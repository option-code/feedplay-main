# Add project specific ProGuard rules here.

# Facebook Audience Network SDK
-keep class com.facebook.ads.** { *; }
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.ads.**
-dontwarn com.facebook.infer.annotation.**

# Unity Ads SDK
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# Google Mobile Ads Mediation
-keep class com.google.ads.mediation.** { *; }
-dontwarn com.google.ads.mediation.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

