# Keep SLF4J Logger Implementation
-keep class org.slf4j.** { *; }

# Keep Logging classes if you're using a specific implementation
-keep class ch.qos.logback.** { *; }

# Prevent class stripping
-dontwarn org.slf4j.**
-dontwarn ch.qos.logback.**

# Keep Flutter Data classes (Models)
-keep class com.your.package.name.src.features.parayer_screen.controller.model.** { *; }

# Keep Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Timezone data
-keep class com.google.android.gms.internal.gtm.** { *; }

-keep public class com.google.android.gms.** { *; }