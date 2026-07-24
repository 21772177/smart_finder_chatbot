# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep app's own classes
-keep class com.secondbrain.second_brain.** { *; }

# Keep SQLCipher
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.* { *; }

# Keep MethodChannel handlers
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.api.client.http.** { *; }
-keep class com.google.api.client.json.** { *; }

# ML Kit text recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.crashlytics.internal.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firebase Core
-keep class com.google.firebase.FirebaseApp.** { *; }
-keep class com.google.firebase.components.** { *; }

# Don't warn about missing classes
-dontwarn io.flutter.embedding.**
-dontwarn net.sqlcipher.**
-dontwarn com.google.android.gms.**
