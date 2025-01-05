#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

set +e

while true
do
  monitor/server_core.sh
  LAST_STATUS_CODE=$?
  source monitor/last_state_get.sh
  echo "${LAST_STATUS_CODE} : $(TZ=JST-9 date) - $(find "${SERVER_HOME}" -name "server_*" -printf "%f,") - ${SERVER_LAST_STATE}"
  sleep 20
done
