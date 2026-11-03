package com.zyj.local;

import java.io.File;
import java.nio.charset.StandardCharsets;

public final class ReportQueueTest {
    public static void main(String[] args) throws Exception {
        ReportQueue queue = new ReportQueue(new File(args[1]));
        String id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        if ("basic".equals(args[0])) {
            File orphan = new File(queue.directory, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.tmp");
            assert orphan.createNewFile();
            new ReportQueue(queue.directory);
            assert !orphan.exists();
            byte[] data = "original".getBytes(StandardCharsets.UTF_8);
            assert queue.save(id, data);
            assert queue.save(id, "changed".getBytes(StandardCharsets.UTF_8));
            assert new String(ReportQueue.read(queue.files("\\.json")[0]), StandardCharsets.UTF_8).equals("original");
            assert !queue.save("../../escape", data);
            assert !queue.save(id, new byte[65537]);
            for (int i = 1; i < 24; i++) assert queue.save(String.format("%032x", i), data);
            assert !queue.save("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", data);
            assert queue.files("\\.json").length == 24;
            assert queue.files("\\.tmp").length == 0;
            System.out.println("OK");
        } else {
            String payload = "{\"id\":\"" + id + "\",\"kind\":\"lua\",\"build\":\"bbbbbbbbbbbbbbbb\","
                + "\"time\":1800000000,\"sdk\":29,\"abi\":\"arm64-v8a\",\"source\":\"ui\",\"trace\":\"lua_error=runtime\"}";
            assert queue.save(id, payload.getBytes(StandardCharsets.UTF_8));
            try { queue.flush(args[2], args[3]); } catch (java.io.IOException ignored) {}
            System.out.println(queue.files("\\.json").length);
        }
    }
}
