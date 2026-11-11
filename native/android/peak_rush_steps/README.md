# PeakRushSteps (Android, Health Connect)

A Godot Android plugin (v2) that reads daily step totals from **Health Connect** for M9
real-step rewards (GAME_DESIGN §5.10). The GDScript side is `scenes/steps/health_connect_step_provider.gd`,
and `addons/peak_rush_steps/` adds the AAR and its Maven dependencies to Android exports.
The `native/` folder has a `.gdignore`, so Godot never imports or exports it.

## API (singleton `PeakRushSteps`)
| Call | Answer |
|---|---|
| `getStatus() -> int` | 0 unsupported, 1 Health Connect needs install/update, 2 ready (= `StepProvider.Status`) |
| `requestAccess()` | signal `access_result(granted: bool)` |
| `readDays(id: int, request_json: String)` with `{"dates": [...], "since_unix": n}` | signal `days_read(id: int, totals_json: String, ok: bool)` |
| `openStore()` | opens Health Connect's Play Store page |

## Build the AAR (after changing the Kotlin code)
From this folder, in Git Bash:
```bash
JAVA_HOME="/c/Program Files/Java/jdk-17" ANDROID_HOME="$LOCALAPPDATA/Android/Sdk" \
JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT \
./gradlew --no-daemon :plugin:copyAarToAddon
```
This writes `addons/peak_rush_steps/bin/peak_rush_steps-release.aar`. Versions follow Godot 4.7.2's
build template (AGP 8.6.1, Kotlin 2.1.21, compileSdk 36). When Godot is upgraded, bump the `godot`
`compileOnly` dependency to match.
If you change the dependency versions in `plugin/build.gradle.kts`, change `DEPENDENCIES` in
`addons/peak_rush_steps/export_plugin.gd` too.

## Requirements
- Android exports must use the **Gradle build** with **min SDK 26** (both presets are set up this way).
- Google Play: fill in the **Health Connect permission declaration** (READ_STEPS) and the data-safety
  form (step data is read on the device, never collected or shared). The privacy policy must say so.
