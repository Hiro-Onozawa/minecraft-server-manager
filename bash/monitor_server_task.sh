#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

set +e

while true
do
  monitor_server_core.sh
  echo "$? : $(TZ=JST-9 date) - $(find "${SERVER_HOME}" -name "server_*" -printf "%f,")"
  sleep 20
done
