#!/bin/bash

PATH=$PATH:$(dirname "$(dirname "$0")")

while true; do
  timeout 5 bash -c 'cat /home/ubuntu/workspace/user_util/settings/http_index.html | http/make_response.sh "text/html" | nc -l -p 18080 -N'
done
