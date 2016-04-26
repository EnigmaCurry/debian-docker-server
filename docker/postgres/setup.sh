#!/bin/bash

######################################################################
### Container variables:
######################################################################
[ -z "$VERSION" ] && VERSION=":latest"
DOCKER_CONTAINER="abevoelker/postgres$VERSION"
POSTGRES_VERSION=9.4
CONTAINER_NAME="postgres"
DATA_CONTAINER_NAME="postgres-data"
[ -z "$EXTRA_DOCKER_OPTS" ] && EXTRA_DOCKER_OPTS=""
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
LOG_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/logs
SUPERVISOR_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/supervisor
CONF_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/conf
VAR_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/var
WAL_E_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/wal-e

if [ ! -d "$LOG_VOLUME" ]
then
    mkdir -p $LOG_VOLUME
fi
if [ ! -d "$SUPERVISOR_VOLUME" ]
then
    mkdir -p $SUPERVISOR_VOLUME
fi
if [ ! -d "$CONF_VOLUME" ]
then
    mkdir -p $CONF_VOLUME
fi
if [ ! -d "$VAR_VOLUME" ]
then
    mkdir -p $VAR_VOLUME
fi
  
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $LOG_VOLUME:/var/log/postgresql -v $SUPERVISOR_VOLUME:/var/log/supervisor -v $CONF_VOLUME:/etc/postgresql/$POSTGRES_VERSION/main -v $VAR_VOLUME:/var/lib/postgresql/$POSTGRES_VERSION/main -v $WAL_E_VOLUME:/etc/wal-e.d/env --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service

