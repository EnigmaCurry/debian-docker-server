#!/bin/bash

######################################################################
### Container variables:
######################################################################
DOCKER_CONTAINER="nginx"
CONTAINER_NAME="nginx-static"
DATA_CONTAINER_NAME="nginx-static-data"
HTTP_PORT="80"
EXTRA_DOCKER_OPTS="-p $HTTP_PORT:80"
######################################################################
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/../../lib/bash_helpers.sh
CONTENT_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/html
CONF_VOLUME=$THIS_DIR/../../docker_volumes/$CONTAINER_NAME/conf

if [ ! -d "$CONTENT_VOLUME" ]
then
    mkdir -p $CONTENT_VOLUME
    echo "Hello, World!" > $CONTENT_VOLUME/index.html
fi
if [ ! -d "$CONF_VOLUME" ]
then
    mkdir -p $CONF_VOLUME
    cat <<EOF > $CONF_VOLUME/default.conf
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/log/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
EOF
fi
    
docker rm -f $DATA_CONTAINER_NAME > /dev/null 2>&1
docker run -v $CONTENT_VOLUME:/usr/share/nginx/html:ro -v $CONF_VOLUME:/etc/nginx/conf.d:ro --name $DATA_CONTAINER_NAME busybox true
docker pull $DOCKER_CONTAINER

create_service

# Allow SSH access through the firewall
ufw allow $HTTP_PORT
