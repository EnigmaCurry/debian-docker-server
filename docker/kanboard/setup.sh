#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="kanboard/kanboard:stable"
CONTAINER_NAME="kanboard"
DATA_CONTAINER_NAME="kanboard-data"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
DATA_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/data
PLUGIN_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/plugins

if [ ! -d "$DATA_VOLUME" ]; then
    mkdir -p $DATA_VOLUME
fi
if [ ! -d "$PLUGIN_VOLUME" ]; then
    mkdir -p $PLUGIN_VOLUME
fi
    
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $DATA_VOLUME:/var/www/kanboard/data -v $DATA_VOLUME:/var/www/kanboard/plugins --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service