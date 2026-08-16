plugins {
    id("com.android.dynamic-feature")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.sujinarin.ko_lernen_app.proofreading"
    compileSdk = 36

    defaultConfig {
        // Dynamic feature modules must match the base minSdk. Delivery remains
        // API 26+ through the manifest's install-time condition below.
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(project(":app"))
    implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
}
