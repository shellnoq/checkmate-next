import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle eklentisi Android ve Kotlin eklentilerinden sonra gelmelidir.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yayın imzası android/key.properties dosyasından okunur. Bu dosya ve
// keystore sürüm kontrolüne girmez; kurulumu docs/RELEASE.md anlatır.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.e2esolutions.satranc"
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
        applicationId = "com.e2esolutions.satranc"
        // Stockfish eklentisi 21'i destekler; NNUE değerlendirmesi için bellek
        // ve 64 bit desteği güvenilir olsun diye taban 24'e çekilmiştir.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Motor kitaplığı NNUE ağlarını gömülü taşıdığı için ABI başına
        // ~114 MB'dır. Yalnızca gerçek cihaz mimarileri paketlenir; Apple
        // Silicon emülatörleri de arm64-v8a kullandığı için x86_64 gereksizdir.
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Anahtar yoksa `flutter run --release` çalışmaya devam etsin.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Stockfish kitaplığı NNUE ağlarını gömülü taşır (~114 MB) ve
            // sembol tablosu paketi üç katına çıkarır; yerel semboller
            // gerekirse Play Console'a ayrıca yüklenebilir.
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }

    bundle {
        // Dil seçimi uygulama içinden yapılıyor; dil bölümlemesi kapatılır,
        // aksi hâlde Play yalnızca cihaz dilini indirir.
        language {
            enableSplit = false
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
            )
        }
        jniLibs {
            // Eklenti modülü x86_64'ü de derliyor; ndk.abiFilters önceden
            // derlenmiş jniLibs'i süzmediği için paketleme aşamasında elenir.
            excludes += setOf("**/x86_64/*.so", "**/x86/*.so")
        }
    }
}

flutter {
    source = "../.."
}
