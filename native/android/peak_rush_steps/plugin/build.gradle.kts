import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

// Keep these in step with addons/peak_rush_steps/export_plugin.gd (DEPENDENCIES):
// the AAR doesn't bundle its dependencies, the Godot export adds them.
// 1.1.0 final needs AGP 8.9.1; Godot 4.7.2's template has 8.6.1. beta01 is the newest that fits (needs 8.6.0).
val healthConnectVersion = "1.1.0-beta01"
val coroutinesVersion = "1.9.0"

android {
    namespace = "org.jcv.peakrush.steps"
    compileSdk = 36
    defaultConfig {
        // Health Connect's client library needs API 26.
        minSdk = 26
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    compileOnly("org.godotengine:godot:4.7.2.stable")
    implementation("androidx.health.connect:connect-client:$healthConnectVersion")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:$coroutinesVersion")
}

// Copies the release AAR to where the Godot export plugin looks for it.
tasks.register<Copy>("copyAarToAddon") {
    dependsOn("assembleRelease")
    from(layout.buildDirectory.file("outputs/aar/plugin-release.aar"))
    into(rootProject.file("../../../addons/peak_rush_steps/bin"))
    rename { "peak_rush_steps-release.aar" }
}
