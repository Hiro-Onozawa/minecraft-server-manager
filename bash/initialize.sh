#!/bin/bash

cd "$(dirname "$0")" || exit 1
PATH=$PATH:$(pwd)

find . -type f -name '*.sh' -exec chmod +x \{\} \;

source server/setup_env.sh

INSTANCE_PARAMETERS_JSON_PATH="/home/ubuntu/workspace/user_util/settings/instance_parameters.json"

ARG_VALUE="$(jq -r '.arg_value' "${INSTANCE_PARAMETERS_JSON_PATH}")"
VERSION="$(jq -r '.version' "${INSTANCE_PARAMETERS_JSON_PATH}")"
SERVER_NAME="$(jq -r '.server_name' "${INSTANCE_PARAMETERS_JSON_PATH}")"
BUCKET_NAME="$(jq -r '.bucket_name' "${INSTANCE_PARAMETERS_JSON_PATH}")"
DIFFICULTY="$(jq -r '.difficulty' "${INSTANCE_PARAMETERS_JSON_PATH}")"
GAMEMODE="$(jq -r '.gamemode' "${INSTANCE_PARAMETERS_JSON_PATH}")"
WORLD_SIZE="$(jq -r 'if .world_size == null then "" else .world_size end' "${INSTANCE_PARAMETERS_JSON_PATH}")"
IS_HARDCORE="$(jq -r 'if .hardcore == null then "" else .hardcore end' "${INSTANCE_PARAMETERS_JSON_PATH}")"
MAX_USER="$(jq -r '.max_user' "${INSTANCE_PARAMETERS_JSON_PATH}")"
OPEN_JDK_VER="$(jq -r '.open_jdk_ver' "${INSTANCE_PARAMETERS_JSON_PATH}")"
UPDATE_PLUGINS="$(jq -r '.update_plugins' "${INSTANCE_PARAMETERS_JSON_PATH}")"
DISCORD_WEBHOOK_USER="$(jq -r '.discord_webhook_user' "${INSTANCE_PARAMETERS_JSON_PATH}")"
DISCORD_WEBHOOK_ADMIN="$(jq -r '.discord_webhook_admin' "${INSTANCE_PARAMETERS_JSON_PATH}")"
CONSOLE_LAMBDA_URL="$(jq -r '.console_lambda_url' "${INSTANCE_PARAMETERS_JSON_PATH}")"

mkdir -p "$(dirname "${CONSOLE_LAMBDA_URL_PATH}")"
echo "${CONSOLE_LAMBDA_URL}" > "${CONSOLE_LAMBDA_URL_PATH}"
mkdir -p "$(dirname "${SERVER_VERSION_PATH}")"
echo "${VERSION}" > "${SERVER_VERSION_PATH}"
mkdir -p "$(dirname "${SERVER_NAME_PATH}")"
echo "${SERVER_NAME}" > "${SERVER_NAME_PATH}"
mkdir -p "$(dirname "${BACKUP_BUCKET_NAME_PATH}")"
echo "${BUCKET_NAME}" > "${BACKUP_BUCKET_NAME_PATH}"

/home/ubuntu/workspace/user_util/bash/notification/initialize.sh "${DISCORD_WEBHOOK_USER}" "${DISCORD_WEBHOOK_ADMIN}"

/home/ubuntu/workspace/user_util/bash/http/initialize.sh

/home/ubuntu/workspace/user_util/bash/mcrcon/initialize.sh
/home/ubuntu/workspace/user_util/bash/server/initialize.sh "${ARG_VALUE}" "${MAX_USER}" "${DIFFICULTY}" "${GAMEMODE}" "${WORLD_SIZE}" "${IS_HARDCORE}" "${OPEN_JDK_VER}" "${UPDATE_PLUGINS}"

if [ "${ARG_VALUE}" = "user" ]; then
  sudo systemctl start minecraft-spigot-server.service auto-shutdown.service
fi
