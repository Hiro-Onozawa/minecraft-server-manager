#!/bin/bash -eu

PATH=$PATH:$(dirname "$(dirname "$0")")

source server/setup_env.sh

mcrcon 'list' 2>/dev/null | sed -E -n 's/^There are ([0-9]+) .+$/\1/p'