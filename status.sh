#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=14600
ADMIN_PORT=14601

echo "------------------------------------------------------------"
echo "《作妖记》(zyj) 服务状态检查 (IP: 10.66.0.11 / 192.168.101.63)"
echo "------------------------------------------------------------"

check_port() {
    local name="$1"
    local port="$2"
    if ss -tln | grep -q ":$port "; then
        echo -e "[\e[32mRUNNING\e[0m] $name 正在运行 (端口: $port)"
    else
        echo -e "[\e[31mSTOPPED\e[0m] $name 未运行 (端口: $port)"
    fi
}

check_port "核心通信 TCP 端口 (mock_server.py)" $PORT
check_port "网页管理后台 HTTP (AdminServer)" $ADMIN_PORT

echo "------------------------------------------------------------"
echo "游戏核心服: 10.66.0.11:$PORT (无需 ADB 直连)"
echo "网页管理台: http://10.66.0.11:$ADMIN_PORT/"
echo "客户端安装包: $BASE_DIR/zyj_local.apk"
echo "------------------------------------------------------------"
