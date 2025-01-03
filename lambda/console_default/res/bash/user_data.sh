#!/bin/bash -eu
apt update
apt install -y unzip
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install
rm -rf ./awscliv2.zip ./aws
sudo -u ubuntu mkdir -p /home/ubuntu/workspace
cd /home/ubuntu/workspace
sudo -u ubuntu git clone --filter=blob:none --sparse --no-checkout --branch %%BRANCH_NAME%% https://github.com/Hiro-Onozawa/minecraft-server-manager.git user_util
pushd user_util
sudo -u ubuntu git sparse-checkout set
sudo -u ubuntu git sparse-checkout add bash systemd template
sudo -u ubuntu git checkout
popd
sudo -u ubuntu mkdir -p /home/ubuntu/workspace/user_util/settings
cat << EOS > /home/ubuntu/workspace/user_util/settings/instance_parameters.json
%%INSTANCE_PARAMS_JSON%%
EOS
sudo -u ubuntu bash /home/ubuntu/workspace/user_util/bash/initialize.sh