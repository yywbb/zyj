package com.zyj.local;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.Proxy;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;

final class ReportQueue {
    static final int MAX_FILES = 24;
    static final int MAX_BYTES = 65536;
    final File directory;

    ReportQueue(File directory) throws IOException {
        this.directory = directory;
        if (!directory.isDirectory() && !directory.mkdirs()) throw new IOException("queue unavailable");
        for (File file : files("\\.tmp")) file.delete();
    }

    synchronized File[] files(String suffix) {
        File[] files = directory.listFiles((dir, name) -> name.matches("[0-9a-f]{32}" + suffix));
        if (files == null) return new File[0];
        Arrays.sort(files, Comparator.comparingLong(File::lastModified));
        return files;
    }

    synchronized boolean hasRoom() {
        return files("\\.(json|native)").length < MAX_FILES;
    }

    synchronized boolean save(String id, byte[] data) throws IOException {
        if (!id.matches("[0-9a-f]{32}") || data.length == 0 || data.length > MAX_BYTES) return false;
        File target = new File(directory, id + ".json");
        if (target.exists()) return true;
        if (!hasRoom() && !new File(directory, id + ".native").exists()) return false;
        File temporary = new File(directory, id + ".tmp");
        try {
            try (FileOutputStream output = new FileOutputStream(temporary)) {
                output.write(data);
                output.getFD().sync();
            }
            if (!temporary.renameTo(target)) throw new IOException("queue commit failed");
        } finally {
            temporary.delete();
        }
        return true;
    }

    static byte[] read(InputStream input, int limit) throws IOException {
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        byte[] buffer = new byte[2048];
        int count;
        while ((count = input.read(buffer)) != -1) {
            if (result.size() + count > limit) throw new IOException("report too large");
            result.write(buffer, 0, count);
        }
        return result.toByteArray();
    }

    static byte[] read(File file) throws IOException {
        try (FileInputStream input = new FileInputStream(file)) {
            return read(input, MAX_BYTES);
        }
    }

    void flush(String endpoint, String key) throws IOException {
        for (File file : files("\\.json")) {
            byte[] data = read(file);
            HttpURLConnection connection = (HttpURLConnection) new URL(endpoint).openConnection(Proxy.NO_PROXY);
            try {
                connection.setInstanceFollowRedirects(false);
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json");
                connection.setRequestProperty("X-Client-Log-Key", key);
                connection.setFixedLengthStreamingMode(data.length);
                connection.setDoOutput(true);
                try (java.io.OutputStream output = connection.getOutputStream()) { output.write(data); }
                if (connection.getResponseCode() != 200) return;
                String ack;
                try (InputStream input = connection.getInputStream()) {
                    ack = new String(read(input, 1024), StandardCharsets.UTF_8);
                }
                String id = file.getName().substring(0, 32);
                if (!ack.equals("{\"id\": \"" + id + "\", \"stored\": true}")) return;
                if (!file.delete()) throw new IOException("queue acknowledgement failed");
            } finally {
                connection.disconnect();
            }
        }
    }
}
