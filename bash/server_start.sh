#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

TOTAL_MEMORY=$(free --mega | grep 'Mem:' | awk '{print $2}')
HEAP_MIN_SIZE=$(( TOTAL_MEMORY / 100 * 40 ))
HEAP_MAX_SIZE=$(( TOTAL_MEMORY / 100 * 65 ))

cd "${SERVER_HOME}"
java -Xms${HEAP_MIN_SIZE}M -Xmx${HEAP_MAX_SIZE}M -server -jar "${SERVER_JAR_PATH}" nogui --noconsole
