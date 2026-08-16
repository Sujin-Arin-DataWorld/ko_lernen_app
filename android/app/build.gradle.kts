import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

// Release credentials remain local and gitignored. A release task must never
// silently fall back to the Android debug key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val requiredSigningProperties =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseSigningError = run {
    if (!keystorePropertiesFile.isFile) {
        return@run "android/key.properties is missing."
    }

    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
    val missingProperties = requiredSigningProperties.filter { property ->
        keystoreProperties.getProperty(property).isNullOrBlank()
    }
    if (missingProperties.isNotEmpty()) {
        return@run "android/key.properties is missing required values: " +
            missingProperties.joinToString(", ") + "."
    }

    val configuredStoreFile = file(keystoreProperties.getProperty("storeFile"))
    if (!configuredStoreFile.isFile) {
        return@run "The configured release keystore does not exist: " +
            configuredStoreFile.absolutePath
    }

    null
}
gradle.taskGraph.whenReady {
    val releaseTaskScheduled = allTasks.any { task ->
        task.project == project &&
            task.name.contains("release", ignoreCase = true)
    }
    if (releaseTaskScheduled && releaseSigningError != null) {
        throw GradleException(
            "Release signing configuration is invalid. $releaseSigningError " +
                "Provide a complete android/key.properties and an existing " +
                "non-debug upload keystore."
        )
    }
}
val hasReleaseKey = releaseSigningError == null

// versionCode 자동 증가 — git 커밋 수 기반. 커밋마다 +1 이라 Play 재업로드 시
// versionCode 충돌(이미 올라간 20 등)을 원천 차단한다. versionName(2.0.5)은 그대로.
// git 사용 불가 시(소스 zip 등) 안전 폴백 21(>이미 올라간 20).
val autoVersionCode: Int = run {
    try {
        val process = ProcessBuilder("git", "rev-list", "--count", "HEAD")
            .directory(rootProject.projectDir)
            .redirectErrorStream(true)
            .start()
        val text = process.inputStream.bufferedReader().readText().trim()
        process.waitFor()
        text.toInt()
    } catch (e: Exception) {
        21
    }
}

android {
    namespace = "com.sujinarin.ko_lernen_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    dynamicFeatures += setOf(":proofreading_feature")

    compileOptions {
        // M3: flutter_local_notifications braucht core library desugaring
        // (java.time-Backport für ältere Android-Versionen).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sujinarin.ko_lernen_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = autoVersionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"] as String
                keyPassword   = keystoreProperties["keyPassword"] as String
                storeFile     = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled  = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Hinweis: debugSymbolLevel = "NONE" wurde testweise hinzugefügt,
            // führte aber zu "failed to strip debug symbols" beim Build
            // (Konflikt mit Flutter's eigenem Strip-Schritt). Standard belassen.
            // AAB enthält daher native debug symbols (~5-15 MB Mehraufwand) —
            // Play Console kann sie aus der AAB selbst lesen.
        }
    }

    // ABI-Splits entfernt — Flutter Gradle Plugin setzt bereits ndk abiFilters
    // automatisch, was zu Konflikt führt. Für Play Store: .aab nutzen
    // (Play generiert ABI-Splits automatisch). Für direkte APK-Distribution:
    // 'flutter build apk --release' liefert universal APK (~30-40MB).
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
    // M3: Laufzeit-Backport für core library desugaring (flutter_local_notifications).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // 책 한 컷 한국어 OCR (PFLICHT): google_mlkit_text_recognition 플러그인은
    // Latin 인식기만 implementation 으로 번들하고, Korean/Chinese/Japanese/
    // Devanagari 는 compileOnly 로만 선언한다 → Korean 클래스가 APK(런타임)에
    // 빠져 OCR 호출 시 NoClassDefFoundError(KoreanTextRecognizerOptions) 크래시.
    // 앱에서 implementation 으로 명시 포함해야 한국어 인식이 동작한다.
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
