# ProGuard Rules for SkyWings1942

# Keep all application classes
-keep class com.skywings.reborn.** { *; }
-keep class com.skywings.reborn.MainActivity { *; }

# Keep AndroidX classes
-keep class androidx.** { *; }
-keepnames class androidx.** 

# Keep Android classes
-keep class android.** { *; }
-keepnames class android.**

# Keep library classes
-keep class com.google.android.material.** { *; }
-keepnames class com.google.android.material.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep View constructors for inflation
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# Keep enum values and valueOf() methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
