#!/command/with-contenv sh
. /docker/shell/common.sh
set -e

CONF_DIR="/.lego/tasks.d"

if [ ! -d "$CONF_DIR" ] || [ -z "$(ls -A "$CONF_DIR" 2>/dev/null)" ]; then
    echo "[Batch] No configurations found in $CONF_DIR. Nothing to renew."
    exit 0
fi

echo "[Batch] Starting batch renewal at $(date)"

for conf in "$CONF_DIR"/*.conf; do
    [ -e "$conf" ] || continue
	echo "-----------------------------------"
    echo "[Batch] Processing config: $(basename "$conf" .conf)"
	(
        . "$conf"
        echo "[Process] Running lego for args: $LEGO_ARGS"

        /usr/bin/lego --path /.lego $LEGO_ARGS
        
        if [ $? -eq 0 ]; then
            echo "[Success] Renewal successful."
        else
            echo "[Error] Renewal failed for $(basename "$conf")."
        fi
    )
done

echo "-----------------------------------"
echo "[Batch] All tasks processed."
