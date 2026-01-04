#!/command/with-contenv sh
set -e

CMD_ARGS=$(cat /tmp/cmd_args | xargs)

MODE_ARG=$(echo $CMD_ARGS | awk '{print $1}')

if [ "$MODE_ARG" = "daemon" ]; then
    echo "[Mode] Daemon: Configuring cron..."
    CRON_SCHEDULE=${cron:-"0 3 * * *"}
    echo "${CRON_SCHEDULE} /usr/bin/lego --path /.lego renew > /dev/stdout 2>&1" > /var/spool/cron/crontabs/root
else
    echo "[Mode] CLI: Running one-time command..."
    /usr/bin/lego --path /.lego $CMD_ARGS
    echo "Command finished. Terminating container..."
    ( sleep 1; s6-svscanctl -t /run/service ) &
fi
