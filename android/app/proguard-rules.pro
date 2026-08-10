# ════════════════════════════════════════════════════════════════════════
#  R8 / ProGuard keep rules — RELEASE builds only (isMinifyEnabled=true,
#  isShrinkResources=true). Debug builds are unaffected.
#
#  Philosophy: over-keep rather than under-keep. A missing keep rule can turn
#  into a runtime NoClassDefFoundError / ClassNotFoundException that only
#  surfaces on a signed release APK/AAB on device — never in debug. Every
#  plugin declared in pubspec.yaml gets an explicit keep + dontwarn below.
#  -keep on an absent class is a harmless no-op; -dontwarn on an absent class
#  is fine. So the cost of over-keeping is a few unshrunk classes; the cost of
#  under-keeping is a store-shipped crash. We choose the former.
# ════════════════════════════════════════════════════════════════════════

# ── Flutter engine + embedding ─────────────────────────────────────────────
-keep class io.flutter.embedding.**    { *; }
-keep class io.flutter.plugin.**       { *; }
-keep class io.flutter.plugins.**      { *; }   # plural: the generated plugin registrant + all first-party plugins live here
-keep class io.flutter.util.**         { *; }
-keep class io.flutter.view.**         { *; }
-keep class io.flutter.**              { *; }
-dontwarn io.flutter.**
# GeneratedPluginRegistrant is invoked reflectively by the engine bootstrap.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
# App entry point (also kept via AndroidManifest, but pin it explicitly).
-keep class com.sujinarin.ko_lernen_app.** { *; }

# ── Play Core / Deferred Components / Play Integrity ───────────────────────
# Flutter references Play Core classes unconditionally even when deferred
# components are unused; Firebase App Check uses Play Integrity.
-keep class com.google.android.play.core.**       { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.integrity.**  { *; }
-dontwarn com.google.android.play.integrity.**

# ── Firebase (core, auth, firestore, messaging, crashlytics, storage,
#    remote config, app check, analytics, functions) ────────────────────────
-keep class com.google.firebase.**            { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.**          { *; }
-dontwarn com.google.android.gms.**
# Crashlytics needs class/line attributes for readable stack traces (see the
# -keepattributes block near the bottom). Keep its internal model too.
-keep class com.google.firebase.crashlytics.** { *; }
# Firestore/RTDB may reflect over @IgnoreExtraProperties / @PropertyName /
# @DocumentId annotated model classes (harmless for a Dart-only data layer,
# kept for safety in case any native model is added later).
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
-keep class * implements com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# ── Google Sign-In (google_sign_in) ────────────────────────────────────────
-keep class com.google.android.gms.auth.**      { *; }
-keep class com.google.android.gms.common.**     { *; }
-dontwarn com.google.android.gms.auth.**

# ── Sign in with Apple (sign_in_with_apple) ────────────────────────────────
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
-dontwarn com.aboutyou.dart_packages.sign_in_with_apple.**

# ── Google ML Kit Text Recognition incl. Korean
#    (google_mlkit_text_recognition + text-recognition-korean) ──────────────
# The plugin references ALL script recognizers (Chinese/Devanagari/Japanese/
# Korean); we bundle only Latin + Korean, so R8 aborts the release build with
# "Missing class" for the others. Keep everything under com.google.mlkit and
# suppress the optional recognizers. The Korean recognizer stays via -keep.
-keep class com.google.mlkit.**                 { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ── RevenueCat (purchases_flutter) + Google Play Billing ───────────────────
-keep class com.revenuecat.purchases.**         { *; }
-dontwarn com.revenuecat.purchases.**
-keep class com.android.billingclient.**         { *; }
-dontwarn com.android.billingclient.**

# ── image_picker / image_cropper (uCrop) ───────────────────────────────────
-keep class io.flutter.plugins.imagepicker.**    { *; }
-keep class com.yalantis.ucrop.**                { *; }
-dontwarn com.yalantis.ucrop.**
-keep class * extends com.yalantis.ucrop.**      { *; }

# ── flutter_local_notifications ────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
# The plugin serialises notification models via Gson (see Gson block below).
-keep class com.dexterous.** { *; }

# ── permission_handler ─────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.**    { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── audioplayers ───────────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.**             { *; }
-dontwarn xyz.luan.audioplayers.**

# ── flutter_tts ────────────────────────────────────────────────────────────
-keep class com.tundralabs.fluttertts.**         { *; }
-dontwarn com.tundralabs.fluttertts.**

# ── shared_preferences ─────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── flutter_secure_storage ─────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── video_player (ExoPlayer / androidx.media3) ─────────────────────────────
-keep class io.flutter.plugins.videoplayer.**    { *; }
-keep class com.google.android.exoplayer2.**     { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.**                    { *; }
-dontwarn androidx.media3.**

# ── rive (rive) ────────────────────────────────────────────────────────────
-keep class app.rive.runtime.**                  { *; }
-dontwarn app.rive.runtime.**

# ── Google Mobile Ads (plugin currently disabled in pubspec; keep rules are
#    inert no-ops while classes are absent, ready if re-enabled) ────────────
-keep class com.google.android.gms.ads.**        { *; }
-dontwarn com.google.android.gms.ads.**

# ── record_use ─────────────────────────────────────────────────────────────
# Dart-side build-time tooling (@RecordUse tree-shaking metadata); it ships no
# Android/Java runtime classes, so there is no R8 surface to keep. Documented
# here for completeness — nothing to do.

# ════════════════════════════════════════════════════════════════════════
#  Cross-cutting reflection / serialization safety (over-keep)
# ════════════════════════════════════════════════════════════════════════

# ── @Keep-annotated classes and members (androidx + firebase) ──────────────
-keep,allowobfuscation @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keep @com.google.firebase.annotations.Keep class * { *; }
-keepclassmembers class * {
    @com.google.firebase.annotations.Keep *;
}

# ── Native / JNI methods ───────────────────────────────────────────────────
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# ── Enums: values() / valueOf() are called reflectively by many libs ───────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Parcelable CREATOR ─────────────────────────────────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep class * implements android.os.Parcelable { *; }

# ── Serializable full contract ─────────────────────────────────────────────
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ── Gson (used transitively by flutter_local_notifications, Firebase, etc.) ─
-keep class com.google.gson.**                   { *; }
-dontwarn com.google.gson.**
-keep class com.google.gson.reflect.TypeToken    { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}

# ── Kotlin runtime + metadata ──────────────────────────────────────────────
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-dontwarn org.jetbrains.annotations.**

# ── OkHttp / Okio (transitive via Firebase, ML Kit, RevenueCat) ────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# ── Misc optional transitive deps R8 must not abort on ─────────────────────
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.j2objc.annotations.**
-dontwarn org.checkerframework.**
-dontwarn javax.naming.**
-dontwarn java.beans.**
-dontwarn javax.lang.model.element.**
-dontwarn sun.misc.**

# ── Attributes needed for reflection, generics, and readable stack traces ──
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keepattributes Exceptions
-keepattributes AnnotationDefault
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
