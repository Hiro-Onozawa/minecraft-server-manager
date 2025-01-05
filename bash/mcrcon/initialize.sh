#!/bin/bash

mkdir -p /home/ubuntu/workspace/mcrcon
cd /home/ubuntu/workspace/mcrcon || exit 1
wget -q -O mcrcon.tar.gz https://github.com/Tiiffi/mcrcon/releases/download/v0.7.2/mcrcon-0.7.2-linux-x86-64.tar.gz
tar -zxf mcrcon.tar.gz
rm mcrcon.tar.gz
