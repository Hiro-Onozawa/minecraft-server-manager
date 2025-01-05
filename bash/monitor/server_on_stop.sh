#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

server/stop.sh
echo -n "${NOTICE_SERVER_NAME} を終了します。" | send_message/main.sh
