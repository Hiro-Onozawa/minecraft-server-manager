#!/bin/bash -eu

RECIEVER_NAME="$(echo "$1" | jq -r '.name')"
ENDPOINT_URL="$(echo "$1" | jq -r '.endpoint')"
TOKEN="$(echo "$1" | jq -r '.token')"
RESPONSE="$( \
  curl \
    -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -F "message=<-" \
    -s \
    "${ENDPOINT_URL}" \
    | jq '.' \
  )"

if [ "$(echo "${RESPONSE}" | jq '.status')" != "200" ]; then
  echo "send to line error; ${RECIEVER_NAME}; $(echo "${RESPONSE}" | jq '.message')" 1>&2
  exit 1
fi

echo "${RESPONSE}" | jq -c --arg name "${RECIEVER_NAME}" '{$name : .message}'
