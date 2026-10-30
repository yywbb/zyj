#!/usr/bin/env python3
"""用现有 Android SDK 构建无第三方依赖的 MinIO APK 下载/校验/安装工具。"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.parse
import zipfile

from build_local_apk import find_tool, run_tool


def validate_download_base(value):
    url = urllib.parse.urlsplit(value)
    if (url.scheme not in ("http", "https") or not url.hostname or url.username or url.password
            or url.query or url.fragment or not url.path.strip("/") or not url.path.endswith("/")):
        raise ValueError("下载地址必须是以 / 结尾的 MinIO 桶路径，不含密钥或查询串")
    return value


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--download-base", required=True, help="例如 https://minio.example/bucket/")
    args = parser.parse_args(argv)
    try:
        base = validate_download_base(args.download_base)
    except ValueError as error:
        parser.error(str(error))
    root = Path(__file__).resolve().parent
    sdk = Path(os.environ["ANDROID_HOME"])
    android = sdk / "platforms/android-34/android.jar"
    result = subprocess.run([find_tool("apksigner"), "verify", "--print-certs", str(root / "zyj_local.apk")],
                            capture_output=True, text=True, check=True)
    signer = re.search(r"Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]{64})", result.stdout)
    if not signer:
        raise ValueError("游戏 APK 缺少可识别的签名")
    with tempfile.TemporaryDirectory(prefix="zyj-downloader-") as directory:
        work = Path(directory)
        config = work / "BuildConfig.java"
        config.write_text("package com.ldfs.zyjdownload; final class BuildConfig {"
                          f"static final String MINIO_BASE={json.dumps(base)};"
                          f"static final String SIGNER_SHA256={json.dumps(signer[1].lower())};}}")
        classes, dex = work / "classes", work / "dex"
        classes.mkdir()
        dex.mkdir()
        subprocess.run(["javac", "--release", "8", "-classpath", str(android), "-d", str(classes),
                        str(config), str(root / "android_downloader/DownloadActivity.java")], check=True)
        run_tool(find_tool("d8"), ["--lib", str(android), "--min-api", "28", "--output", str(dex),
                                  *map(str, classes.rglob("*.class"))])
        unsigned = work / "unsigned.apk"
        run_tool(find_tool("aapt"), ["package", "-f", "-M", str(root / "android_downloader/AndroidManifest.xml"),
                                    "-I", str(android), "-F", str(unsigned)])
        with zipfile.ZipFile(unsigned, "a") as archive:
            archive.write(dex / "classes.dex", "classes.dex")
        output = root / "zyj_downloader.apk"
        run_tool(find_tool("zipalign"), ["-f", "4", str(unsigned), str(output)])
        run_tool(find_tool("apksigner"), ["sign", "--ks", str(root / "debug.keystore"), "--ks-pass", "pass:android",
                                         "--key-pass", "pass:android", str(output)])
        run_tool(find_tool("apksigner"), ["verify", str(output)])
        print(f"已构建并验签：{output}")


if __name__ == "__main__":
    main()
