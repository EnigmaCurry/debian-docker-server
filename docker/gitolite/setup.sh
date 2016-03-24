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

# SSH key can be obtained interactively, or passed in as SSH_KEY:
if [ -z "$SSH_KEY" ]
then
    echo "No SSH_KEY environment variable found"
    while :
    do
	read -p "Please enter your SSH pubkey: " SSH_KEY
	echo "Your SSH pubkey is:"
	echo $SSH_KEY
	echo
	read -p "Does this look right? (Y/n) " LOOKS_RIGHT
	if [ "$LOOKS_RIGHT" == "" ] || [ "$LOOKS_RIGHT" == "Y" ] || [ "$LOOKS_RIGHT" == "y" ]
	then
	    break
	fi
    done
fi

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GIT_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/repositories
SSH_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/ssh

mkdir -p $GIT_VOLUME
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $GIT_VOLUME:/home/git/repositories -v $SSH_VOLUME:/etc/ssh --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

# Run the container to initialize the configuration:
/usr/bin/docker run --rm -e SSH_KEY="$SSH_KEY" --volumes-from $DATA_CONTAINER_NAME --name $CONTAINER_NAME $DOCKER_CONTAINER /init true
# Disable password authentication:
perl -pi -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_VOLUME/sshd_config

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

# Allow SSH access through the firewall
ufw allow $SSH_PORT
