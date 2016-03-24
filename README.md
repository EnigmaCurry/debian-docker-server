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

### nginx-static

A simple [nginx](https://www.nginx.com/) container to serve static content via HTTP.

Setup:

    ~/debian-docker-server/docker/nginx-static/setup.sh
	systemctl enable nginx-static
	systemctl start nginx-static

Place your content in docker_volumes/nginx-static

### gitolite

[gitolite](http://gitolite.com/gitolite/) hosts git repositories and makes it easy to allow access to
your coworkers or friends.

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

If you're restoring data to a new machine, make sure you run that
command before you setup your other containers.

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
  'custom inline policy' and paste the following, changing the bucket name to yours:
  
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
