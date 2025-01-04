#!/bin/bash

cd $(dirname "$(dirname "$0")")
PATH=$PATH:$(pwd)

source server/setup_env.sh
cat /home/ubuntu/workspace/user_util/template/index.html.template \
  | sed 's|/\*\${{instance_id}}\*/|'"$(ec2metadata --instance-id)"'|g' \
  | sed 's|/\*\${{public_ip_address}}\*/|'"${SERVER_ADDRESS}"'|g' \
  | sed 's|/\*\${{server_name}}\*/|'"${SERVER_NAME}"'|g' \
  | sed 's|/\*\${{version}}\*/|'"$(cd /home/ubuntu/workspace/user_util/ && git rev-parse --short HEAD)"'|g' \
  | sed 's|/\*\${{console_lambda_url}}\*/|'"${CONSOLE_LAMBDA_URL}"'|g' \
  > /home/ubuntu/workspace/user_util/settings/http_index.html

sudo cp /home/ubuntu/workspace/user_util/systemd/http_status_check.service /etc/systemd/system/
sudo cp /home/ubuntu/workspace/user_util/systemd/http_index_html.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start http_index_html.service http_status_check.service
