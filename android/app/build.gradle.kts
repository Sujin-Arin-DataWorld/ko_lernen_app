import com.android.build.api.artifact.SingleArtifact
import java.util.Properties
import javax.inject.Inject
import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

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

// Play versionCode is app-global, so each upload track owns one lane for a
// commit: internal=3N, alpha=3N+1, beta=3N+2. The next commit starts at
// 3(N+1), keeping all lanes unique and monotonically ordered.
val configuredPlayTrack =
    System.getenv("PLAY_TRACK")?.trim()?.lowercase().orEmpty()
val playTrackVersionOffset: Int = when (configuredPlayTrack) {
    "", "internal" -> 0
    "alpha" -> 1
    "beta" -> 2
    else -> throw GradleException(
        "Unsupported PLAY_TRACK '$configuredPlayTrack'. " +
            "Expected internal, alpha, or beta."
    )
}

val gitCommitCount: Int? = try {
        val process = ProcessBuilder("git", "rev-list", "--count", "HEAD")
            .directory(rootProject.projectDir)
            .redirectErrorStream(true)
            .start()
        val text = process.inputStream.bufferedReader().readText().trim()
        process.waitFor()
        if (process.exitValue() == 0) {
            text.toIntOrNull()?.takeIf { count -> count > 0 }
        } else {
            null
        }
    } catch (_: Exception) {
        null
    }

// Source archives can still configure debug builds without Git metadata. A
// release task must have the real HEAD count and is rejected below.
val autoVersionCode: Int = run {
    val commitCount = gitCommitCount ?: 21
    commitCount * 3 + playTrackVersionOffset
}
gradle.taskGraph.whenReady {
    val releaseTaskScheduled = allTasks.any { task ->
        task.project == project &&
            task.name.contains("release", ignoreCase = true)
    }
    if (releaseTaskScheduled && gitCommitCount == null) {
        throw GradleException(
            "Cannot derive release versionCode from git HEAD. " +
                "Release builds require complete Git version history."
        )
    }
}

android {
    namespace = "com.sujinarin.ko_lernen_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    dynamicFeatures += setOf(":proofreading_feature")
    dynamicFeatures += setOf(":c_artwork")

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

// Select the artifact pipeline at configuration time. Requested task names
// belong to Gradle's configuration-cache key; no task action reads taskGraph.
val cArtworkRequestedTaskLeaves = gradle.startParameter.taskNames.map {
    it.substringAfterLast(':').lowercase()
}
val cArtworkBundleRequested = cArtworkRequestedTaskLeaves.any {
    it == "bundle" || Regex("^(bundle.*release|package.*releasebundle)$").matches(it)
}
val cArtworkApkRequested = cArtworkRequestedTaskLeaves.any {
    it.startsWith("assemble") || it.startsWith("install") ||
        (it.startsWith("package") && !it.endsWith("bundle")) ||
        it in setOf("build", "buildneeded", "builddependents")
}
if (cArtworkBundleRequested && cArtworkApkRequested) {
    throw GradleException(
        "c_artwork cannot combine bundle tasks with APK-producing " +
            "assemble/install/package/build tasks in one invocation. " +
            "Run the AAB and standalone APK builds separately to preserve their artwork assets."
    )
}

// AABs relocate artwork. Standalone APKs (including release), debug and profile
// keep the full base pipeline; an old transformed directory is never selected.
if (cArtworkBundleRequested) {
    androidComponents {
        onVariants(selector().withBuildType("release")) { variant ->
            val variantSuffix = variant.name.replaceFirstChar { it.uppercaseChar() }
            val relocatedAssets = tasks.register<RemoveCArtworkFromBaseAssets>(
                "remove${variantSuffix}CArtworkFromBaseAssets"
            ) {
                // Flutter copies into mergeAssets.outputDir after AGP's merge.
                dependsOn("copyFlutterAssets$variantSuffix")
            }
            variant.artifacts.use(relocatedAssets)
                .wiredWithDirectories(
                    RemoveCArtworkFromBaseAssets::inputDirectory,
                    RemoveCArtworkFromBaseAssets::outputDirectory
                )
                .toTransform(SingleArtifact.ASSETS)
        }
    }
}

@CacheableTask
abstract class RemoveCArtworkFromBaseAssets @Inject constructor(
    private val fileSystemOperations: FileSystemOperations
) : DefaultTask() {
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val inputDirectory: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun removeArtworkDuplicate() {
        val prefix = "flutter_assets/assets/illustrations/ildu_r16"
        check(inputDirectory.dir(prefix).get().asFile.isDirectory) {
            "R16 Flutter assets are missing from merged assets; " +
                "copyFlutterAssets must finish before the relocation transform."
        }
        fileSystemOperations.sync {
            from(inputDirectory)
            into(outputDirectory)
            exclude("$prefix/**")
        }
    }
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
