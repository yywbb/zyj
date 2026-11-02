#!/bin/bash
# 用法: ./set_ip.sh [新IP] [账号槽位数量(可选，默认3)]
TARGET_IP="${1:-10.66.0.11}"
ACCOUNTS="${2:-3}"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=================================================="
echo "    正在为《作妖记》重构客户端 APK 连接 IP: $TARGET_IP"
echo "=================================================="

cd "$BASE_DIR" || exit 1
python3 build_local_apk.py --server-ip "$TARGET_IP" --accounts "$ACCOUNTS"

if [ $? -eq 0 ]; then
    echo "=================================================="
    echo "[✔] 客户端重打包完成！"
    echo "生成 APK 路径: $BASE_DIR/zyj_local.apk"
    echo "游戏服务连接目标: $TARGET_IP:14600 (支持 $ACCOUNTS 个多账号独立槽位)"
    echo "=================================================="
else
    echo "[✘] 客户端打包失败，请检查上方日志。"
    exit 1
fi
