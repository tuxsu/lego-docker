#!/bin/sh -eu
. /docker/shell/common.sh

LEGO_ARGS=""
CAPTURED_ENVS_NAME=""
CAPTURED_ENVS=""

parse_args LEGO_ARGS CAPTURED_ENVS_NAME CAPTURED_ENVS "$@"

[ -n "$CAPTURED_ENVS" ] && export $CAPTURED_ENVS

export LEGO_ARGS="$LEGO_ARGS"
export CAPTURED_ENVS_NAME="$CAPTURED_ENVS_NAME"
export CAPTURED_ENVS="$CAPTURED_ENVS"
export ALL_ARGS="$@"

echo "[Entrypoint] Parse env name args: $CAPTURED_ENVS_NAME"
echo "[Entrypoint] Parse env args: $CAPTURED_ENVS"
echo "[Entrypoint] Parse lego args: $LEGO_ARGS"
echo "[Entrypoint] All args: $@"

exec /init
