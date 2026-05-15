#!/usr/bin/env bash
set -u

# --- 基礎資訊 ---
VERSION="1.3.0"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/etcvs/NRCheck/main/modules"
NGINX_BIN=$(command -v nginx || echo "/usr/local/openresty/nginx/sbin/nginx")
OPENRESTY_BIN="/usr/local/openresty/bin/openresty"
ERROR_LOGS="/usr/local/openresty/nginx/logs/error.log /var/log/nginx/error.log"
TMP_CONF="/tmp/nginx_active_$$.conf"

# 定義要檢查的模組清單 (以後有新的就直接加在陣列後面)
MODULES=("CVE-2026-42945.sh")

echo "=================================================="
echo " NRCheck - Nginx Security Auditor v$VERSION"
echo " Host: $(hostname)"
echo " Time: $(date '+%F %T')"
echo "=================================================="

# 1. 導出 Active Config
if [ -x "$NGINX_BIN" ]; then
    "$NGINX_BIN" -T > "$TMP_CONF" 2>/tmp/nginxT.err
else
    nginx -T > "$TMP_CONF" 2>/tmp/nginxT.err
fi

if [ ! -s "$TMP_CONF" ]; then
    echo "[ERROR] Nginx configuration dump failed. 請看 /tmp/nginxT.err"
    cat /tmp/nginxT.err 2>/dev/null || true
    exit 1
fi

echo "[OK] Active config dumped to $TMP_CONF"
echo

# 2. 迭代並執行模組
for module_name in "${MODULES[@]}"; do
    echo "=================================================="
    echo " Running Module: $module_name"
    echo "=================================================="
    
    # 嘗試從 GitHub 抓取並直接執行 (不存檔)，同時帶入 4 個參數
    if ! curl -fsSL "$GITHUB_RAW_BASE/$module_name" | bash -s -- "$TMP_CONF" "$NGINX_BIN" "$OPENRESTY_BIN" "$ERROR_LOGS"; then
        echo "[WARN] Could not load module $module_name from remote."
    fi
    echo
done

# 清理暫存檔 (如需自動清理，可取消下一行的註解)
# rm -f "$TMP_CONF" /tmp/nginxT.err

echo "NRCheck Complete."