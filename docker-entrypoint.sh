#!/bin/sh -eu

ENV_DIR=/run/s6/container_environment
mkdir -p "$ENV_DIR"

is_valid_var() {
    case "$1" in
        [A-Za-z_]*)
            case "$1" in
                *[!A-Za-z0-9_]*)
                    return 1 ;;
                *)
                    return 0 ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}

LEGO_ARGS=""

for arg in "$@"; do
    case "$arg" in
        -*) 
            LEGO_ARGS="$LEGO_ARGS $arg"
            ;;
        *=*)
            key=${arg%%=*}
            val=${arg#*=}
            if is_valid_var "$key"; then

                printf '%s' "$val" > "$ENV_DIR/$key"

                export "$key=$val"
            else

                LEGO_ARGS="$LEGO_ARGS $arg"
            fi
            ;;
        *)
            LEGO_ARGS="$LEGO_ARGS $arg"
            ;;
    esac
done

echo "$LEGO_ARGS" > /tmp/cmd_args
echo "[Entrypoint] Saved args: $LEGO_ARGS"
exec /init
