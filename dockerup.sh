#!/usr/bin/env bash

BASE_DIR="$(dirname "$0")";

source "$BASE_DIR/config.sh";
if [ -f "$BASE_DIR/config_custom.sh" ]; then
    source "$BASE_DIR/config_custom.sh";
fi
source "$BASE_DIR/lib.sh";
source "$BASE_DIR/params.sh";
source "$BASE_DIR/init.sh";

CONTAINER_PATH="$CONTAINERS_DIR_PATH/$TICKET_NUMBER";

# Create dir for project
if [ ! -d "$CONTAINER_PATH" ]; then
    log "Create $CONTAINER_PATH";
    mkdir -p "$CONTAINER_PATH"
fi

# Prepare IP address
IP_ADDRESS="${CONTAINERS_IP_TEMPLATE/NUM1/${TICKET_NUMBER:0:2}}"
IP_ADDRESS="${IP_ADDRESS/NUM2/${TICKET_NUMBER:2:2}}"
sudo ifconfig lo0 alias $IP_ADDRESS up

# Create docker-compose.yml
if [ ! -f "$CONTAINER_PATH/docker-compose.yml" ]; then
    log "Create $CONTAINER_PATH/docker-compose.yml";
    cp "$BASE_DIR/template/docker-compose.yml" "$CONTAINER_PATH/docker-compose.yml"
fi

sed -i '' s/%ip_address%/"$IP_ADDRESS"/g "$CONTAINER_PATH"/docker-compose.yml;
sed -i '' s/%img%/"$DOCKER_IMAGE_NAME"/g "$CONTAINER_PATH"/docker-compose.yml;
sed -i '' s/%magento_version%/"$MAGENTO_VERSION"/g "$CONTAINER_PATH"/docker-compose.yml;

# Run container
cd $CONTAINER_PATH
log "Run container '$TICKET_NUMBER'";
docker-compose up -d;

if [ $? -eq 0 ]; then
    log "Container was created successfully!"
else
    docker-compose down
    rm -Rf $CONTAINER_PATH
    echo "Error! Temporary folder was removed!"
fi

# Create host config
log "Create host config $CONTAINERS_HOST_CONFIG_DIR_PATH/$TICKET_NUMBER";
if [ ! -d $CONTAINERS_HOST_CONFIG_DIR_PATH ]; then
    log "Create $CONTAINERS_HOST_CONFIG_DIR_PATH";
    mkdir -p $CONTAINERS_HOST_CONFIG_DIR_PATH
fi
cp "$BASE_DIR/template/hostconf" $CONTAINERS_HOST_CONFIG_DIR_PATH/"$TICKET_NUMBER";
sed -i '' s/%host%/"$TICKET_NUMBER"/g $CONTAINERS_HOST_CONFIG_DIR_PATH/"$TICKET_NUMBER";
sed -i '' s/%ip_address%/"$IP_ADDRESS"/g $CONTAINERS_HOST_CONFIG_DIR_PATH/"$TICKET_NUMBER";

# Mount container volume to the host
sleep 3;
log "Mount container volume to the host '$CONTAINER_PATH/src/'";
mkdir -p "$CONTAINER_PATH/src";
sshfs "$TICKET_NUMBER":/var/www/html/ "$CONTAINER_PATH/src/" -ocache=no;

# Set own domain
DOMAIN="$TICKET_NUMBER.$CONTAINERS_DOMAIN_SUFFIX"
sudo sh -c "echo '$IP_ADDRESS     $DOMAIN' >> /etc/hosts"

# Set base url
ssh $TICKET_NUMBER "mysql -umagento -p123123q magento -e \"UPDATE core_config_data SET value=\\\"http://$DOMAIN/\\\" WHERE path=\\\"web%url\\\";\""

# Cleaning and static deploy
if [ "$MAGENTO_VERSION" = "m2" ]; then
    ssh $TICKET_NUMBER "sudo rm -Rf /var/www/html/var/*; rm -Rf /var/www/html/pub/static/frontend; rm -Rf /var/www/html/pub/static/adminhtml; rm -Rf /var/www/html/pub/static/_requirejs; cd /var/www/html/; php bin/magento setup:static-content:deploy"
fi

# Enable xdebug for the container
if [ "$XDEBUG" ]; then
    log "Enable xdebug"
    ssh $TICKET_NUMBER "sudo /usr/local/bin/xdebug-sw.sh 1"
fi