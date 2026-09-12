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

// versionCode = (git 커밋 수 × 2) + 트랙 오프셋. versionName(pubspec)은 그대로.
//
// **왜 트랙마다 다른 칸을 쓰나.** Play 의 versionCode 는 트랙이 아니라 앱 전역에서
// 유일해야 한다. 예전엔 커밋 수를 그대로 썼는데, 같은 SHA 를 내부 테스트(ci.yml)와
// 비공개 테스트(play_closed.yml)가 각각 빌드하면 두 번째 업로드가 언제나
// "Version code N has already been used." 로 거부됐다(2026-09-06 run 34036865928).
// 그래서 릴리스마다 자동 내부배포를 껐다 켜는 수작업이 생겼고, 되돌리는 걸 잊자
// 내부 테스트 트랙이 조용히 멈춰 2026-09-06 의 Hören 카드 그리드 변경이 그 트랙의
// 빌드에 없었다. 트랙마다 칸을 나누면 두 경로가 같은 번호를 두고 다툴 일이 없다.
//
//   PLAY_TRACK 미설정·internal → 짝수 2N   (main CI 자동 내부 업로드, 로컬 빌드)
//   PLAY_TRACK=alpha|closed    → 홀수 2N+1 (같은 소스의 내부 빌드보다 딱 1 높다)
//
// 커밋 수는 늘기만 하므로 번호도 단조 증가한다. 이 식은 워크플로의 아티팩트 이름·
// 심볼 증거 게이트가 쓰는 bash 식과 같아야 하며, 어긋나면
// `.github/scripts/test_play_version_code_contract.py` 가 CI 에서 잡는다.
// git 사용 불가 시(소스 zip 등) 안전 폴백 커밋 수 21.
val playTrackVersionOffset: Int =
    when (System.getenv("PLAY_TRACK")?.trim()?.lowercase()) {
        "alpha", "closed" -> 1
        else -> 0
    }

val autoVersionCode: Int = run {
    val commitCount = try {
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
    commitCount * 2 + playTrackVersionOffset
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
        // API 24/25 users must keep receiving the base app. Proofreading is
        // isolated behind the API 26+ dynamic-feature delivery condition.
        minSdk = 24
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
