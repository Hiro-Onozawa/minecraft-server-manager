#!/bin/bash

mkdir -p /home/ubuntu/workspace/user_util/settings
cat << EOS > /home/ubuntu/workspace/user_util/settings/notification.cfg
[
    {
        "type": "discord",
        "name": "Discord_User",
        "endpoint": "$1"
    }
]
EOS
cat << EOS > /home/ubuntu/workspace/user_util/settings/notification_admin.cfg
[
    {
        "type": "discord",
        "name": "Discord_Admin",
        "endpoint": "$2"
    }
]
EOS

sudo cp /home/ubuntu/workspace/user_util/systemd/notice-instance-start.service /etc/systemd/system/
sudo cp /home/ubuntu/workspace/user_util/systemd/notice-instance-stop.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start notice-instance-start.service
sudo systemctl enable notice-instance-stop.service
