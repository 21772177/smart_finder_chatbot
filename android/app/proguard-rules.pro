# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Drift database classes
-keep class com.secondbrain.second_brain.** { *; }

# Keep SQLCipher
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.* { *; }

# Keep MethodChannel handlers
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Keep Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Don't warn about missing classes
-dontwarn io.flutter.embedding.**
-dontwarn net.sqlcipher.**
