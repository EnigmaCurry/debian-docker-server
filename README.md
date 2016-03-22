Debian Docker Server
====================

These are generic instructions for setting up a debian (jessie) server
for serving docker containers

Bootstrap Server
----------------

Install git:

    apt update && apt install -y git

Checkout this repo:

    git clone http://github.com/EnigmaCurry/debian-docker-server

Run the setup script:

    cd debian-docker-server
	./debian_setup.sh

You now have docker setup and an initial firewall that only allows ssh access


Docker containers
-----------------

This repository ships with several docker container configurations you
can use. Each one has a setup command that creates a systemd service
that automatically gets started for that container on boot.

# nginx-static

A simple nginx container to serve static content via HTTP.

Setup:

    ./docker/nginx-static/setup.sh
	systemctl enable nginx-static
	systemctl start nginx-static

Place your content in docker_volumes/nginx-static

# gitolite

gitolite hosts git repositories and makes it easy to allow access to
your coworkers or friends.

Setup:

    ./docker/gitolite/setup.sh
	systemctl enable gitolite
	systemctl start gitolite

The script will ask you for your SSH public key. This can also be
specified via the SSH\_KEY environment variable. This should be the
full contents of your local ~/.ssh/id_rsa.pub file starting with
'ssh-rsa'

Now checkout the admin repository from your local machine:

    git clone ssh://git@YOUR_SERVER:2222/gitolite-admin
	

