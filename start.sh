#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$BASE_DIR/logs"
PID_FILE="$LOG_DIR/mock_server.pid"
LOG_FILE="$LOG_DIR/mock_server.log"
PORT=14600
ADMIN_PORT=14601

mkdir -p "$LOG_DIR"

echo "=================================================="
echo "        正在启动《作妖记》本地模拟服务端          "
echo "=================================================="

# Check if already running
if ss -tln | grep -q ":$PORT "; then
    echo "[!] 端口 $PORT 已经在监听中！"
    "$BASE_DIR/status.sh"
    exit 0
fi

cd "$BASE_DIR" || exit 1

echo "启动 Python 模拟服 (通信端口: $PORT, 管理后台: $ADMIN_PORT)..."
setsid nohup python3 -u mock_server.py --admin-port $ADMIN_PORT </dev/null > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

sleep 2

if ss -tln | grep -q ":$PORT "; then
    echo "[✔] 《作妖记》服务端启动成功！"
    echo ""
    "$BASE_DIR/status.sh"
else
    echo "[✘] 启动失败，请检查日志: $LOG_FILE"
    tail -n 20 "$LOG_FILE"
    exit 1
fi
