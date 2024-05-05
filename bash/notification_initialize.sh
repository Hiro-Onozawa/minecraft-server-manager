#!/bin/bash

mkdir -p /home/ubuntu/workspace/user_util/settings
# TODO: どこかから通知先情報を取得して書き込む
echo "[]" > /home/ubuntu/workspace/user_util/settings/notification.cfg
echo "[]" > /home/ubuntu/workspace/user_util/settings/notification_admin.cfg

sudo cp /home/ubuntu/workspace/user_util/systemd/notice-instance-stop.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable notice-instance-stop.service
