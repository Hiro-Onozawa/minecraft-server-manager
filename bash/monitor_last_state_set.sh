#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

echo -n "{\"state\":\"$1\", \"update\":\"$(TZ=JST-9 date +%s)\"}" > "${SERVER_LAST_STATE_FILE}"
