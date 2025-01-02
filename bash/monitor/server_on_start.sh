#!/bin/bash -eu

PATH=$PATH:$(dirname "$(dirname "$0")")

source server/setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

(sleep 30; echo -n "${NOTICE_SERVER_NAME} を起動しました。"$'\n'"接続先は \`${SERVER_ADDRESS}:26291\` です。" | send_message.sh) &
