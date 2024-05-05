#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

server_stop.sh
echo -n "${NOTICE_SERVER_NAME} を終了します。" | send_message.sh
