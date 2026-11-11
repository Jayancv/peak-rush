# Building a Google Play release

Two export presets live in `export_presets.cfg`:

| Preset | Output | Use |
|---|---|---|
| `Android` | debug APK, no Gradle | quick installs on the phone (`adb install -r`) |
| `Android Release` | signed **AAB** via the Gradle build | uploads to Google Play |

The app version comes from `application/config/version` in `project.godot` (both presets leave
`version/name` empty). **Raise `version/code` in both presets for every upload**: Play rejects
a version code it has already seen. Target SDK is Godot 4.7's default, **API 36** (what Play
requires for new apps and updates since 31 Aug 2026); min SDK 24.

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
# This PC's network intercepts TLS (same reason git needs schannel): let Gradle's Java trust
# the Windows certificate store, or its downloads fail with "PKIX path building failed".
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStoreType=Windows-ROOT"

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
