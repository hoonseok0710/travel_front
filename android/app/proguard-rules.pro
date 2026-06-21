# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio / Retrofit
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# JSON 파싱 모델 클래스 보호
-keep class com.mookie.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Google Play Core (누락된 클래스 처리)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# 일반 규칙
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn okhttp3.**
-dontwarn okio.**

# Kakao SDK
-keep class com.kakao.sdk.** { *; }
-keep class com.kakao.auth.** { *; }
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.kakao.sdk.common.model.SdkType *;
}

# Kakao Network
-keep interface com.kakao.sdk.**.model.* { *; }
-keep class com.kakao.sdk.**.api.* { *; }