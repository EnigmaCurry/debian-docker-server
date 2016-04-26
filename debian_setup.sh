#!/bin/bash

######################################################################
### Installs base applications
###
###  - ufw firewall
###   - port 22 allowed, not much else
###  - fail2ban
###  - Emacs editor
###  - Docker
###  - Clone of debian-docker-server into the current directory
###
######################################################################
exe() { echo "\$ $@" ; "$@" ; }

if [[ $EUID != 0 ]]; then
    echo "This needs to be run as root"
    exit 1
fi

exe apt-get update
exe apt-get install -y apt-transport-https ca-certificates

exe apt-get install -y git emacs-nox

# Initial firewall rules:
exe apt-get install -y ufw
yes | ufw enable
exe ufw default deny
exe ufw allow 22

# Install fail2ban:
# Disabled for now....
# apt-get install -y fail2ban

# Install Docker
exe apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
exe apt-get update
exe apt-get install -y docker-engine
exe systemctl start docker

export DDS_ROOT=$PWD/debian-docker-server
if [ ! -d $DDS_ROOT ]; then
    exe git clone https://github.com/EnigmaCurry/debian-docker-server.git
else
    exe git -C $DDS_ROOT pull
fi
