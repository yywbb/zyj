"""构建独立诊断DEX/双ABI信号采集器，并向原二进制Manifest追加私有启动Provider。"""

import hashlib
import json
import os
from pathlib import Path
import platform
import struct
import subprocess
import tempfile

from zyj_server.client_reports import load_key


def inject_provider(raw):
    assert struct.unpack_from("<HH", raw) == (3, 8), "Expected Android binary XML"
    chunks = []
    offset = 8
    while offset < len(raw):
        kind, header, size = struct.unpack_from("<HHI", raw, offset)
        assert header >= 8 and size >= header and offset + size <= len(raw)
        chunks.append((kind, raw[offset:offset + size]))
        offset += size
    assert offset == len(raw) and chunks[0][0] == 1
    pool = chunks[0][1]
    count, styles, flags, start, style_start = struct.unpack_from("<IIIII", pool, 8)
    assert styles == 0 and style_start == 0 and not flags & 0x100, "Expected original UTF16 string pool"
    offsets = list(struct.unpack_from(f"<{count}I", pool, 28))
    strings = []
    for value in offsets:
        length = struct.unpack_from("<H", pool, start + value)[0]
        assert length < 0x8000
        strings.append(pool[start + value + 2:start + value + 2 + length * 2].decode("utf-16le"))
    content = bytearray(pool[start:])
    for value in ("com.zyj.local.ReportProvider", "com.ldfs.zyjyg.local.clientreports"):
        assert value not in strings, "Provider already injected"
        offsets.append(len(content))
        content.extend(struct.pack("<H", len(value)) + value.encode("utf-16le") + b"\0\0")
        strings.append(value)
    content.extend(b"\0" * (-len(content) % 4))
    start = 28 + len(strings) * 4
    pool = struct.pack("<HHIIIIII", 1, 28, start + len(content), len(strings), 0, flags, start, 0)
    chunks[0] = (1, pool + struct.pack(f"<{len(strings)}I", *offsets) + content)
    index = strings.index
    namespace = index("http://schemas.android.com/apk/res/android")
    name = index("provider")
    attributes = b""
    for key, value in (("name", "com.zyj.local.ReportProvider"), ("exported", False),
                       ("authorities", "com.ldfs.zyjyg.local.clientreports")):
        text = index(value) if isinstance(value, str) else 0xffffffff
        attributes += struct.pack("<IIIHBBI", namespace, index(key), text, 8, 0,
                                  3 if isinstance(value, str) else 0x12,
                                  text if isinstance(value, str) else 0)
    node = (struct.pack("<HHIII", 0x102, 16, 36 + len(attributes), 0, 0xffffffff)
            + struct.pack("<IIHHHHHH", 0xffffffff, name, 20, 20, 3, 0, 0, 0) + attributes
            + struct.pack("<HHIIIII", 0x103, 16, 24, 0, 0xffffffff, 0xffffffff, name))
    positions = [i for i, (kind, chunk) in enumerate(chunks)
                 if kind == 0x103 and struct.unpack_from("<I", chunk, 20)[0] == index("application")]
    assert len(positions) == 1
    chunks.insert(positions[0], (0x102, node))
    result = b"".join(chunk for _, chunk in chunks)
    return struct.pack("<HHI", 3, 8, 8 + len(result)) + result


def build_assets(root, server_ip, patched_lua, find_tool, run_tool):
    root = Path(root)
    sdk = Path(os.environ["ANDROID_HOME"])
    android = sdk / "platforms/android-34/android.jar"
    source = root / "android_reports"
    ndk = Path(os.environ.get("ANDROID_NDK_HOME", sdk / "ndk/27.2.12479018"))
    host = "darwin-x86_64" if platform.system() == "Darwin" else "windows-x86_64" if os.name == "nt" else "linux-x86_64"
    compiler = ndk / "toolchains/llvm/prebuilt" / host / "bin" / ("clang.exe" if os.name == "nt" else "clang")
    if not compiler.is_file():
        raise FileNotFoundError("原生崩溃采集需要Android NDK r27c；可用ANDROID_NDK_HOME指定，不允许静默漏打采集器")
    digest = hashlib.sha256()
    digest.update(Path(__file__).read_bytes())
    for name, data in sorted(patched_lua.items()):
        digest.update(name.encode()); digest.update(data)
    for path in sorted(source.glob("*")):
        if path.is_file() and not path.name.startswith("._"):
            digest.update(path.name.encode()); digest.update(path.read_bytes())
    digest.update(server_ip.encode())
    build = digest.hexdigest()[:16]
    key = load_key(root / "client_reports.key")
    with tempfile.TemporaryDirectory(prefix="zyj-reports-") as directory:
        work = Path(directory)
        config = work / "BuildConfig.java"
        config.write_text("package com.zyj.local; final class BuildConfig {"
                          f"static final String ENDPOINT={json.dumps('http://' + server_ip + ':14602/v1/reports')};"
                          f"static final String UPLOAD_KEY={json.dumps(key)};"
                          f"static final String BUILD={json.dumps(build)};}}")
        classes, dex = work / "classes", work / "dex"
        classes.mkdir(); dex.mkdir()
        subprocess.run(["javac", "-encoding", "UTF-8", "--release", "8", "-classpath", str(android), "-d", str(classes),
                        str(config), *(str(source / name) for name in ("ClientReports.java", "ReportProvider.java", "ReportQueue.java"))], check=True)
        run_tool(find_tool("d8"), ["--lib", str(android), "--min-api", "24", "--output", str(dex),
                                 *map(str, sorted(classes.rglob("*.class")))])
        assets = {"classes2.dex": (dex / "classes.dex").read_bytes()}
        for abi, target in (("arm64-v8a", "aarch64-linux-android24"), ("armeabi-v7a", "armv7a-linux-androideabi24")):
            library = work / (abi + ".so")
            subprocess.run([str(compiler), "--target=" + target, "-shared", "-fPIC", "-O2", "-Wall", "-Wextra", "-Werror",
                            "-Wl,-z,relro,-z,now,-z,max-page-size=16384", "-Wl,--build-id=sha1", "-o", str(library),
                            str(source / "native_reports.c")], check=True)
            assets["lib/" + abi + "/liblocalreports.so"] = library.read_bytes()
    assets["assets/LocalClientReports.json"] = json.dumps({"build": build, "endpoint": "http://" + server_ip + ":14602/v1/reports"}).encode()
    print(f"  [Reports] Built upload-only diagnostics {build} (Java + arm64/armv7)")
    return assets
