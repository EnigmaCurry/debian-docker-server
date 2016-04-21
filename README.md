Debian Docker Server
====================

This is a set of scripts to run and maintain a docker host running
debian (jessie.) It includes a number of scripts to setup containers
and create systemd service files for them. It includes a backup script
for all of the container volumes to Amazon S3, as well as a restore
process to completely recreate the environment on a fresh server.

Additionally, this README also details how to automate provisioning from your 
personal computer with [curlbomb](https://github.com/EnigmaCurry/curlbomb).

Bootstrap Server
----------------

Run the setup script from this repository on the server:

    bash <(wget https://git.io/vaNIX -q -O -)
	
This configures the firewall, installs docker, and clones this
repository. This is intended to be run on a fresh server (tested on
Digital Ocean Debian 8.3 image)

Docker containers
-----------------

This repository ships with several docker container configurations you
can use. Each one has a setup script that creates a systemd service
that you can enable to start containers on system boot.

### nginx

A simple [nginx](https://www.nginx.com/) container to use as a webserver.

Setup:

    ~/debian-docker-server/docker/nginx/setup.sh
	systemctl enable nginx
	systemctl start nginx

Place your content in docker_volumes/nginx/html. Congigure the
server in docker_volumes/nginx/conf

### gitolite

[gitolite](http://gitolite.com/gitolite/) hosts git repositories and makes it easy to allow access to
your coworkers or friends. This container runs it's own SSH server on it's own port (2222 by default) 

Setup:

    ~/debian-docker-server/docker/gitolite/setup.sh
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

### duplicity

You can backup all your containers to Amazon S3 with this one.

Setup:

    ~/debian-docker-server/docker/duplicity/setup.sh
	systemctl enable duplicity
	systemctl start duplicity
	
Setup will ask you for your S3 bucket and authentication parameters
(see the section below if you don't have that setup already.) In
addition it will ask you for a passphrase to encrypt the backups
with. Save all that information some place safe. You will need all
that information if you need to restore to a new machine.

With the duplicity container running, it will backup any changes to
your docker volumes (~/debian-docker-server/docker_volumes)
hourly. You can force the backup to run now with the follwing command:

    docker exec -it duplicity backup

You can restore the data with:

    docker exec -it duplicity restore

If you're restoring data to a new machine, make sure you run the
restore command before you setup your other containers as some of the
scripts will try to look for existing data before doing their setup.

#### Create IAM and S3 bucket

For duplicity backups, it's best to create a fresh bucket and access
keys that only have access to that one bucket. Here's how to do that:

* Login to the the [AWS console](https://console.aws.amazon.com)
* Navigate to the [S3 console](https://console.aws.amazon.com/s3) and
  create a new bucket. For demo purposes I chose 'dds-duplicity'.
* Navigate to the [IAM console](https://console.aws.amazon.com/iam)
* Click on Users and Create New Users
* Enter the name you want. I chose 'dds-duplicity'
* Click Create
* Make note of the Access and Secret keys. They are only displayed this one time.
* Click on the new user and go to the Permissions tab. Create an
  'custom inline policy' and paste the following, changing the
  instances of 'dds-duplicity' to the name of the bucket you created:
  
        {
          "Statement": [
            {
              "Action": "s3:*",
              "Effect": "Allow",
              "Resource": [
                "arn:aws:s3:::dds-duplicity",
                "arn:aws:s3:::dds-duplicity/*"
              ]
            }
          ]
        }

Automated setup
---------------

You can automate the entire bootstrap and setup of a server by writing
a script that contains all the necessary variables. The quick and
dirty way of doing this is to just copy the script to the server and
run it. This can get tedious pretty fast, especially if you have to
provision a lot of servers.

[curlbomb](https://github.com/EnigmaCurry/curlbomb) will let you keep
the install script on your local computer where it's easy to edit and
keep safe. It will also serve that script to the server to be used one
time via curl.

Write the installation script and specify all the variables the
individual containers need:

    cd $HOME

    # Setup base system, set DDS_ROOT:
    source <(wget https://raw.githubusercontent.com/EnigmaCurry/debian-docker-server/master/debian_setup.sh -q -O -)
    source $DDS_ROOT/lib/bash_helpers.sh
    
    # Perform setup for each container:
    # Running in a subshell (parentheses) prevents leaking environment
    # variables between containers
    
    # Setup duplicity
    (
		# Your Amazon S3 bucket name and credentials to store backups of your containers:
        export AWS_BUCKET=my-bucket-name
        export AWS_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXX
        export AWS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        export AWS_ENCRYPTION_KEY=my_encryption_passphrase
        service_setup duplicity
        service_enable_now duplicity
		# Run restore to download any existing backups to this machine:
        docker exec -it duplicity restore
    )
    
    # Setup nginx
    (
        export HTTP_PORT=80
        service_setup nginx
        service_enable_now nginx
    )
    
    # Setup gitolite
    (
        export SSH_PORT=2222
		# Your SSH key to be installed as the admin key for gitolite:
        export SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmo9sQ6iAHDH8Gg1vd1js3R+wnbex3t68/oNgLhF//A9ierMXsNc+P09PO3VAYBxSvI5kxO/BLVecUVDLrnu525NlB6jpHK685ijs5MZB2Bv5CTB5nDyhT3aQ7eO09eqHFOicFM3VOCdCesN4xDiTZ3g7ETzEax+NDhE0LN1iLxlpFPWcol/KA7KanA22kJTFqDRC/90u8lxedaAPALk7j8i5beRAg7b1LdJLa1gyKnLXOeKR01aMBObtA9gF2vbIPeoyKwQxJyjujLuuC9Jmp/C1hBI08H2+Gltu/AZafcLlqLjNjxPJhgcLhbw4ZB4YCWeVKiRMQF90vaK5ei12qQ== snowden@nsa"
        service_setup gitolite
        service_enable_now gitolite
    )

Since this is potentially sensitive data, you may want to be careful
where you store this script. This is where curlbomb comes in
handy. You can write the script on your personal computer and serve it
from there as a one-time-use installer script.

Install curlbomb:

    # On arch linux, with your favorite AUR helper:
	pacaur -S curlbomb
	
	# Or with a PyPI installer:
	pip install curlbomb
	
If you're on the same network as the machine you're installing to,
just serve the file directly:

    curlbomb /path/to/installer.sh

curlbomb outputs a curl command like this:

    KNOCK=zyA8OgIWAF4oSvsG bash <(curl -LSs http://10.13.37.133:43515)

Paste that one line into the new machine and watch everything install by itself :)

If the new machine is somewhere in the cloud (and you probably don't
make a habit of opening up ports to your local computer), you can
still use curlbomb from your local machine, but you'll need a third
machine that has open ports to the internet to use as a proxy. Bear
with me here, because cool magical stuff is about to happen, and while
it requires a bit of setup, you can show off to your fellow cloud
wizards some new found abilities... This third machine has a few
requirements:

 * It needs to have at least one unused TCP port open to the public internet.
 * You have SSH access to it.
 * The sshd_config of the machine has
   ['GatewayPorts'](http://www.snailbook.com/faq/gatewayports.auto.html)
   set to "clientspecified" or "yes" (the former is more secure.)
 * Optionally, you also have an SSL certificate created for that machine.

For example, if your intermediary server is called public.example.com,
it has port 8080 open to the public, you have ssh access for the user
called 'edward', it has GatewayPorts turned on, and you have a copy of it's SSL
certificate on your local computer, you could run curlbomb like this:

    curlbomb --ssh edward@public.example.com:8080 --ssl /path/to/ssl_cert.pem run /path/to/installer.sh

That will output a different curl command (note the public domain name rather 
than the local IP, and https rather than http) :

    KNOCK=4virgAOgkuS1XgEG bash <(curl -LSs https://public.example.com:8080)

Paste that command, from anywhere in the world, and watch the installation fly.

Let's enumerate what's cool about this:

 * You write the script and keep it on your local laptop. Sensitive
   data doesn't get saved anywhere else unless you want it to.
 * Your laptop stays completely behind a firewall.
 * The client can be halfway around the world, as long as it can 
   access the intermediary server.
 * curlbomb enforces a X-knock header, only clients that know the
   correct knock gain access (they know it because you pasted it 
   in the curlbomb.)
 * curlbomb automatically quits after serving the script one time, 
   so the knock only works once. 
 * Everything is SSL encrypted, only the end client ever sees the script.
 * Even though you have to keep the ssl cert on your local computer, it can 
   be PGP encrypted and curlbomb will decrypt it on the fly.
 * You didn't have to type anything on the client other than the curl
   command. This means your install is repeatable and documented.
 * You went through the trouble of setting up the intermediary server,
   but now you can use it again for other curlbombs :)

I keep an alias for this public-accessible curlbomb, for easier typing later:

    alias curlbomb_public="curlbomb --ssh edward@public.example.com:8080 --ssl ~/.curlbomb/cert.pem.gpg"

