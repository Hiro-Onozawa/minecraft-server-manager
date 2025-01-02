#!/bin/bash

cd $(dirname "$(dirname "$0")")
PATH=$PATH:$(pwd)

while true; do
  timeout 5 bash -c 'server/health_check.sh | http/make_response.sh "application/json" | nc -l -p 18081 -N'
done
