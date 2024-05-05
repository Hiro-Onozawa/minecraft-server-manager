#!/bin/bash -eu

PATH=$PATH:$(dirname "$0")

source server_setup_env.sh

mcrcon 'list' 2>/dev/null | sed -E -n 's/^There are ([0-9]+) .+$/\1/p'
