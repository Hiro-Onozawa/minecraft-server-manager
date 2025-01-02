#!/bin/bash

PATH=$PATH:$(dirname "$(dirname "$0")")

source server/setup_env.sh

mkdir -p ${SERVER_HOME}
cd ${SERVER_HOME}

ARG_OWNER_NAME="$1"
ARG_MAX_PLAYERS="$2"
ARG_JDK_VERSION="$3"
ARG_UPDATE_PLUGINS="$4"

if [ "${ARG_OWNER_NAME}" = "user" ]; then
  LATEST_ARCHIVE_KEY=$(aws s3api list-objects-v2 --bucket "${BUCKET_NAME}" --prefix "${SERVER_NAME}" | jq -r '.Contents | sort_by(.LastModified) | reverse | .[] | select(.StorageClass == "STANDARD") | .Key' | head -n 1)
  LATEST_ARCHIVE_NAME=${LATEST_ARCHIVE_KEY##${SERVER_NAME}/}
  aws s3 cp "s3://${BUCKET_NAME}/${SERVER_NAME}/${LATEST_ARCHIVE_NAME}" ./
  tar -zxf ./"${LATEST_ARCHIVE_NAME}"
  rm ./"${LATEST_ARCHIVE_NAME}"
fi

wget -q -O paper_${SERVER_VERSION}.json https://api.papermc.io/v2/projects/paper/versions/${SERVER_VERSION}/builds
jq '[.builds[]] | sort_by(.build) | reverse | .[0]' paper_${SERVER_VERSION}.json > paper_${SERVER_VERSION}_latest.json
PAPER_BUILD_NUMBER=$(jq -r '.build' paper_${SERVER_VERSION}_latest.json)
PAPER_APP_NAME=$(jq -r '.downloads.application.name' paper_${SERVER_VERSION}_latest.json)
wget -q -O paper-${SERVER_VERSION}.jar https://api.papermc.io/v2/projects/paper/versions/${SERVER_VERSION}/builds/${PAPER_BUILD_NUMBER}/downloads/${PAPER_APP_NAME}
rm paper_${SERVER_VERSION}.json paper_${SERVER_VERSION}_latest.json

head -c 64 /dev/random | base64 | tr -d '/+' | head -c 24 > rcon.pass
sed -e 's/rcon.password=/rcon.password='"$(cat rcon.pass)"'/' -e 's/motd=/motd='"${ARG_OWNER_NAME} (${SERVER_VERSION})"'/' -e 's/max-players=/max-players='"${ARG_MAX_PLAYERS}"'/' /home/ubuntu/workspace/user_util/template/server.properties.template > server.properties
echo "eula=true" > eula.txt

mkdir -p plugins
pushd plugins
  if [ "${ARG_UPDATE_PLUGINS}" = "true" ]; then
    # wget -q -O multiverse-core.jar https://dev.bukkit.org/projects/multiverse-core/files/latest
    # wget -q -O multiverse-portals.jar https://dev.bukkit.org/projects/multiverse-portals/files/latest
    wget -q -O LuckPerms-Bukkit.jar $(wget -q -O - https://metadata.luckperms.net/data/all | jq -r '.downloads.bukkit')
    wget -q -O geyser.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
    wget -q -O floodgate.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
  fi
popd

sudo apt update
sudo apt install -y "${ARG_JDK_VERSION}"
sudo cp /home/ubuntu/workspace/user_util/systemd/minecraft-spigot-server.service /etc/systemd/system/
sudo cp /home/ubuntu/workspace/user_util/systemd/auto-shutdown.service /etc/systemd/system/
sudo systemctl daemon-reload
