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
    id("com.android.dynamic-feature")
}

android {
    namespace = "com.sujinarin.ko_lernen_app.c_artwork"
    compileSdk = 36

    defaultConfig {
        // Match the existing base minimum. Delivery has no SDK condition.
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

// Keep selection identical to the base: only explicitly requested AAB tasks
// register generated split assets. Standalone APKs keep artwork in the base.
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

if (cArtworkBundleRequested) {
    androidComponents {
        onVariants(selector().withBuildType("release")) { variant ->
            val variantSuffix = variant.name.replaceFirstChar { it.uppercaseChar() }
            val artwork = tasks.register<StageCArtworkAssets>(
                "stage${variantSuffix}CArtworkAssets"
            ) {
                sourceDirectory.set(
                    rootProject.layout.projectDirectory.dir(
                        "../assets/illustrations/ildu_r16"
                    )
                )
            }
            checkNotNull(variant.sources.assets).addGeneratedSourceDirectory(
                artwork,
                StageCArtworkAssets::outputDirectory
            )
        }
    }
}

@CacheableTask
abstract class StageCArtworkAssets @Inject constructor(
    private val fileSystemOperations: FileSystemOperations
) : DefaultTask() {
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val sourceDirectory: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun stageArtwork() {
        fileSystemOperations.sync {
            from(sourceDirectory)
            into(outputDirectory.dir("flutter_assets/assets/illustrations/ildu_r16"))
        }
    }
}

dependencies {
    implementation(project(":app"))
}
