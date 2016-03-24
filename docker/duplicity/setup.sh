#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="dataferret/cron-duplicity"
CONTAINER_NAME="duplicity"
DATA_CONTAINER_NAME="duplicity-data"
# AWS credentials specified interactively by default:
# AWS_BUCKET
# AWS_ACCESS_KEY
# AWS_SECRET_KEY
# AWS_ENCRYPTION_KEY
######################################################################
source ../../lib/bash_helpers.sh

while :
do
    [ -z "$AWS_BUCKET" ] && read -p "Please enter your AWS Bucket Name: " AWS_BUCKET
    [ -z "$AWS_ACCESS_KEY" ] && read -p "Please enter your AWS Access Key: " AWS_ACCESS_KEY
    [ -z "$AWS_SECRET_KEY" ] && read -p "Please enter your AWS Secret Key: " AWS_SECRET_KEY
    [ -z "$AWS_ENCRYPTION_KEY" ] && read -p "Please enter a passphrase to encrypt data: " AWS_ENCRYPTION_KEY
    confirm_vars AWS_BUCKET AWS_ACCESS_KEY AWS_SECRET_KEY AWS_ENCRYPTION_KEY
    [ $? == 0 ] && break
done

EXTRA_DOCKER_OPTS="-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY -e REMOTE_URL=s3+http://$AWS_BUCKET/ -e SOURCE_PATH=/backups -e PASSPHRASE=$AWS_ENCRYPTION_KEY"

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_VOLUME=$THIS_DIR/../../docker_volumes

docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $BACKUP_VOLUME:/backups --name $DATA_CONTAINER_NAME busybox true
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
ExecStop=/usr/bin/docker stop -t 5 $CONTAINER_NAME

[Install]
WantedBy=multi-user.target
EOF

systemctl link $THIS_DIR/"$CONTAINER_NAME".service
touch /etc/init.d/$CONTAINER_NAME
######################################################################

