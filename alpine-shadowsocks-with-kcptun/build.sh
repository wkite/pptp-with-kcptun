#!/bin/bash
set -ex
DEBUG=${DEBUG:-false}
DIRNAME=$(dirname $(readlink -f $0))
NAME=$(basename $DIRNAME)
RUN_AFTER_BUILD=${RUN_AFTER_BUILD:-true}
ENTER_ENV=${ENTER_ENV:-false}

PORT=${PORT:-6666}
PASSWORD=${PASSWORD:-default-password}

docker build --build-arg DEBUG=${DEBUG} -t $NAME $DIRNAME
docker ps -a | grep " $NAME" | awk '{print$1}' | xargs docker stop || true
docker ps -a | grep " $NAME" | awk '{print$1}' | xargs docker rm || true
docker images | grep '<none>' | awk '{print$3}' | xargs docker rmi || true

if $RUN_AFTER_BUILD; then
  docker run -d --name $NAME-$PORT --restart=always -e PASSWORD=$PASSWORD -e KCP_ENCRYPT=none -e KCP_PASSWORD=none-encrypt -p $PORT:29900/udp $NAME
  sleep 1 && docker logs $NAME-$PORT
fi

if $ENTER_ENV; then
  docker exec -it $NAME-$PORT /bin/sh
fi
