#!/bin/bash

PATH=$PATH:$(dirname "$0")

echo "HTTP/1.1 200 OK"
echo "Content-Type: $1; charset=UTF-8"
echo "Access-Control-Allow-Origin: *"
echo ""
cat -
