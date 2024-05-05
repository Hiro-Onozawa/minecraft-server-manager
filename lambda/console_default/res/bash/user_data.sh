#!/bin/bash -eu
apt update
apt install -y unzip
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install
rm -rf ./awscliv2.zip ./aws
sudo -u ubuntu mkdir -p /home/ubuntu/.ssh
aws secretsmanager get-secret-value --secret-id "%%SECRET_ID%%" --query 'SecretBinary' --output text | base64 -d > /home/ubuntu/.ssh/id_ed25519_minecraft-server-manager
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_ed25519_minecraft-server-manager
sudo chmod 0400 /home/ubuntu/.ssh/id_ed25519_minecraft-server-manager
sudo -u ubuntu mkdir -p /home/ubuntu/workspace
cd /home/ubuntu/workspace
export GIT_SSH_COMMAND="ssh -i /home/ubuntu/.ssh/id_ed25519_minecraft-server-manager -o StrictHostKeyChecking=no -F /dev/null"
sudo -E -u ubuntu git clone git@github.com:Hiro-Onozawa/minecraft-server-manager.git user_util
sudo -u ubuntu bash /home/ubuntu/workspace/user_util/bash/initialize.sh %%ON_MOUNT_ARG%%