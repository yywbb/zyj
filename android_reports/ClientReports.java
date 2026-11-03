package com.zyj.local;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import android.os.SystemClock;
import android.util.Log;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.JSONObject;

public final class ClientReports {
    private static ReportQueue queue;
    private static File nativeFile;
    private static boolean nativeLoaded;
    private static long window;
    private static int count;
    private static final AtomicBoolean uploading = new AtomicBoolean();
    private static final ScheduledExecutorService worker = Executors.newSingleThreadScheduledExecutor(task -> {
        Thread thread = new Thread(task, "local-reports"); thread.setDaemon(true); return thread;
    });
    private static native boolean nativeInstall(String path, String build);

    static synchronized void initialize(Context context) {
        if (queue != null) return;
        try {
            queue = new ReportQueue(new File(context.getNoBackupFilesDir(), "client_reports"));
            collectNative();
            if (queue.hasRoom()) {
                nativeFile = new File(queue.directory, id() + ".native");
                try {
                    System.loadLibrary("localreports");
                    nativeLoaded = true;
                    installThread();
                } catch (Throwable ignored) { Log.w("LocalReports", "native capture unavailable"); }
            }
            final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
            Thread.setDefaultUncaughtExceptionHandler((thread, error) -> {
                try {
                    StringBuilder trace = new StringBuilder("exception=").append(error.getClass().getName());
                    StackTraceElement[] frames = error.getStackTrace();
                    for (int i = 0; i < Math.min(frames.length, 64); i++) {
                        trace.append("\nat ").append(frames[i]);
                    }
                    persist("java", "process", trace.toString(), BuildConfig.BUILD, System.currentTimeMillis() / 1000, abi());
                } catch (Throwable ignored) {
                    // 崩溃采集失败不能吞掉原来的崩溃处理。
                } finally {
                    if (previous != null) previous.uncaughtException(thread, error);
                    else { Process.killProcess(Process.myPid()); System.exit(10); }
                }
            });
            Application application = (Application) context.getApplicationContext();
            application.registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
                public void onActivityCreated(Activity activity, Bundle state) { installThread(); }
                public void onActivityResumed(Activity activity) { installThread(); requestUpload(); }
                public void onActivityStarted(Activity activity) {}
                public void onActivityPaused(Activity activity) {}
                public void onActivityStopped(Activity activity) {}
                public void onActivitySaveInstanceState(Activity activity, Bundle state) {}
                public void onActivityDestroyed(Activity activity) {}
            });
            worker.scheduleWithFixedDelay(ClientReports::requestUpload, 10, 60, TimeUnit.SECONDS);
        } catch (Throwable ignored) {
            Log.w("LocalReports", "diagnostic initialization unavailable");
        }
    }

    public static synchronized void installThread() {
        if (nativeLoaded && nativeFile != null) {
            try { nativeInstall(nativeFile.getAbsolutePath(), BuildConfig.BUILD); }
            catch (Throwable ignored) { Log.w("LocalReports", "native capture unavailable"); }
        }
    }

    public static void reportLua(String source, String trace) {
        try {
            if (!"ui".equals(source) && !"net".equals(source)) return;
            if (trace == null || trace.length() > 16000) return;
            persist("lua", source, trace, BuildConfig.BUILD, System.currentTimeMillis() / 1000, abi());
            requestUpload();
        } catch (Throwable ignored) {
            Log.w("LocalReports", "Lua diagnostic deferred");
        }
    }

    private static String id() { return UUID.randomUUID().toString().replace("-", ""); }
    private static String abi() { return Process.is64Bit() ? "arm64-v8a" : "armeabi-v7a"; }

    private static synchronized void persist(String kind, String source, String trace, String build, long time, String abi) throws Exception {
        if (queue == null) return;
        long now = SystemClock.elapsedRealtime();
        if (now - window >= 60000) { window = now; count = 0; }
        if (count >= 10) return;
        count++;
        String id = id();
        queue.save(id, payload(id, kind, source, trace, build, time, abi));
    }

    private static byte[] payload(String id, String kind, String source, String trace, String build, long time, String abi) throws Exception {
        JSONObject report = new JSONObject();
        report.put("id", id); report.put("kind", kind); report.put("source", source); report.put("trace", trace);
        report.put("build", build); report.put("time", time); report.put("abi", abi); report.put("sdk", Build.VERSION.SDK_INT);
        return report.toString().getBytes(StandardCharsets.UTF_8);
    }

    private static void collectNative() {
        for (File raw : queue.files("\\.native")) {
            try {
                String trace = new String(ReportQueue.read(raw), StandardCharsets.UTF_8).trim();
                if (!trace.contains("\nsignal=")) { raw.delete(); continue; }
                String build = null, abi = null;
                long time = 0;
                for (String line : trace.split("\n")) {
                    if (line.startsWith("build=")) build = line.substring(6);
                    if (line.startsWith("abi=")) abi = line.substring(4);
                    if (line.startsWith("time=")) time = Long.parseLong(line.substring(5));
                }
                if (build == null || abi == null) continue;
                String id = raw.getName().substring(0, 32);
                if (queue.save(id, payload(id, "native", "process", trace, build, time, abi))) raw.delete();
            } catch (Exception ignored) { Log.w("LocalReports", "native diagnostic retained"); }
        }
    }

    private static void requestUpload() {
        if (queue == null || !uploading.compareAndSet(false, true)) return;
        worker.execute(() -> {
            try { queue.flush(BuildConfig.ENDPOINT, BuildConfig.UPLOAD_KEY); }
            catch (Exception ignored) { /* 保留未确认文件；进程存活时60秒后或下次启动再传。 */ }
            finally { uploading.set(false); }
        });
    }
}
