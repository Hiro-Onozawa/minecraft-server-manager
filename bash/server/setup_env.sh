#!/bin/bash -eu

VERSION_CODE_PATH=/home/ubuntu/workspace/user_util/settings/version.txt
SERVER_NAME_PATH=/home/ubuntu/workspace/user_util/settings/server_name.txt
BUCKET_NAME_PATH=/home/ubuntu/workspace/user_util/settings/bucket_name.txt
SERVER_SUPPORT_VERSIONS_PATH=/home/ubuntu/workspace/user_util/settings/server_support_versions.json
SERVER_VERSION=$(if [ -f "${VERSION_CODE_PATH}" ]; then cat "${VERSION_CODE_PATH}"; else echo "undefined"; fi)
SERVER_NAME=$(if [ -f "${SERVER_NAME_PATH}" ]; then cat "${SERVER_NAME_PATH}"; else echo "undefined"; fi)
BUCKET_NAME=$(if [ -f "${BUCKET_NAME_PATH}" ]; then cat "${BUCKET_NAME_PATH}"; else echo "undefined"; fi)
MC_HOME=/home/ubuntu/workspace/Spigot/Server/${SERVER_VERSION}
BACKUP_HOME=/home/ubuntu/workspace/Spigot/Backup
BUILD_HOME=/home/ubuntu/workspace/Spigot/Build
MCRCON_BIN=/home/ubuntu/workspace/mcrcon

export PATH=$PATH:$MCRCON_BIN
export SERVER_VERSION_PATH=${VERSION_CODE_PATH}
export SERVER_VERSION=${SERVER_VERSION}
export SERVER_NAME_PATH=${SERVER_NAME_PATH}
export SERVER_NAME=${SERVER_NAME}
export BACKUP_BUCKET_NAME_PATH=${BUCKET_NAME_PATH}
export BACKUP_BUCKET_NAME=${BUCKET_NAME_PATH}
export SERVER_JAR_NAME=paper-${SERVER_VERSION}.jar
export SERVER_HOME=${MC_HOME}
export SERVER_JAR_PATH=${MC_HOME}/${SERVER_JAR_NAME}
export SERVER_LAST_STATE_FILE=${MC_HOME}/server_state
export SERVER_ADDRESS=$(ec2metadata --public-ipv4)
export SERVER_SUPPORT_VERSIONS_PATH=${SERVER_SUPPORT_VERSIONS_PATH}
export BACKUP_HOME=${BACKUP_HOME}
export BUILD_HOME=${BUILD_HOME}
export MCRCON_HOST=localhost
export MCRCON_PORT=$(if [ -f "${MC_HOME}/server.properties" ]; then sed -E -n 's/^rcon.port=(.+)$/\1/p' "${MC_HOME}/server.properties"; fi)
export MCRCON_PASS=$(if [ -f "${MC_HOME}/rcon.pass" ]; then cat "${MC_HOME}/rcon.pass"; fi)
export BUCKET_NAME=${BUCKET_NAME}
