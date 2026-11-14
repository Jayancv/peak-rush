# Building a Google Play release

Two export presets live in `export_presets.cfg`:

| Preset | Output | Use |
|---|---|---|
| `Android` | debug APK via the Gradle build | quick installs on the phone (`tools/deploy.sh`) |
| `Android Release` | signed **AAB** via the Gradle build | uploads to Google Play |

The app version comes from `application/config/version` in `project.godot` (both presets leave
`version/name` empty). **Raise `version/code` in both presets for every upload**: Play rejects
a version code it has already seen. Target SDK is Godot 4.7's default, **API 36** (what Play
requires for new apps and updates since 31 Aug 2026); min SDK 24.

## 0. This PC's Gradle settings (once)
This PC's network intercepts TLS (same reason git needs schannel), so Gradle's Java must trust
the Windows certificate store, or downloads fail with "PKIX path building failed". Builds also
run next to the Godot editor, so Gradle's memory is capped. Both live in
`%USERPROFILE%\.gradle\gradle.properties` (applies to every Gradle build on the PC; it replaces
the old `JAVA_TOOL_OPTIONS` variable):
```properties
systemProp.javax.net.ssl.trustStoreType=Windows-ROOT
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.daemon=false
```

## Debug builds on the phone
`tools/deploy.sh` exports the `Android` preset only when game files are newer than the APK,
waits for the phone and installs (`--force` always exports, `--install-only` skips it). Godot
comes from `$GODOT` or `godot` on PATH.

**Wireless debugging** (no cable): phone and PC on the same Wi-Fi.
1. Phone: Settings > System > Developer options > **Wireless debugging** on.
2. Tap **Pair device with pairing code**; it shows an address `IP:PORT` and a 6-digit code.
3. PC: `tools/deploy.sh pair IP:PORT CODE` (once per PC; the pairing is remembered).
4. From then on `tools/deploy.sh` finds the phone by itself (mDNS) while Wireless debugging
   is on. If it doesn't, use the address on the Wireless debugging screen (not the pairing
   one): `tools/deploy.sh connect IP:PORT`. The port changes each time it is switched on.

On this PC a phone that was once allowed over USB connects without pairing. The home network gives
every device its own public address (the TP-Link is only an access point), so Wi-Fi installs go
through the ISP: ~2 minutes for the 89 MB APK, against seconds over USB. `deploy.sh` uses the cable
when both are connected. Switch Wireless debugging off when done: its port is on a public address.

## 1. Release keystore (once, never again)
Play App Signing keeps Google's app-signing key; this keystore is your **upload key**. Losing it
is recoverable through Play support but slow, so still treat it as precious.

```bash
"C:/Program Files/Java/jdk-17/bin/keytool" -genkeypair -v -keystore peak-rush-upload.keystore \
  -alias peakrush -keyalg RSA -keysize 2048 -validity 10000
```
- Keep the file **outside the repo** (e.g. `%USERPROFILE%\keys\`). `.gitignore` blocks
  `*.keystore` / `*.jks` / `export_credentials.cfg` anyway.
- Back up the file **and** its password in two safe places (e.g. a password manager + an
  encrypted USB stick). Never commit or paste the password anywhere.

## 2. Build the AAB
Credentials come from environment variables, so nothing secret is written into the project:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="C:/Users/<you>/keys/peak-rush-upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=peakrush
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='...'
godot --headless --path . --install-android-build-template --export-release "Android Release" export/android/peak-rush-release.aab
```
- `--install-android-build-template` creates `android/build/` (ignored by git; the stock
  template, nothing customised) the first time. The first Gradle run downloads its
  dependencies and takes several minutes.
- Check the result: the merged manifest at
  `android/build/build/intermediates/merged_manifest/standardRelease/.../AndroidManifest.xml`
  should show the right versionCode/versionName and `targetSdkVersion="36"`.

The pipeline was checked on 2026-11-11 with the debug keystore standing in: a 29 MB AAB,
versionName 1.0.0, versionCode 1, target 36. That test AAB was deleted; never upload an AAB
signed with the debug key.

## 3. Store images
```bash
godot --path . --resolution 1920x1080 tools/store_shots/store_shots.tscn
```
Needs a real window (not headless). Writes 8 screenshots, the 1024x500 feature graphic and the
512 px icon to `export/store/`. Uses made-up progress in memory only; the real save is never
written. Listing text: `docs/STORE_LISTING.md`.

## 4. Still to do before the first upload
- Real AdMob provider + plugin (adds the `AD_ID` permission through its manifest; ask before
  downloading the plugin). Until then a release build shows no ads.
- Host `docs/PRIVACY.md` and set `AboutCard.PRIVACY_URL`.
- Upload to the **internal testing** track, install from Play on the phone, read the pre-launch report.
