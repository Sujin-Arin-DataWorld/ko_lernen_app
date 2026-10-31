import javax.inject.Inject
import java.io.File
import java.security.MessageDigest
import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
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
                repositoryDirectory.set(rootProject.layout.projectDirectory.dir(".."))
                artworkManifest.set(layout.projectDirectory.file("artwork_manifest.tsv"))
                authorityFiles.from(CArtworkManifest.authorities(artworkManifest.get().asFile).map {
                    repositoryDirectory.file(it).get().asFile
                })
                val keys = CArtworkManifest.rows(artworkManifest.get().asFile, repositoryDirectory.get().asFile)
                    .map { it.asset }
                sourceFiles.from(fileTree(repositoryDirectory.get().asFile) { include(keys) })
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
    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val artworkManifest: RegularFileProperty

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val sourceFiles: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val authorityFiles: ConfigurableFileCollection

    @get:Internal
    abstract val repositoryDirectory: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun stageArtwork() {
        val rows = CArtworkManifest.rows(artworkManifest.get().asFile, repositoryDirectory.get().asFile)
        rows.forEach { row ->
            val file = repositoryDirectory.file(row.asset).get().asFile
            check(file.isFile && file.length() == row.bytes && CArtworkManifest.sha(file) == row.sha256) {
                "Artwork source missing/changed: ${row.asset}"
            }
        }
        // One union sync removes stale output while preserving every relative key.
        fileSystemOperations.sync {
            from(repositoryDirectory) { include(rows.map { it.asset }) }
            into(outputDirectory.dir("flutter_assets"))
        }
    }
}

object CArtworkManifest {
    data class Row(val asset: String, val sha256: String, val bytes: Long)

    // JSON authorities follow Git's eol=lf contract; artwork hashes stay raw.
    fun authoritySha(file: File): String = MessageDigest.getInstance("SHA-256")
        .digest(file.readText(Charsets.UTF_8).replace("\r\n", "\n").replace("\r", "\n")
            .toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it.toInt() and 255) }

    fun sha(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(65536)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it.toInt() and 255) }
    }

    fun safePath(path: String): Boolean =
        path.isNotEmpty() && path.none { it in "\\:*?[]<>\"|" || it.code < 32 || it.code == 127 } &&
            path.split('/').none { it in setOf("", ".", "..") }

    fun authorities(file: File): List<String> = file.readLines()
        .filter { it.startsWith("# authority\t") }.map { line ->
            val fields = line.split('\t')
            check(fields.size == 6 && safePath(fields[2])) { "Invalid artwork authority" }
            fields[2]
        }

    fun rows(file: File, repository: File): List<Row> {
        val lines = file.readLines()
        check(lines.firstOrNull() == "# c-artwork-manifest-v1") { "Unsupported artwork manifest" }
        val authorities = lines.drop(1).takeWhile { it.startsWith("# authority\t") }
            .map { it.split('\t') }
        check(authorities.isNotEmpty() && authorities.all { it.size == 6 }) { "Missing artwork authorities" }
        check(authorities.map { it[1] }.distinct().size == authorities.size) { "Duplicate artwork group" }
        authorities.forEach { fields ->
            check(safePath(fields[2]) && Regex("[0-9a-f]{64}").matches(fields[3]) &&
                fields[4].startsWith("assets/") && fields[4].endsWith('/') &&
                safePath(fields[4].dropLast(1)) && fields[5].toInt() > 0 &&
                authoritySha(File(repository, fields[2])) == fields[3]) { "Artwork authority changed" }
        }
        check(lines.getOrNull(authorities.size + 1) == "asset\tsha256\tbytes\tgroup") { "Invalid artwork columns" }
        val counts = mutableMapOf<String, Int>()
        val rows = lines.drop(authorities.size + 2).map { line ->
            val fields = line.split('\t')
            check(fields.size == 4) { "Invalid artwork row" }
            val family = authorities.singleOrNull { it[1] == fields[3] }
            check(family != null && safePath(fields[0]) && fields[0].startsWith(family[4]) &&
                Regex("[0-9a-f]{64}").matches(fields[1]) && fields[2].toLong() > 0) { "Unsafe artwork identity" }
            counts[fields[3]] = counts.getOrDefault(fields[3], 0) + 1
            Row(fields[0], fields[1], fields[2].toLong())
        }
        check(rows.map { it.asset } == rows.map { it.asset }.distinct().sorted() &&
            authorities.all { counts[it[1]] == it[5].toInt() }) { "Artwork exact set/count differs" }
        return rows
    }
}

dependencies {
    implementation(project(":app"))
}
