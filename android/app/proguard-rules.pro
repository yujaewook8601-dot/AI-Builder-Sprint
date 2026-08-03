# AndroidX Startup & WorkManager Keep Rules (CRITICAL FIX FOR RELEASE BUILD)
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }

# Room Framework Reflection Keep
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}

# home_widget Native Keep Rules
-keep class es.antonborri.home_widget.** { *; }
-keep class com.example.pixel_hero.QuestWidgetProvider { *; }
