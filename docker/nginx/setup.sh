#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="nginx"
CONTAINER_NAME="nginx"
DATA_CONTAINER_NAME="nginx-data"
[ -z "$HTTP_PORT" ] && HTTP_PORT="80"
[ -z "$EXTRA_DOCKER_OPTS" ] && EXTRA_DOCKER_OPTS="-p $HTTP_PORT:80"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
CONTENT_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/html
CONF_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/conf
LOG_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/logs

if [ ! -d "$CONTENT_VOLUME" ]
then
    mkdir -p $CONTENT_VOLUME
    echo "Hello, World!" > $CONTENT_VOLUME/index.html
fi
if [ ! -d "$CONF_VOLUME" ]
then
    mkdir -p $CONF_VOLUME
    cat <<EOF > $CONF_VOLUME/default.conf
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/log/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
fi
    
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $CONTENT_VOLUME:/usr/share/nginx/html:ro -v $CONF_VOLUME:/etc/nginx/conf.d:ro -v $LOG_VOLUME:/var/log/nginx/log --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service

