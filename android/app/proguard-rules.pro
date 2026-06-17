# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio & Network attributes
-keepattributes Signature, InnerClasses, AnnotationDefault, EnclosingMethod

# Secure Storage & Cryptography
-keep class androidx.security.crypto.** { *; }
