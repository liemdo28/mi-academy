import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is optional and never committed. If key.properties is absent
// (local dev, CI debug/analyze runs), release builds fall back to the debug key
// so `flutter build apk --debug` keeps working exactly as before. Real release
// signing requires key.properties to be generated at build time from secrets —
// see docs/security/SECRET_INVENTORY.md and the release-build CI job.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.mi_academy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // NOT YET A REAL, OWNED PACKAGE NAME -- this is Flutter's scaffold
        // default. Google Play rejects "com.example.*" applications and
        // package names cannot be changed after first Play Console upload,
        // so this is a business decision (Play Console developer account /
        // domain ownership) that must be made before the first production
        // upload, not something to invent here. Tracked as a Blocker in
        // docs/release-audit.md and docs/android-signing.md -- not a code
        // TODO because there's no code fix, only an org decision.
        applicationId = "com.example.mi_academy"
        // versionCode/versionName both come from pubspec.yaml's `version:`
        // field (currently 0.9.0-beta.1+1) via Flutter's standard Gradle
        // integration -- not hardcoded here, not a separate source of truth.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // `-PrequireReleaseSigning=true` opts into a hard failure instead of the
    // silent debug-signing fallback below -- for CI/release-engineer runs
    // that must produce a real, Play-Console-uploadable artifact and would
    // rather fail loudly than ship a debug-signed AAB by mistake. Ordinary
    // local/dev release builds (`flutter build apk --release` with no
    // key.properties) are unaffected and keep working exactly as before.
    val requireReleaseSigning = project.hasProperty("requireReleaseSigning") &&
        project.property("requireReleaseSigning") == "true"
    if (requireReleaseSigning && !hasReleaseSigning) {
        throw GradleException(
            "requireReleaseSigning=true was set but android/key.properties is " +
                "missing. Generate it from android/key.properties.example (see " +
                "docs/android-signing.md) or supply the signing secrets this CI " +
                "job expects before requesting a production-signed build."
        )
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties present — fall back to the debug key so
                // unsigned CI/local release builds keep working.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
