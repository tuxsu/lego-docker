#!/command/with-contenv sh
. /docker/shell/common.sh
set -e

MODE_ARG=$(echo $LEGO_ARGS | awk '{print $1}')

if [ "$MODE_ARG" = "daemon" ]; then
    echo "[Mode] Daemon: Starting configuration..."

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

    CRON_SCHEDULE=${cron:-"0 3 * * *"}
    echo "${CRON_SCHEDULE} /docker/shell/renew.sh > /dev/stdout 2>&1" > /var/spool/cron/crontabs/root
	echo "[Mode] Daemon: Cron configured with schedule $CRON_SCHEDULE"

else
    echo "[Mode] CLI: Running one-time command..."
    /usr/bin/lego --path /.lego $LEGO_ARGS

	if [ $? -eq 0 ] && echo "$LEGO_ARGS" | grep -q "\brun\b"; then
		echo "[Post-Process] Command successful. Saving to tasks.list..."
		CURRENT_DOMAIN=$(extract_domain "$ALL_ARGS")
		CERT_FILE=$(get_cert_path "$CURRENT_DOMAIN")

		if [ -n "$CURRENT_DOMAIN" ] && [ -f "$CERT_FILE" ]; then
			TASK_DIR="/.lego/tasks.d"
			mkdir -p "$TASK_DIR"
			CONF_FILE="$TASK_DIR/${CURRENT_DOMAIN}.conf"

			echo "[Post-Process] Successfully serialized $CURRENT_DOMAIN. Saving to tasks.d..."

			{
                echo "# Configuration for $CURRENT_DOMAIN"
                echo "# Generated at $(date)"
                
				echo "export $CAPTURED_ENVS"
                
                RENEW_ARGS=$(echo "$LEGO_ARGS" | sed 's/\brun\b/renew/')
                echo "LEGO_ARGS=\"$RENEW_ARGS\""
            } > "$CONF_FILE"
			chmod 600 "$CONF_FILE"
            echo "[Post-Process] Configuration saved: $CONF_FILE"
        else
            echo "[Notice] Certificate for $CURRENT_DOMAIN not found. Skipping serialization."
        fi
	fi

    echo "Command finished. Terminating container..."
    ( sleep 1; s6-svscanctl -t /run/service ) &
fi
