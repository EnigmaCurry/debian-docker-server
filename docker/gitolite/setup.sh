#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="elsdoerfer/gitolite"
CONTAINER_NAME="gitolite"
DATA_CONTAINER_NAME="gitolite-data"
SSH_PORT="2222"
EXTRA_DOCKER_OPTS="-p $SSH_PORT:22"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh

GIT_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/repositories
SSH_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/ssh

mkdir -p $GIT_VOLUME
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $GIT_VOLUME:/home/git/repositories -v $SSH_VOLUME:/etc/ssh --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

if [ -d "$GIT_VOLUME"/gitolite-admin.git ];
then
    # git repositories already exist, don't do initial setup
    echo "Admin repository already exists, skipping initial setup"
else
    if [ -z "$SSH_KEY" ]
    then
	echo "No SSH_KEY environment variable found"
	ask_confirm "Please enter your SSH pubkey" SSH_KEY
    fi
    
    # Run the container to initialize the configuration:
    /usr/bin/docker run --rm -e SSH_KEY="$SSH_KEY" --volumes-from $DATA_CONTAINER_NAME --name $CONTAINER_NAME $DOCKER_CONTAINER /init true
    # Disable password authentication:
    perl -pi -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_VOLUME/sshd_config
fi

create_service

# Allow SSH access through the firewall
ufw allow $SSH_PORT
