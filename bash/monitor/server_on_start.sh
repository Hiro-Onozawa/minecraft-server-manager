#!/bin/bash -eu

cd $(dirname "$(dirname "$0")")
PATH=$PATH:$(pwd)

source server/setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

(sleep 30; echo -n "${NOTICE_SERVER_NAME} を起動しました。"$'\n'"Java版の接続先は \`${SERVER_ADDRESS}:26291\` です。\n詳細は[サーバー管理ページ](${CONSOLE_LAMBDA_URL})を確認してください。" | send_message/main.sh) &
