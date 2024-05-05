#!/bin/bash -eu

RECIEVER_NAME="$(echo "$1" | jq -r '.name')"
ENDPOINT_URL="$(echo "$1" | jq -r '.endpoint')"
RESPONSE="$( \
  cat - \
  | jq -R -s -c '{"content":.}' \
  | curl \
    -X POST \
    -H "Content-Type: application/json" \
    -d "@-" \
    -s \
    "${ENDPOINT_URL}" \
  | jq '.' \
)"

if [ -n "${RESPONSE}" ]; then
  echo "send to discord error; ${RECIEVER_NAME}; $(echo "${RESPONSE}" | jq '.message')" 1>&2
  exit 1
fi

echo "ok" | jq -R -c --arg name "${RECIEVER_NAME}" '{$name : .}'
