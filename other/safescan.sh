#!/usr/bin/env bash
set -euo pipefail

# 確保是以 root 權限執行，或是提示使用者
if [ "$EUID" -ne 0 ]; then
    echo "❌ 請使用 sudo 或 root 權限執行此腳本。"
    exit 1
fi

echo "=================================================="
echo " Host Info"
echo "=================================================="
hostname
hostname -I || true
echo

echo "=================================================="
echo " nginx/openresty process"
echo "=================================================="
ps -ef | grep -E 'nginx|openresty' | grep -v grep || true
echo

echo "=================================================="
echo " Version"
echo "=================================================="
CMD=""
if command -v openresty &>/dev/null; then
    CMD="openresty"
elif command -v nginx &>/dev/null; then
    CMD="nginx"
fi

if [ -n "$CMD" ]; then
    $CMD -V 2>&1
else
    echo "⚠️ 未找到 nginx 或 openresty 執行檔"
fi
echo

echo "=================================================="
echo " Config Test"
echo "=================================================="
if [ -n "$CMD" ]; then
    $CMD -t 2>&1
fi
echo

echo "=================================================="
echo " Deleted Log FD"
echo "=================================================="
lsof 2>/dev/null | awk '/deleted/ && ($1=="nginx" || $1=="openresty")' || true
echo

echo "=================================================="
echo " Listening Ports"
echo "=================================================="
ss -lntp | grep -E ':(80|81|443|8080|8443|13306|3306|6379)' || true
echo

echo "=================================================="
echo " Worker Connections"
echo "=================================================="
ss -antp | grep -E 'nginx|openresty' | head -50 || true
echo
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
echo "=================================================="
echo " Dynamic Path Detection & Inspect"
echo "=================================================="
# 自動偵測配置路徑
CONF_PATH=""
if [ -n "$CMD" ]; then
    # 修正重點：加上 -e 參數，避免 grep 把 --prefix 當成選項；同時處理可能帶有雙引號或單引號的路徑
    CONF_PREFIX=$($CMD -V 2>&1 | awk '{
      for (i=1;i<=NF;i++) {
        if ($i ~ /^--prefix=/) {
          sub(/^--prefix=/,"",$i)
          gsub(/\047/,"",$i)
          print $i
          exit
        }
      }
    }')
CONF_PATH="${CONF_PREFIX}/conf"
    if [ -n "$CONF_PATH" ]; then
        CONF_PATH="${CONF_PATH}/conf"
    fi
fi

# 如果找不到動態路徑，或動態路徑不存在，則嘗試常見預設路徑
if [ -z "$CONF_PATH" ] || [ ! -d "$CONF_PATH" ]; then
    for path in "/usr/local/openresty/nginx/conf" "/etc/nginx" "/usr/local/nginx/conf"; do
        if [ -d "$path" ]; then
            CONF_PATH="$path"
            break
        fi
    done
fi

if [ -n "$CONF_PATH" ] && [ -d "$CONF_PATH" ]; then
    echo "🔍 正在檢查配置路徑: $CONF_PATH"
    grep -RInE 'rewrite|alias|proxy_pass|access_by_lua|content_by_lua|set_by_lua|ngx\.exec|ngx\.location\.capture|\$[1-9]' "$CONF_PATH" 2>/dev/null || true
    echo
    echo "🔍 Stream 配置檢查:"
    grep -RIn "stream {" "$CONF_PATH" 2>/dev/null || true
    if [ -d "$CONF_PATH/streams" ]; then
        grep -RIn "proxy_pass" "$CONF_PATH/streams" 2>/dev/null || true
    fi
else
    echo "⚠️ 找不到有效的 Nginx/OpenResty 配置路徑，跳過過濾檢查。"
fi
echo
echo "=================================================="
echo " nginx/openresty deleted log fix"
echo "=================================================="

BEFORE=$(lsof 2>/dev/null | awk '/deleted/ && ($1=="nginx" || $1=="openresty")' || true)

if [ -n "$BEFORE" ]; then
    echo "⚠️ 發現已刪除但未釋放的日誌檔案描述符 (FD)，嘗試重新打開..."

    # 精準尋找 nginx/openresty 的 master process pid
    MASTER_PID=$(ps -ef | grep -E 'nginx|openresty' | grep 'master process' | grep -v grep | awk '{print $2}' | head -n 1 || true)

    if [ -n "$MASTER_PID" ]; then
        echo "📢 發送 USR1 訊號至 Master PID: $MASTER_PID"
        kill -USR1 "$MASTER_PID"
        sleep 1
    else
        echo "❌ 找不到運行中的 Master 處理程序"
    fi

    AFTER=$(lsof 2>/dev/null | awk '/deleted/ && ($1=="nginx" || $1=="openresty")' || true)

    if [ -z "$AFTER" ]; then
        echo "✅ 已刪除的 FD 已成功釋放"
    else
        echo "⚠️ 部分已刪除的 FD 依然存在"
        echo "$AFTER"
    fi
else
    echo "✅ 沒有發現未釋放的已刪除 FD"
fi

echo
echo "=================================================="
echo " DONE"
echo "=================================================="
