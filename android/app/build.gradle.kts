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
// Sürüm kodu git commit sayısından türetilir: her commit ile kendiliğinden
// artar, elle güncellemeyi unutmak mümkün olmaz ve Play'in "sürüm kodu daha
// önce kullanıldı" hatası tekrarlanmaz. Git yoksa pubspec'teki değere düşer.
val gitVersionCode: Int = try {
    val process = ProcessBuilder("git", "rev-list", "--count", "HEAD")
        .directory(rootProject.projectDir.parentFile)
        .redirectErrorStream(true)
        .start()
    val output = process.inputStream.bufferedReader().readText().trim()
    process.waitFor()
    output.toIntOrNull() ?: 0
} catch (e: Exception) {
    0
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.e2esolutions.chess"
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
        applicationId = "com.e2esolutions.chess"
        // Stockfish eklentisi 21'i destekler; NNUE değerlendirmesi için bellek
        // ve 64 bit desteği güvenilir olsun diye taban 24'e çekilmiştir.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // İkisinin büyüğü alınır; böylece pubspec'te elle yükseltilen bir
        // değer git sayısının gerisinde kalsa bile sürüm kodu asla düşmez.
        versionCode = maxOf(gitVersionCode, flutter.versionCode)
        versionName = flutter.versionName

        // Motor kitaplığı NNUE ağlarını gömülü taşıdığı için ABI başına
        // ~114 MB'dır. Yalnızca arm64-v8a paketlenir: 32 bit cihazlar bu
        // boyuttaki bir motoru zaten rahat çalıştıramaz, x86_64 ise emülatör
        // dışında kullanılmaz (Apple Silicon emülatörleri de arm64'tür).
        ndk {
            abiFilters += listOf("arm64-v8a")
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
            excludes += setOf(
                "**/x86_64/*.so",
                "**/x86/*.so",
                "**/armeabi-v7a/*.so",
            )
        }
    }
}

flutter {
    source = "../.."
}
