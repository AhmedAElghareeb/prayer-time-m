# Keep SLF4J Logger Implementation
-keep class org.slf4j.** { *; }

# Keep Logging classes if you're using a specific implementation
-keep class ch.qos.logback.** { *; }

# Prevent class stripping
-dontwarn org.slf4j.**
-dontwarn ch.qos.logback.**