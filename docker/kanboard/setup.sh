#!/bin/bash

######################################################################
### Container variables:
######################################################################
[ -z "$VERSION" ] && VERSION=":stable"
DOCKER_CONTAINER="kanboard/kanboard$VERSION"
CONTAINER_NAME="kanboard"
DATA_CONTAINER_NAME="kanboard-data"
[ -z "$KANBOARD_PORT" ] && KANBOARD_PORT="127.0.0.1:8000"
[ -z "$EXTRA_DOCKER_OPTS" ] && EXTRA_DOCKER_OPTS="-p $KANBOARD_PORT:80"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
DATA_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/data
PLUGIN_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/plugins

if [ ! -d "$DATA_VOLUME" ]; then
    mkdir -p $DATA_VOLUME
    chown 100:101 $DATA_VOLUME
fi
if [ ! -d "$PLUGIN_VOLUME" ]; then
    mkdir -p $PLUGIN_VOLUME
    chown 100:101 $PLUGIN_VOLUME
fi
    
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $DATA_VOLUME:/var/www/kanboard/data -v $DATA_VOLUME:/var/www/kanboard/plugins --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service
