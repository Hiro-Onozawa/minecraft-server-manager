#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh
source monitor/last_state_get.sh

# State : Start, Terminated, Left, Joined, Stop, Backup

NOW_TIME="$(TZ=JST-9 date +%s)"
SERVER_FIRST_JOINED_PATH="${SERVER_HOME}/server_joined"
SERVER_BACKUP_PID_PATH="${SERVER_HOME}/server_backup"
SERVER_HEALTH="$(server/health_check.sh)"
SERVER_STATUS="$(echo "${SERVER_HEALTH}" | jq -r '.status')"
SERVER_ACTIVE_USER="$(echo "${SERVER_HEALTH}" | jq -r '.active')"
if [ "${SERVER_STATUS}" = "online" ]; then
  # State : Start, Left, Joined, Stop
  if [ "${SERVER_ACTIVE_USER}" -gt 0 ]; then
    # Joined
    if [ "${SERVER_LAST_STATE}" != "Joined" ]; then
      monitor/server_on_joined.sh
      monitor/last_state_set.sh "Joined"
      if [ ! -f "${SERVER_FIRST_JOINED_PATH}" ]; then
        echo "${NOW_TIME}" > "${SERVER_FIRST_JOINED_PATH}"
      fi
    else
      exit 0
    fi
  else
    # Start, Left, Stop
    if [ "${SERVER_LAST_STATE}" = "Left" ]; then
      if [ "$(( NOW_TIME - SERVER_LAST_STATE_UPDATE ))" -gt 600 ]; then
        monitor/server_on_stop.sh
        monitor/last_state_set.sh "Stop"
      else
        exit 0
      fi
    elif [ "${SERVER_LAST_STATE}" = "Start" ]; then
      monitor/last_state_set.sh "Left"
      exit 0
    elif [ "${SERVER_LAST_STATE}" = "Stop" ]; then
      monitor/server_on_start.sh
      monitor/last_state_set.sh "Start"
      exit 0
    else
      monitor/server_on_left.sh
      monitor/last_state_set.sh "Left"
    fi
  fi
elif [ "${SERVER_STATUS}" = "offline" ]; then
  exit 0
elif [ "${SERVER_STATUS}" = "stop" ]; then
  # Terminated, Backup
  if [ "${SERVER_LAST_STATE}" = "Backup" ]; then
    if ps -p "$(< "${SERVER_BACKUP_PID_PATH}")" -o cmd --no-headers >/dev/null; then
      exit 0
    else
      true # goto terminated
    fi
  elif [ "${SERVER_LAST_STATE}" = "Terminated" ]; then
    if [ "$(( NOW_TIME - SERVER_LAST_STATE_UPDATE ))" -gt 300 ]; then
      (sleep 5 && sudo shutdown now) &
    fi
    exit 0
  else
    if [ -f "${SERVER_FIRST_JOINED_PATH}" ]; then
      monitor/server_on_backup.sh > "${SERVER_BACKUP_PID_PATH}"
      monitor/last_state_set.sh "Backup"
      exit 0
    else
      true # goto terminated
    fi
  fi
  # terminated
  rm -f "${SERVER_FIRST_JOINED_PATH}" "${SERVER_BACKUP_PID_PATH}"
  monitor/server_on_terminated.sh
  monitor/last_state_set.sh "Terminated"
else
  exit 1
fi
