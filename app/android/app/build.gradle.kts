import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (ADR-0010). The keystore never lives in the repository: `key.properties` is
// gitignored, and CI writes one from secrets before it builds. When the file is absent the release
// build falls back to the debug keys, so `flutter run --release` and a CI build without secrets
// both still work — a fallback that has to stay, because a contributor's clone has no keystore and
// a build that failed for them would be worse than one that is merely unsigned.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "io.github.kikuyomiapp.kikuyomi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.kikuyomiapp.kikuyomi"
        // ADR-0012's floor, not Flutter's. API 26 is where notification channels and the modern
        // background-execution limits begin, so the foreground service the download queue needs has
        // one model rather than two. Flutter's own default is lower, and taking it would publish an
        // APK that installs on devices the project has decided not to support — which is only
        // cheap to correct before the first release, because raising a floor afterwards strands
        // whoever installed under it.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
