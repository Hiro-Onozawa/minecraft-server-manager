#!/bin/bash

source /home/ubuntu/workspace/user_util/bash/server_setup_env.sh
mkdir -p "$(dirname "${SERVER_VERSION_PATH}")"
echo $2 > "${SERVER_VERSION_PATH}"
mkdir -p "$(dirname "${SERVER_NAME_PATH}")"
echo $3 > "${SERVER_NAME_PATH}"

/home/ubuntu/workspace/user_util/bash/notification_initialize.sh

/home/ubuntu/workspace/user_util/bash/instance_on_start.sh

/home/ubuntu/workspace/user_util/bash/http_initialize.sh

/home/ubuntu/workspace/user_util/bash/mcrcon_initialize.sh
/home/ubuntu/workspace/user_util/bash/server_initialize.sh "$1" "$4" "$5" "$6"

if [ "$1" = "user" ]; then
  sudo systemctl start minecraft-spigot-server.service auto-shutdown.service
fi
