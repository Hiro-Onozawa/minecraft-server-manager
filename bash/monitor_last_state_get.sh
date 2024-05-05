#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

if [ -f "${SERVER_LAST_STATE_FILE}" ]; then
  export SERVER_LAST_STATE="$(jq -r '.state' "${SERVER_LAST_STATE_FILE}")"
  export SERVER_LAST_STATE_UPDATE="$(jq -r '.update' "${SERVER_LAST_STATE_FILE}")"
else
  export SERVER_LAST_STATE="stop"
  export SERVER_LAST_STATE_UPDATE="$(TZ=JST-9 date +%s)"
fi
