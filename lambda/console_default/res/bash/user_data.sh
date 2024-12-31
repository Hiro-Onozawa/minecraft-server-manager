#!/bin/bash -eu
apt update
apt install -y unzip
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install
rm -rf ./awscliv2.zip ./aws
sudo -u ubuntu mkdir -p /home/ubuntu/workspace
cd /home/ubuntu/workspace
sudo -u ubuntu git clone https://github.com/Hiro-Onozawa/minecraft-server-manager.git user_util
sudo -u ubuntu bash /home/ubuntu/workspace/user_util/bash/initialize.sh %%ON_MOUNT_ARG%%