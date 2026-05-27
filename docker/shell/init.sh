#!/command/with-contenv sh
. /docker/shell/common.sh
set -e

TASK_DIR="/.lego/tasks.d"
if [ -d "$TASK_DIR" ]; then
    echo "[Cleanup] Checking for abandoned configurations..."
    for conf in "$TASK_DIR"/*.conf; do
        [ -e "$conf" ] || continue
        DOMAIN=$(basename "$conf" .conf)
        CERT_FILE=$(get_cert_path "$DOMAIN")
        if [ ! -f "$CERT_FILE" ]; then
            echo "[Cleanup] Removing $DOMAIN (Certificate not found at $CERT_FILE)"
            rm "$conf"
        fi
    done
fi
