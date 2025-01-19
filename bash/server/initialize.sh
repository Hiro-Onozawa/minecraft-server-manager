#!/bin/bash

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

mkdir -p "${SERVER_HOME}"
cd "${SERVER_HOME}" || exit 1

ARG_OWNER_NAME="$1"
ARG_MAX_PLAYERS="$2"
ARG_DIFFICULTY="$3"
ARG_GAMEMODE="$4"
ARG_WORLD_SIZE="$5"
ARG_IS_HARDCORE="$6"
ARG_JDK_VERSION="$7"
ARG_UPDATE_PLUGINS="$8"

if [ "${ARG_OWNER_NAME}" = "user" ]; then
  LATEST_ARCHIVE_KEY="$(aws s3api list-objects-v2 --bucket "${BUCKET_NAME}" --prefix "${SERVER_NAME}" | jq -r '[ (.Contents // []) | sort_by(.LastModified) | reverse | .[] | select(.StorageClass == "STANDARD") | .Key ] | .[0] // ""')"
  LATEST_ARCHIVE_NAME="${LATEST_ARCHIVE_KEY##"${SERVER_NAME}/"}"
  if [ -n "${LATEST_ARCHIVE_KEY}" ]; then
    aws s3 cp "s3://${BUCKET_NAME}/${SERVER_NAME}/${LATEST_ARCHIVE_NAME}" ./
    tar -zxf ./"${LATEST_ARCHIVE_NAME}"
    rm ./"${LATEST_ARCHIVE_NAME}"
  fi
fi

wget -q -O "paper_${SERVER_VERSION}.json" "https://api.papermc.io/v2/projects/paper/versions/${SERVER_VERSION}/builds"
jq '[.builds[]] | sort_by(.build) | reverse | .[0]' "paper_${SERVER_VERSION}.json" > "paper_${SERVER_VERSION}_latest.json"
PAPER_BUILD_NUMBER=$(jq -r '.build' "paper_${SERVER_VERSION}_latest.json")
PAPER_APP_NAME=$(jq -r '.downloads.application.name' "paper_${SERVER_VERSION}_latest.json")
wget -q -O "paper-${SERVER_VERSION}.jar" "https://api.papermc.io/v2/projects/paper/versions/${SERVER_VERSION}/builds/${PAPER_BUILD_NUMBER}/downloads/${PAPER_APP_NAME}"
rm "paper_${SERVER_VERSION}.json" "paper_${SERVER_VERSION}_latest.json"

head -c 64 /dev/random | base64 | tr -d '/+' | head -c 24 > rcon.pass
if [ ! -f "server.properties" ]; then
  cp /home/ubuntu/workspace/user_util/template/server.properties.template server.properties
fi
cp server.properties server.properties.old
awk -F "=" \
  -v rcon_password="$(cat rcon.pass)" \
  -v motd="${SERVER_NAME} (${SERVER_VERSION})" \
  -v max_players="${ARG_MAX_PLAYERS}" \
  -v gamemode="${ARG_GAMEMODE}" \
  -v difficulty="${ARG_DIFFICULTY}" \
  -v world_size="${ARG_WORLD_SIZE}" \
  -v hardcore="${ARG_IS_HARDCORE}" \
  '
  function get_value(v1, v2, v3) {
    return v1 == "" ? (v2 == "" ? v3 : v2) : v1
  }
  NF>=2{ key=$1; value=substr($0, length($1)+2); dic[key]=value }
  END{
    dic["rcon.password"]  = rcon_password
    dic["motd"]           = motd
    dic["max-players"]    = max_players
    dic["gamemode"]       = gamemode
    dic["difficulty"]     = difficulty
    dic["max-world-size"] = get_value(world_size, dic["max-world-size"], 8192)
    dic["hardcore"]       = get_value(hardcore, dic["hardcore"], false)

    for (key in dic) { print key "=" dic[key] }
  }
  ' server.properties.old > server.properties
echo "eula=true" > eula.txt

mkdir -p plugins
pushd plugins || exit 1
  if [ "${ARG_UPDATE_PLUGINS}" = "true" ]; then
    # wget -q -O multiverse-core.jar https://dev.bukkit.org/projects/multiverse-core/files/latest
    # wget -q -O multiverse-portals.jar https://dev.bukkit.org/projects/multiverse-portals/files/latest
    wget -q -O LuckPerms-Bukkit.jar "$(wget -q -O - https://metadata.luckperms.net/data/all | jq -r '.downloads.bukkit')"
    wget -q -O geyser.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
    wget -q -O floodgate.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
  fi
popd || exit 1

sudo apt update
sudo apt install -y "${ARG_JDK_VERSION}"
sudo cp /home/ubuntu/workspace/user_util/systemd/minecraft-spigot-server.service /etc/systemd/system/
sudo cp /home/ubuntu/workspace/user_util/systemd/auto-shutdown.service /etc/systemd/system/
sudo systemctl daemon-reload
