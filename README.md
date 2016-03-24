Debian Docker Server
====================

This is a config framework for running a debian (jessie) docker
server. Separate setup scripts for a collection of docker containers.

Bootstrap Server
----------------

Run the setup script from this repository on the server:

    bash <(wget https://git.io/vaNIX -q -O -)
	
This configures the firewall, installs docker, and clones this
repository.

Docker containers
-----------------

This repository ships with several docker container configurations you
can use. Each one has a setup command that creates a systemd service
that automatically gets started for that container on boot.

# nginx-static

A simple [nginx](https://www.nginx.com/) container to serve static content via HTTP.

Setup:

    ./docker/nginx-static/setup.sh
	systemctl enable nginx-static
	systemctl start nginx-static

Place your content in docker_volumes/nginx-static

# gitolite

[gitolite](http://gitolite.com/gitolite/) hosts git repositories and makes it easy to allow access to
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
	
Place your users in the the config file and their SSH keys in keydir.

Here's a simple config example:

    @developers     = admin ryan

    repo gitolite-admin
        RW+     =   admin

    repo dotfiles-private
        RW+     =   ryan
		
	repo work-project
	    RW+     =   @developers

For more info see the [gitolite docs](http://gitolite.com/gitolite/gitolite.html)
