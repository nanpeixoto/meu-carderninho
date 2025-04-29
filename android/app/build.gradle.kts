plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // nome correto do plugin Kotlin moderno
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin DEVE vir depois do Android/Kotlin
    id("com.google.gms.google-services") // Necessário para Firebase e outros serviços Google
}

android {
    namespace = "com.example.meu_caderninho"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.meu_caderninho"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // útil para usar APIs modernas em versões antigas
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // substitua por sua keystore real depois
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // necessário se usar desugaring
}
