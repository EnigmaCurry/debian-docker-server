# Logger helper
exe() { echo "\$ $@" ; "$@" ; }

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

service_setup() {
    $DDS_ROOT/docker/$1/setup.sh
}

wait_for_container() {
    (
	set +e
	tries=0
	while true; do
	    tries=$((tries+1))
	    echo "Waiting for $1 container to start ..."
	    if (docker inspect $1 > /dev/null); then
		break
	    else
		if [ $tries -gt 15 ]; then
		    echo "Timed out waiting for $1 to start."
		    return 1
		fi
		sleep 2
	    fi
	done
    )
}

service_enable_now() {
    # Old versions of systemd don't have enable --now so this will have to do:
    (
	set +e
	systemctl enable $1
	# Return true even though systemctl is dumb on debian and
	# tries to call a non-existent LSB script
	true
    )
    exe systemctl start $1
    exe wait_for_container $1
}
 
