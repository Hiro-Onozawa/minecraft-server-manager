#!/bin/bash

PATH=$PATH:$(dirname "$(dirname "$0")")

while true; do
  timeout 5 bash -c 'server_health_check.sh | http/make_response.sh "application/json" | nc -l -p 18081 -N'
done
