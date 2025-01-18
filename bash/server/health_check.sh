#!/bin/bash

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

if systemctl is-active --quiet minecraft-spigot-server.service; then
  RESP=$(mcrcon -c 'list' 2>&1 \
    | sed -E \
      -e 's/There are ([0-9]+) of a max of ([0-9]+) players online: (.*)$/{"status":"online","active":\1,"max":\2,"users":"\3"}/' \
      -e 's/Connection failed.//' \
      -e 's/Error ([0-9]+):? ?(.*?)/{"status":"offline","error":{"number":\1,"message":"\2"}}/' \
      -e 't; q100')
  MCRON_EXIT_CODE=$?
  if [ "${MCRON_EXIT_CODE}" -eq 0 ]; then
    if [ "$(echo "${RESP}" | jq -r '.status')" = "online" ]; then
      # バージョン情報のキャッシュが無ければ作成する
      if [ ! -s "${SERVER_SUPPORT_VERSIONS_PATH}" ]; then
        mcrcon -c 'geyser version' \
          | grep -o -E -e 'Java: ([0-9\.]+), Bedrock: ([0-9\.\/ \-]+)' \
          | sed -n -E -e 's/Java: (.+), Bedrock: (.+)/{"support":{"java":"\1","bedrock":"\2"}}/p' \
          > "${SERVER_SUPPORT_VERSIONS_PATH}"
      fi
      {
        echo "${RESP}";
        cat "${SERVER_SUPPORT_VERSIONS_PATH}";
      } | jq -c -s '.[0] * (.[1] // {})'
      # 期待通りバージョン情報がキャッシュできなかったら次回取り直すので削除しておく
      if [ ! -s "${SERVER_SUPPORT_VERSIONS_PATH}" ]; then
        rm -f "${SERVER_SUPPORT_VERSIONS_PATH}"
      fi
    else
      echo "${RESP}"
    fi
  else
    echo '{"status":"offline","error":{"number":null,"message":"undefined state"}}'
  fi
else
  echo '{"status":"stop"}'
fi
