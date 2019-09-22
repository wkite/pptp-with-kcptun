#!/bin/bash
set -ex
DEBUG=${DEBUG:-false}
DIRNAME=$(dirname "$(readlink -f $0)")
NAME=$(basename $DIRNAME)
RUN_AFTER_BUILD=${RUN_AFTER_BUILD:-true}
ENTER_ENV=${ENTER_ENV:-false}

PORT=${PORT:-80}
RPC_PORT=$(($PORT + 6720))
PASSWORD=${PASSWORD:-default-password}

docker build --build-arg DEBUG=${DEBUG} -t $NAME $DIRNAME
docker ps -a | grep " $NAME" | awk '{print$1}' | xargs docker stop || true
docker ps -a | grep " $NAME" | awk '{print$1}' | xargs docker rm || true
docker images | grep '<none>' | awk '{print$3}' | xargs docker rmi || true

if $RUN_AFTER_BUILD; then
  docker run -d --name $NAME-$PORT --restart=always -e USERNAME=admin -e PASSWORD=$PASSWORD \
    -v /mnt/media:/var/www/html/media -p $PORT:80/tcp -p $RPC_PORT:6800/tcp $NAME
  sleep 1 && docker logs $NAME-$PORT
fi

if $ENTER_ENV; then
  docker exec -it $NAME-$PORT /bin/sh
else
  echo docker exec -it $NAME-$PORT /bin/sh
fi
