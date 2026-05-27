#!/command/with-contenv sh
. /docker/shell/common.sh
set -e

L_ARGS=""
L_ENVS=""
parse_args L_ARGS _dummy L_ENVS "$@"
[ -n "$L_ENVS" ] && export $L_ENVS

MODE_ARG=$(echo "$L_ARGS" | awk '{print $1}')

if [ "$MODE_ARG" = "daemon" ]; then
    CRON_SCHEDULE=${cron:-"0 3 * * *"}
    echo "${CRON_SCHEDULE} /docker/shell/renew.sh > /dev/stdout 2>&1" > /var/spool/cron/crontabs/root
    echo "[Daemon] Cron configured with schedule $CRON_SCHEDULE"
    echo "[Daemon] Starting crond..."
    exec crond -f -l 2
fi

echo "[CLI] Running: lego --path /.lego $L_ARGS"
/usr/bin/lego --path /.lego $L_ARGS
RET=$?

if [ $RET -eq 0 ] && echo "$L_ARGS" | grep -q "\brun\b"; then
    CURRENT_DOMAIN=$(extract_domain "$L_ARGS")
    CERT_FILE=$(get_cert_path "$CURRENT_DOMAIN")

    if [ -n "$CURRENT_DOMAIN" ] && [ -f "$CERT_FILE" ]; then
        TASK_DIR="/.lego/tasks.d"
        mkdir -p "$TASK_DIR"
        CONF_FILE="$TASK_DIR/${CURRENT_DOMAIN}.conf"

        echo "[Post-Process] Successfully obtained cert for $CURRENT_DOMAIN. Saving to tasks.d..."
        {
            echo "# Configuration for $CURRENT_DOMAIN"
            echo "# Generated at $(date)"
            echo "export $L_ENVS"
            RENEW_ARGS="$L_ARGS"
            echo "LEGO_ARGS=\"$RENEW_ARGS\""
        } > "$CONF_FILE"
        chmod 600 "$CONF_FILE"
        echo "[Post-Process] Configuration saved: $CONF_FILE"
    else
        echo "[Notice] Certificate for $CURRENT_DOMAIN not found. Skipping serialization."
    fi
fi

echo "Command finished."
exit $RET
