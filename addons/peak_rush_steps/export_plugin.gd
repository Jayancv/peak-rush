@tool
extends EditorPlugin
## Adds the PeakRushSteps AAR and its Maven dependencies to Android (Gradle) exports.
## The AAR is built from native/android/peak_rush_steps (see its README).

var _export: StepsExportPlugin


func _enter_tree() -> void:
	_export = StepsExportPlugin.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class StepsExportPlugin extends EditorExportPlugin:
	## Relative to res://addons/.
	const AAR: String = "peak_rush_steps/bin/peak_rush_steps-release.aar"
	## Keep in step with native/android/peak_rush_steps/plugin/build.gradle.kts.
	const DEPENDENCIES: PackedStringArray = [
		"androidx.health.connect:connect-client:1.1.0-beta01",
		"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0",
	]

	func _get_name() -> String:
		return "PeakRushSteps"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not FileAccess.file_exists("res://addons/" + AAR):
			push_warning("PeakRushSteps: %s is missing; build it first (native/android/peak_rush_steps/README.md)" % AAR)
			return PackedStringArray()
		return PackedStringArray([AAR])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return DEPENDENCIES
