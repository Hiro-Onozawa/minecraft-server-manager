#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

echo -n "{\"state\":\"$1\", \"update\":\"$(TZ=JST-9 date +%s)\"}" > "${SERVER_LAST_STATE_FILE}"
