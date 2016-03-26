#!/bin/bash

######################################################################
### Installs base applications
###
###  - ufw firewall
###   - port 22 allowed, not much else
###  - Emacs editor
###  - Docker
###  - Clone of debian-docker-server into the current directory
###
######################################################################

if [[ $EUID != 0 ]]; then
    echo "This needs to be run as root"
    exit 1
fi

apt update
apt install -y apt-transport-https ca-certificates

apt install -y git emacs-nox

# Initial firewall rules:
apt install ufw
yes | ufw enable
ufw allow 22

# Install Docker
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-engine
systemctl start docker

git clone https://github.com/EnigmaCurry/debian-docker-server.git
