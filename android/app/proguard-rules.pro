# AGP 9 / R8 full mode + Google Mobile Ads / WorkManager.
# Prevents: Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
