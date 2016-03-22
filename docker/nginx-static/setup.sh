#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="nginx"
CONTAINER_NAME="nginx-static"
DATA_CONTAINER_NAME="nginx-static-data"
HTTP_PORT="80"
EXTRA_DOCKER_OPTS="-p $HTTP_PORT:80"
######################################################################

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTENT_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/repositories

if [ ! -d "$CONTENT_VOLUME" ]
then
    mkdir -p $CONTENT_VOLUME
    echo "Hello, World!" > $CONTENT_VOLUME/index.html
fi
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $CONTENT_VOLUME:/usr/share/nginx/html:ro --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

######################################################################
### Create systemd service
######################################################################
cat <<EOF > $THIS_DIR/$CONTAINER_NAME.service
[Unit]
Description=$CONTAINER_NAME
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm --volumes-from $DATA_CONTAINER_NAME --name $CONTAINER_NAME $EXTRA_DOCKER_OPTS $DOCKER_CONTAINER
ExecStop=/usr/bin/docker stop -t 5 $DOCKER_CONTAINER

[Install]
WantedBy=multi-user.target
EOF

systemctl link $THIS_DIR/"$CONTAINER_NAME".service
touch /etc/init.d/$CONTAINER_NAME
######################################################################

# Allow SSH access through the firewall
ufw allow $HTTP_PORT
