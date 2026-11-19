# Flutter plugins ship their own consumer rules; these cover the rest.

# Play Billing (in_app_purchase)
-keep class com.android.vending.billing.** { *; }

# Google Mobile Ads / UMP consent
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }

# WorkManager (forced newer version, uses Room reflection)
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Flutter deferred components reference Play Core classes that are not bundled.
-dontwarn com.google.android.play.core.**
