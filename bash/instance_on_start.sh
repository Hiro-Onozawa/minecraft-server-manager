#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

NOTICE_SERVER_NAME="${SERVER_NAME} (${SERVER_VERSION})"

echo -n "[${SERVER_ADDRESS}] Instance of ${NOTICE_SERVER_NAME} is running" | send_message.sh admin
