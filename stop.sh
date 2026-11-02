#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$BASE_DIR/logs/mock_server.pid"
PORT=14600
ADMIN_PORT=14601

echo "=================================================="
echo "        正在停止《作妖记》模拟服务端              "
echo "=================================================="

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "停止 mock_server.py (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

for p in $PORT $ADMIN_PORT; do
    pids=$(lsof -t -iTCP:$p -sTCP:LISTEN 2>/dev/null)
    if [ -n "$pids" ]; then
        echo "清理端口 $p 进程 (PID: $pids)..."
        kill $pids 2>/dev/null || true
    fi
done

pkill -f "python3.*mock_server.py" 2>/dev/null || true
sleep 1

echo "[✔] 《作妖记》服务已完全停止！"
