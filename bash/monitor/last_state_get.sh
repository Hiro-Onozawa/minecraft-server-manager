#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

SERVER_LAST_STATE="Stop"
SERVER_LAST_STATE_UPDATE="$(TZ=JST-9 date +%s)"

if [ -f "${SERVER_LAST_STATE_FILE}" ]; then
  SERVER_LAST_STATE="$(jq -r '.state' "${SERVER_LAST_STATE_FILE}")"
  SERVER_LAST_STATE_UPDATE="$(jq -r '.update' "${SERVER_LAST_STATE_FILE}")"
fi

export SERVER_LAST_STATE=${SERVER_LAST_STATE}
export SERVER_LAST_STATE_UPDATE=${SERVER_LAST_STATE_UPDATE}
