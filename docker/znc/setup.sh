#!/bin/bash

######################################################################
### Container variables:
######################################################################
[ -z "$VERSION" ] && VERSION=":latest"
DOCKER_CONTAINER="jimeh/znc$VERSION"
CONTAINER_NAME="znc"
DATA_CONTAINER_NAME="znc-data"
[ -z "$ZNC_PORT" ] && ZNC_PORT="127.0.0.1:6667"
[ -z "$EXTRA_DOCKER_OPTS" ] && EXTRA_DOCKER_OPTS="-p $ZNC_PORT:6667"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
DATA_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/data

if [ ! -d "$DATA_VOLUME" ]
then
    mkdir -p $DATA_VOLUME
fi
    
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $DATA_VOLUME:/znc-data --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service

