#!/bin/bash -eu

PATH=$PATH:$(dirname "$(dirname "$0")")

source server/setup_env.sh

NOTICE_SERVER_NAME="${SERVER_NAME} (${SERVER_VERSION})"

echo -n "[${SERVER_ADDRESS}] Instance of ${NOTICE_SERVER_NAME} will be stop" | send_message/main.sh admin
