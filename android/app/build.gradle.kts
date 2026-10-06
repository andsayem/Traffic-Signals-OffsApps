import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.andsayem.traffic_signal_symbols"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
        signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = "AS@sayem"
            keyAlias = "upload"
            keyPassword = "AS@sayem"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.andsayem.traffic_signal_symbols"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    // play-services-ads (pulled in by google_mobile_ads) transitively depends on
    // an old androidx.work:work-runtime (2.7.0), whose bundled WorkDatabase_Impl
    // crashes at startup on modern Android with:
    // "Failed to create an instance of androidx.work.impl.WorkDatabase".
    // Force a current WorkManager so Gradle picks this version instead.
    implementation("androidx.work:work-runtime:2.11.2")
}

flutter {
    source = "../.."
}
