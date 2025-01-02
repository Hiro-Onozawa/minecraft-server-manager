#!/bin/bash -eu

cd $(dirname "$(dirname "$0")")
PATH=$PATH:$(pwd)

source server/setup_env.sh

SUFFIX="$(TZ=JST-9 date +%Y%m%d-%H%M)"
BACKUP_NAME="main_backup_${SERVER_VERSION}_${SUFFIX}.tar"

mkdir -p "${BACKUP_HOME}"
pushd "${SERVER_HOME}"
  tar -cf "${BACKUP_HOME}/${BACKUP_NAME}" ops.json world{,_nether,_the_end}
  if [ -d "plugins" ]; then
    if test -n "$(find "plugins" -maxdepth 1 -name '*.jar' -print -quit)"; then
      tar -rf "${BACKUP_HOME}/${BACKUP_NAME}" plugins/*.jar
    fi
    for plugin_name in Multiverse-Core Multiverse-Portals LuckPerms Geyser-Spigot floodgate; do
      if [ -d "plugins/${plugin_name}" ]; then
        if test -n "$(find "plugins/${plugin_name}" -maxdepth 1 -name '*.yml' -print -quit)"; then
          tar -rf "${BACKUP_HOME}/${BACKUP_NAME}" "plugins/${plugin_name}/"*.yml
        fi
      fi
    done
  fi
popd
gzip "${BACKUP_HOME}/${BACKUP_NAME}"
aws s3 cp "${BACKUP_HOME}/${BACKUP_NAME}.gz" "s3://${BUCKET_NAME}/${SERVER_NAME}/${BACKUP_NAME}"
