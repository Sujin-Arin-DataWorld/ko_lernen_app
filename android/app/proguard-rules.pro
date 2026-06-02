# ── Flutter ─────────────────────────────────────────────────
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.**    { *; }

# Play Core (Deferred Components — wir nutzen das nicht, aber Flutter
# referenziert die Klassen unconditional → ProGuard-Warnung ignorieren)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Firebase / Google Sign-In (für spätere Phase 4)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── flutter_tts ─────────────────────────────────────────────
-keep class com.tundralabs.fluttertts.** { *; }

# ── ML Kit Text Recognition (google_mlkit_text_recognition) ──
# Das Plugin referenziert ALLE Sprach-Erkenner (Chinese/Devanagari/
# Japanese/Korean), wir bündeln aber nur Latin/Korean → R8 bricht den
# Release-Build mit "Missing class" ab. Diese Regeln (von R8 selbst in
# build/app/outputs/mapping/release/missing_rules.txt generiert)
# unterdrücken die Warnungen; der Korean-Erkenner bleibt via -keep erhalten.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ── csv (uses reflection lightly) ──────────────────────────
-keep class * implements java.io.Serializable { *; }

# ── Allgemeine Sicherheit ──────────────────────────────────
# Native-Methoden behalten
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum-Werte schützen
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable-Klassen schützen
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Source-File-Info für Stack Traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
