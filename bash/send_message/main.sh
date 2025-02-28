#!/bin/bash -eu

unset tmpfile

atexit() {
  [[ -n ${tmpfile-} ]] && rm -f "$tmpfile"
}

trap atexit EXIT
trap 'rc=$?; trap - EXIT; atexit; exit $?' INT PIPE TERM

tmpfile=$(mktemp "/tmp/${0##*/}.tmp.XXXXXX")

cd "$(dirname "$(dirname "$0")")"
cat - > "${tmpfile}"

TARGET="EVERYONE"
if [ "$#" -ge 1 ]; then
  if [ "$1" = "admin" ]; then
    TARGET="ONLY_ADMIN"
  fi
fi

if [ "${TARGET}" != "ONLY_ADMIN" ]; then
jq -r -c \
  --arg tmpfile "${tmpfile}" \
  '.[] | "cat \"" + $tmpfile + "\" | ./send_message/send_to_" + .type + ".sh '"'"'" + (. | tostring) + "'"'"'"' \
  ../settings/notification.cfg \
  | bash
fi

jq -r -c \
  --arg tmpfile "${tmpfile}" \
  '.[] | "cat \"" + $tmpfile + "\" | ./send_message/send_to_" + .type + ".sh '"'"'" + (. | tostring) + "'"'"'"' \
  ../settings/notification_admin.cfg \
  | bash
