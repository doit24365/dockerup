#!/usr/bin/env bash

BASE_DIR="$(dirname `readlink "$0"`)";

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

M2_DUMPS_DEPLOYED=0
if [ "$MAGENTO_VERSION" = "m2" ] && [ "$DOCKER_IMAGE_NAME" = "base" ]
then
    echo "Creating .m2install.conf file..."
    cp "$BASE_DIR/template/.m2install.conf" "$CONTAINER_PATH/.m2install.conf"
    sed -i '' s/%domain%/"$DOMAIN"/g $CONTAINER_PATH/.m2install.conf;
    scp $CONTAINER_PATH/.m2install.conf $TICKET_NUMBER:/var/www/html
    echo "Created!"

    echo "Finding code dump..."
    codeDumpFilename=$(find . -maxdepth 1 -name '*.tbz2' -o -name '*.tar.bz2' | head -n1)
    if [ "${codeDumpFilename}" == "" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.tar.gz' | grep -v 'logs.tar.gz' | head -n1)
    fi
    if [ ! "$codeDumpFilename" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.tgz' | head -n1)
    fi
    if [ ! "$codeDumpFilename" ]
    then
        codeDumpFilename=$(find . -maxdepth 1 -name '*.zip' | head -n1)
    fi

    if [ "$codeDumpFilename" != "" ]
    then
        echo "Code dump $codeDumpFilename was copied to container!"
        scp "$codeDumpFilename" $TICKET_NUMBER:/var/www/html
    else
        echo "Code dump was not found!"
    fi

    echo "Finding db dump..."
    dbdumpFilename=$(find . -maxdepth 1 -name '*.sql.gz' | head -n1)
    if [ ! "$dbdumpFilename" ]
    then
        dbdumpFilename=$(find . -maxdepth 1 -name '*_db.gz' | head -n1)
    fi
    if [ ! "$dbdumpFilename" ]
    then
        dbdumpFilename=$(find . -maxdepth 1 -name '*.sql' | head -n1)
    fi

    if [ "$dbdumpFilename" != "" ]
    then
        echo "Database dump $codeDumpFilename was copied to container"
        scp "$dbdumpFilename" $TICKET_NUMBER:/var/www/html
    else
        echo "Code dump was not found!"
    fi

    if [ "$codeDumpFilename" != "" ] && [ "$dbdumpFilename" != "" ]
        echo "Code and database dumps were found. Staring m2install tool..."
        ssh $TICKET_NUMBER "cd /var/www/html; m2install.sh --force"
        M2_DUMPS_DEPLOYED=1
    then
        echo "Code and database dumps were not found. m2install will not run automatically!"
    fi
fi

# Set base url
if [ "$M2_DUMPS_DEPLOYED" != "1" ]
then
    ssh $TICKET_NUMBER "mysql -umagento -p123123q magento -e \"UPDATE core_config_data SET value=\\\"http://$DOMAIN/\\\" WHERE path=\\\"web%url\\\";\""

    echo "Creating config.local.php file..."
    cp "$BASE_DIR/template/config.local.php" "$CONTAINER_PATH/config.local.php"
    sed -i '' s/%domain%/"$DOMAIN"/g $CONTAINER_PATH/config.local.php;
    scp $CONTAINER_PATH/config.local.php $TICKET_NUMBER:/var/www/html/app/etc/
    echo "Created!"
fi

# Cleaning and static deploy
if [ "$MAGENTO_VERSION" = "m2" ] && [ "$M2_DUMPS_DEPLOYED" != "1" ]
then
    ssh $TICKET_NUMBER "sudo rm -Rf /var/www/html/var/*; rm -Rf /var/www/html/pub/static/frontend; rm -Rf /var/www/html/pub/static/adminhtml; rm -Rf /var/www/html/pub/static/_requirejs; cd /var/www/html/; php bin/magento setup:static-content:deploy"
fi

# Enable xdebug for the container
if [ "$XDEBUG" ]; then
    log "Enable xdebug"
    ssh $TICKET_NUMBER "sudo /usr/local/bin/xdebug-sw.sh 1"
fi