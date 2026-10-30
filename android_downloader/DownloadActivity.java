package com.ldfs.zyjdownload;

import android.app.Activity;
import android.content.*;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.*;
import android.provider.OpenableColumns;
import android.provider.Settings;
import android.view.View;
import android.widget.*;
import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.security.MessageDigest;

public final class DownloadActivity extends Activity {
    private EditText link;
    private TextView status;
    private Button download, install;
    private boolean busy;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int pad = (int)(24 * getResources().getDisplayMetrics().density);
        layout.setPadding(pad, pad, pad, pad);
        TextView title = new TextView(this);
        title.setText("作妖记 · 简易下载");
        title.setTextSize(25);
        layout.addView(title);
        TextView help = new TextView(this);
        help.setText("粘贴本轮 MinIO 更新链接，下载校验后安装。\n不打开浏览器，不修改游戏存档。\n网络中断后请重新下载；安装仍需您确认。");
        help.setTextSize(16);
        help.setPadding(0, pad, 0, pad);
        layout.addView(help);
        link = new EditText(this);
        link.setHint("MinIO 链接（含 #sha256= 校验值）");
        link.setInputType(android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_VARIATION_URI);
        link.setMaxLines(4);
        link.setText(getPreferences(0).getString("url", ""));
        layout.addView(link);
        Button paste = new Button(this);
        paste.setText("粘贴链接");
        paste.setOnClickListener(v -> {
            ClipboardManager clipboard = (ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
            if (clipboard.hasPrimaryClip() && clipboard.getPrimaryClip().getItemCount() > 0)
                link.setText(clipboard.getPrimaryClip().getItemAt(0).coerceToText(this));
        });
        layout.addView(paste);
        download = new Button(this);
        download.setText("下载并校验 APK");
        download.setOnClickListener(v -> startDownload());
        layout.addView(download);
        install = new Button(this);
        install.setText("安装已校验的更新");
        install.setEnabled(apk().isFile() && getPreferences(0).contains("verified"));
        install.setOnClickListener(v -> install());
        layout.addView(install);
        status = new TextView(this);
        status.setTextSize(16);
        status.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
        status.setPadding(0, pad, 0, 0);
        status.setText("仅接受指定 MinIO 的文件，并检查 SHA256、游戏包名和签名。");
        layout.addView(status);
        setContentView(layout);
        acceptIntent(getIntent());
    }

    @Override protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        acceptIntent(intent);
    }

    private void acceptIntent(Intent intent) {
        String value = intent.getStringExtra("url");
        if (value == null && Intent.ACTION_SEND.equals(intent.getAction())) value = intent.getStringExtra(Intent.EXTRA_TEXT);
        if (value != null && !busy) link.setText(value.trim());
    }

    private File apk() { return new File(getCacheDir(), "game.apk"); }

    private void show(String message) { runOnUiThread(() -> status.setText(message)); }

    private static String hex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) result.append(String.format("%02x", b & 255));
        return result.toString();
    }

    private void startDownload() {
        if (busy) return;
        final String expected;
        String value = link.getText().toString().trim();
        try {
            URI uri = new URI(value), base = new URI(BuildConfig.MINIO_BASE);
            if (!base.getScheme().equals(uri.getScheme()) || !base.getHost().equalsIgnoreCase(uri.getHost())
                    || base.getPort() != uri.getPort() || uri.getUserInfo() != null
                    || !uri.getRawPath().startsWith(base.getRawPath())
                    || uri.getFragment() == null || !uri.getFragment().matches("sha256=[a-fA-F0-9]{64}"))
                throw new IllegalArgumentException();
            expected = uri.getFragment().substring(7).toLowerCase(java.util.Locale.ROOT);
            // 保留预签名查询串的原始编码，不能二次转义。
            URL signed = new URL(value.substring(0, value.indexOf('#')));
            getPreferences(0).edit().putString("url", value).apply();
            busy = true;
            download.setEnabled(false);
            install.setEnabled(false);
            new Thread(() -> transfer(signed, expected), "minio-download").start();
        } catch (Exception error) {
            status.setText("链接无效：请粘贴指定 MinIO 的完整链接，包含 #sha256= 校验值。");
        }
    }

    private void transfer(URL url, String expected) {
        File partial = new File(getCacheDir(), "game.part");
        HttpURLConnection connection = null;
        boolean success = false;
        try {
            connection = (HttpURLConnection)url.openConnection();
            connection.setConnectTimeout(20000);
            connection.setReadTimeout(30000);
            connection.setInstanceFollowRedirects(false);
            if (connection.getResponseCode() != 200) throw new IOException("下载失败，HTTP " + connection.getResponseCode() + "（链接过期请获取新链接）");
            long length = connection.getContentLengthLong(), received = 0, reported = 0;
            long maximum = 512L * 1024 * 1024;
            if (length < 1 || length > maximum) throw new IOException("文件大小无效");
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            try (InputStream input = connection.getInputStream(); FileOutputStream output = new FileOutputStream(partial)) {
                byte[] buffer = new byte[128 * 1024];
                int count;
                while ((count = input.read(buffer)) != -1) {
                    received += count;
                    if (received > length || received > maximum) throw new IOException("文件超过声明大小");
                    output.write(buffer, 0, count);
                    digest.update(buffer, 0, count);
                    if (received - reported >= 1024 * 1024) {
                        reported = received;
                        show("下载中 " + (received * 100 / length) + "% · " + (received / 1024 / 1024) + " MB");
                    }
                }
                output.getFD().sync();
            }
            if (received != length || !expected.equals(hex(digest.digest()))) throw new IOException("下载不完整或 SHA256 不符，请重试");
            PackageInfo info = getPackageManager().getPackageArchiveInfo(partial.getPath(), PackageManager.GET_SIGNING_CERTIFICATES);
            if (info == null || !"com.ldfs.zyjyg.local".equals(info.packageName) || info.signingInfo == null
                    || info.signingInfo.getApkContentsSigners().length != 1
                    || !BuildConfig.SIGNER_SHA256.equals(hex(MessageDigest.getInstance("SHA-256")
                        .digest(info.signingInfo.getApkContentsSigners()[0].toByteArray()))))
                throw new IOException("不是受信任的作妖记本地安装包，已拒绝");
            Files.move(partial.toPath(), apk().toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
            getPreferences(0).edit().putString("verified", expected).apply();
            success = true;
            show("校验通过。点击“安装已校验的更新”，按系统提示确认覆盖安装；游戏进度保留。");
        } catch (Exception error) {
            partial.delete();
            show(error instanceof IOException ? error.getMessage() : "下载或签名校验失败，请重新下载。");
        } finally {
            if (connection != null) connection.disconnect();
            final boolean ready = success;
            runOnUiThread(() -> { busy = false; download.setEnabled(true); install.setEnabled(ready); });
        }
    }

    private void install() {
        if (!getPackageManager().canRequestPackageInstalls()) {
            status.setText("请允许“作妖记下载”安装应用，返回后再点安装。");
            startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + getPackageName())));
            return;
        }
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(Uri.parse("content://com.ldfs.zyjdownload.apk/game.apk"), "application/vnd.android.package-archive");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        startActivity(intent);
    }

    public static final class ApkProvider extends ContentProvider {
        private File file(Uri uri) {
            if (!"/game.apk".equals(uri.getPath())) throw new SecurityException("Invalid path");
            return new File(getContext().getCacheDir(), "game.apk");
        }
        @Override public boolean onCreate() { return true; }
        @Override public String getType(Uri uri) { file(uri); return "application/vnd.android.package-archive"; }
        @Override public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
            if (!"r".equals(mode)) throw new SecurityException("Read only");
            return ParcelFileDescriptor.open(file(uri), ParcelFileDescriptor.MODE_READ_ONLY);
        }
        @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) {
            File apk = file(uri);
            MatrixCursor result = new MatrixCursor(new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});
            result.addRow(new Object[]{"作妖记更新.apk", apk.length()});
            return result;
        }
        @Override public Uri insert(Uri uri, ContentValues values) { throw new UnsupportedOperationException(); }
        @Override public int delete(Uri uri, String where, String[] args) { throw new UnsupportedOperationException(); }
        @Override public int update(Uri uri, ContentValues values, String where, String[] args) { throw new UnsupportedOperationException(); }
    }
}
