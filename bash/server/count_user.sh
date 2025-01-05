#!/bin/bash -eu

cd "$(dirname "$(dirname "$0")")" || exit 1
PATH=$PATH:$(pwd)

source server/setup_env.sh

mcrcon 'list' 2>/dev/null | sed -E -n 's/^There are ([0-9]+) .+$/\1/p'
