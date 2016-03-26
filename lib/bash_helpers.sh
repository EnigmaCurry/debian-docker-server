# Prompt the user to set a variable name and confirm it's correct
ask_confirm() {
    # Args: PROMPT VARIABLE
    # example: ask_confirm "Enter your name" NAME
    while :
    do
	read -p "$1"": " $2
	echo ${2}=${!2}
	read -p "Does this look right? (Y/n) " LOOKS_RIGHT
	if [ "$LOOKS_RIGHT" == "" ] || [ "$LOOKS_RIGHT" == "Y" ] || [ "$LOOKS_RIGHT" == "y" ]
	then
	    break
	fi
    done
}

# Confirm with the user a set of vars are correct:
confirm_vars() {
    # Args: list of variables to confirm
    # Example:
    #   read -p "Enter your name" NAME
    #   read -p "Enter your age" AGE
    #   confirm_vars NAME AGE
    for var in "$@"
    do
	echo $var=${!var}
    done
    read -p "Does this look right? (Y/n) " LOOKS_RIGHT
    if [ "$LOOKS_RIGHT" == "" ] || [ "$LOOKS_RIGHT" == "Y" ] || [ "$LOOKS_RIGHT" == "y" ]
    then
	return 0
    else
	return 1
    fi
}

######################################################################
### Create systemd service
######################################################################
create_service() {
    # REQUIRED ENV VARS:
    #   THIS_DIR - the path where the setup.sh script lives
    #   CONTAINER_NAME - the name of the container and systemd service
    #   DATA_CONTAINER_NAME - the name of the container hosting the volumes
    #   DOCKER_CONTAINER - the docker hub container name
    #   EXTRA_DOCKER_OPTS - additional docker run arguments
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
}

service_enable_now() {
    # Old versions of systemd don't have enable --now so this will
    # have to do:
    systemctl enable $1
    systemctl start $1
}
