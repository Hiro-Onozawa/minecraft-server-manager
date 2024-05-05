#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

NOTICE_SERVER_NAME=$(sed -E -n 's/^motd=(.+)$/\1/p' "${SERVER_HOME}/server.properties")

(
  echo -n "${NOTICE_SERVER_NAME}のバックアップを開始します。" | send_message.sh admin
  server_backup.sh
  ls "${BACKUP_HOME}"
  echo -n "${NOTICE_SERVER_NAME}のバックアップが完了しました。" | send_message.sh admin
) &

echo -n "$!"
