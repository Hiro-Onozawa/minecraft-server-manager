#!/bin/bash -eu

PATH=$PATH:$(dirname "$(dirname "$0")")

source server/setup_env.sh

NOTICE_SERVER_NAME="${SERVER_NAME} (${SERVER_VERSION})"

echo -n "[${SERVER_ADDRESS}] Instance of ${NOTICE_SERVER_NAME} is running" | send_message.sh admin
