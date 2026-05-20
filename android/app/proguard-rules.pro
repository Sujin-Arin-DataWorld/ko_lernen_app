# ── Flutter ─────────────────────────────────────────────────
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.**    { *; }

# ── flutter_tts ─────────────────────────────────────────────
-keep class com.tundralabs.fluttertts.** { *; }

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
