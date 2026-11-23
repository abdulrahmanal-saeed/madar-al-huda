plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Distribution channel and signing come from environment variables so no
// key material or passwords ever live in the repository (P00-11).
//   MADAR_CHANNEL=dev            → dev build: app id suffix ".dev"
//   MADAR_CHANNEL=preview        → side-by-side test build: app id suffix ".preview"
//   MADAR_VERSION_SUFFIX         → e.g. "-dev.42" (shown in Settings/Obtainium)
//   MADAR_SIGNING_STORE_FILE     → path to the keystore (decoded in CI)
//   MADAR_SIGNING_STORE_PASSWORD, MADAR_SIGNING_KEY_ALIAS,
//   MADAR_SIGNING_KEY_PASSWORD
// Without them, release builds fall back to debug keys for local runs only.
val madarChannel: String = System.getenv("MADAR_CHANNEL") ?: "local"
val isDevChannel = madarChannel == "dev"
val isPreviewChannel = madarChannel == "preview"
val madarSigningStore: String? = System.getenv("MADAR_SIGNING_STORE_FILE")

android {
    namespace = "com.abdulrahmanalsaeed.madaralhuda"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for scheduled reminders.
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        if (madarSigningStore != null) {
            create("madar") {
                storeFile = file(madarSigningStore)
                storePassword = System.getenv("MADAR_SIGNING_STORE_PASSWORD")
                keyAlias = System.getenv("MADAR_SIGNING_KEY_ALIAS")
                keyPassword = System.getenv("MADAR_SIGNING_KEY_PASSWORD")
            }
        }
    }

    defaultConfig {
        // Candidate ID from docs/BRAND.md (decision O-08): confirm before the
        // first store release; it can never change once published.
        applicationId = "com.abdulrahmanalsaeed.madaralhuda"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        if (isDevChannel) {
            // Installs beside (never over) a future store build.
            applicationIdSuffix = ".dev"
            versionNameSuffix = System.getenv("MADAR_VERSION_SUFFIX") ?: "-dev"
        } else if (isPreviewChannel) {
            applicationIdSuffix = ".preview"
            versionNameSuffix = "-preview"
        }
    }

    // Ship only the languages the app supports (also trims library strings).
    androidResources {
        localeFilters += listOf("ar", "en")
    }

    buildTypes {
        release {
            signingConfig = when {
                madarSigningStore != null -> signingConfigs.getByName("madar")
                // A published dev build must always carry the fixed dev key,
                // or installed copies could never be updated.
                isDevChannel -> throw GradleException(
                    "MADAR_CHANNEL=dev requires MADAR_SIGNING_* variables.",
                )
                // Local `flutter run --release` only. Store signing: P06-01.
                else -> signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
