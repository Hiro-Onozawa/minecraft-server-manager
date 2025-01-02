#!/bin/bash -eu

cd $(dirname "$(dirname "$0")")
PATH=$PATH:$(pwd)

source server/setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

(
  echo -n "${NOTICE_SERVER_NAME}のバックアップを開始します。" | send_message/main.sh admin
  server/backup.sh
  ls "${BACKUP_HOME}"
  echo -n "${NOTICE_SERVER_NAME}のバックアップが完了しました。" | send_message/main.sh admin
) &

echo -n "$!"
