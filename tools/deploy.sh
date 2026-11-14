#!/usr/bin/env bash
# Build the debug APK (only if something changed) and install it on the phone.
#
#   tools/deploy.sh                    export if stale, then install
#   tools/deploy.sh --force            always export
#   tools/deploy.sh --install-only     install the APK that is already built
#   tools/deploy.sh pair HOST:PORT CODE    one-time wireless pairing (Wireless debugging >
#                                          "Pair device with pairing code" on the phone)
#   tools/deploy.sh connect HOST:PORT      connect to a paired phone by hand
#
# Godot: $GODOT, else `godot` on PATH. adb: $ADB, else the Android SDK's platform-tools.
# Wireless phones are found over mDNS once paired; the cable still works too.
# Certificates and Gradle memory are set in ~/.gradle/gradle.properties (docs/RELEASE.md).
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="$ROOT/export/android/peak-rush-debug.apk"
PRESET="Android"
PACKAGE="org.jcv.peakrush"
LOG="${TMPDIR:-${TEMP:-/tmp}}/peak-rush-export.log"
EXPORT_TIMEOUT=900   # seconds; the first build after a dependency change downloads a lot

ADB="${ADB:-}"
if [ -z "$ADB" ]; then
	if [ -n "${LOCALAPPDATA:-}" ] && [ -x "$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" ]; then
		ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
	elif [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then
		ADB="$ANDROID_HOME/platform-tools/adb"
	else
		ADB="adb"
	fi
fi

say() { printf '\033[1m[deploy]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[deploy]\033[0m %s\n' "$*" >&2; exit 1; }

phone_ready() {
	"$ADB" devices | awk 'NR > 1 && $2 == "device" { found = 1 } END { exit !found }'
}

# A paired phone on Wi-Fi advertises itself over mDNS; connect to whatever is there.
connect_wireless() {
	"$ADB" mdns services 2>/dev/null | awk '/_adb-tls-connect/ { print $NF }' | while read -r addr; do
		"$ADB" connect "$addr" >/dev/null 2>&1 && say "Connected over Wi-Fi: $addr"
	done
}

find_phone() {
	"$ADB" start-server >/dev/null 2>&1
	for _ in 1 2 3 4 5 6 7 8 9 10; do
		phone_ready && return 0
		connect_wireless
		sleep 2
	done
	return 1
}

# Anything the APK is built from that is newer than the APK.
stale() {
	[ -f "$APK" ] || return 0
	[ -n "$(find "$ROOT" \
		\( -path "$ROOT/.git" -o -path "$ROOT/.godot" -o -path "$ROOT/export" -o -path "$ROOT/android" \
		   -o -path "$ROOT/native" -o -path "$ROOT/tools" -o -path "$ROOT/docs" \) -prune -o \
		-type f ! -name "*.md" -newer "$APK" -print -quit)" ]
}

export_apk() {
	local godot="${GODOT:-$(command -v godot || true)}"
	[ -n "$godot" ] || fail "Godot not found: set GODOT=/path/to/Godot_v4.x_console.exe"
	mkdir -p "$(dirname "$APK")"
	local before=0
	[ -f "$APK" ] && before=$(stat -c %Y "$APK")
	say "Exporting $PRESET build (log: $LOG)..."
	"$godot" --headless --path "$ROOT" --export-debug "$PRESET" "$APK" >"$LOG" 2>&1 &
	local pid=$! waited=0
	# The headless editor sometimes stays alive after the export is done: stop waiting
	# (and stop it) once the log says the export finished.
	while kill -0 "$pid" 2>/dev/null; do
		if grep -q "DONE.*export" "$LOG" 2>/dev/null; then
			sleep 3
			kill "$pid" 2>/dev/null
			break
		fi
		[ "$waited" -ge "$EXPORT_TIMEOUT" ] && { kill "$pid" 2>/dev/null; fail "Export took over ${EXPORT_TIMEOUT}s; see $LOG"; }
		sleep 2
		waited=$((waited + 2))
	done
	wait "$pid" 2>/dev/null
	if grep -qE "Project export for preset .* failed|BUILD FAILED" "$LOG"; then
		grep -E "What went wrong|Error:|Could not resolve|> " "$LOG" | head -15 >&2
		fail "Export failed; full log: $LOG"
	fi
	[ -f "$APK" ] && [ "$(stat -c %Y "$APK")" -gt "$before" ] || fail "No new APK was written; see $LOG"
	say "Built $(du -h "$APK" | cut -f1) APK."
}

install_apk() {
	[ -f "$APK" ] || fail "No APK at $APK; run without --install-only first."
	if ! find_phone; then
		fail "Phone not found. Cable: replug, unlock, allow USB debugging. Wi-Fi: same network as this PC, Wireless debugging on (pair once with: tools/deploy.sh pair HOST:PORT CODE)."
	fi
	# Prefer the cable when both are there: on this network Wi-Fi installs go via the ISP (~2 min vs seconds).
	local serial
	serial=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { if (index($1, ":")) wifi = wifi ? wifi : $1; else if (!usb) usb = $1 }
		END { print usb ? usb : wifi }')
	# Over Wi-Fi the streamed install drops out on this slow link; copying first is slow but works.
	local mode=""
	case "$serial" in *:*) mode="--no-streaming"; say "Wi-Fi install: this can take several minutes (a cable takes seconds)." ;; esac
	say "Installing on $serial..."
	"$ADB" -s "$serial" install -r $mode "$APK" || fail "adb install failed."
	local updated
	updated=$("$ADB" -s "$serial" shell dumpsys package "$PACKAGE" | grep -m1 lastUpdateTime | sed 's/^ *//')
	say "Installed. $updated"
}

case "${1:-}" in
	pair)
		[ $# -eq 3 ] || fail "Usage: tools/deploy.sh pair HOST:PORT CODE"
		"$ADB" pair "$2" "$3" || fail "Pairing failed: check the code and port shown on the phone."
		say "Paired. The phone will now be found automatically while Wireless debugging is on."
		exit 0 ;;
	connect)
		[ $# -eq 2 ] || fail "Usage: tools/deploy.sh connect HOST:PORT"
		"$ADB" connect "$2"
		exit 0 ;;
	--install-only)
		install_apk ;;
	--force)
		export_apk && install_apk ;;
	"")
		if stale; then export_apk; else say "APK is up to date; skipping export."; fi
		install_apk ;;
	*)
		sed -n '2,12p' "$0"
		exit 1 ;;
esac
