#!/bin/bash
set -ex
export DEBUG=${DEBUG:-false}
export ENTER_ENV=${ENTER_ENV:-false}
export PASSWORD=${PASSWORD:-default-password}
export RUN_AFTER_BUILD=${RUN_AFTER_BUILD:-true}

find $(dirname "$0") -type f -name build.sh | grep 'wireguard' | while read BUILD_SCRIPT; do
  $BUILD_SCRIPT
done
