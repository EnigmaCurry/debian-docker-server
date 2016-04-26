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
DATA_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/data
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
if [ ! -d "$DATA_VOLUME" ]
then
    mkdir -p $DATA_VOLUME
    chown 700 $DATA_VOLUME
fi
  
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $LOG_VOLUME:/var/log/postgresql -v $SUPERVISOR_VOLUME:/var/log/supervisor -v $CONF_VOLUME:/etc/postgresql/$POSTGRES_VERSION/main -v $DATA_VOLUME:/var/lib/postgresql/$POSTGRES_VERSION/main -v $WAL_E_VOLUME:/etc/wal-e.d/env --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

# Copy default config files if none exist yet:
if [ $(ls $CONF_VOLUME | wc -l) == 0 ]; then
    docker run -v $CONF_VOLUME:/t -it abevoelker/postgres cp -R "/etc/postgresql/9.4/main/." /t
fi

create_service

