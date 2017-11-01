# dockerup
#### The script automates some routine operations with containers:
1. Create project directory (named such as ticket number or magento version).
2. Create docker-compose.yml.
3. Run container.
4. Create host config.
5. Mount container volume to your file system.

#### You can run several containers simultaneously. Each container will have own IP address.

### Installing: 
    cd ~/scripts
    git clone https://github.com/doit24365/dockerup.git
    cd dockerup
    chmod +x dockerup.sh
    ln -s $HOME/scripts/dockerup/dockerup.sh /usr/local/bin/dockerup.sh

### Before usage:
#### 1. Check if simlink to dockerup.sh has been created.
#### 2. Insert to file ~/.ssh/config:
        Include cnt_cnf/*
#### 3. Create file config_custom.sh with custom params for overriding config if need. For creating custom config you can use scratch file config_custom.sh.dist with help of command:
        cp config_custom.sh.dist config_custom.sh
    
### Usage:
    Help:           ~/work/scripts/dockerup/dockerup.sh -h
    Run container:  ~/work/scripts/dockerup/dockerup.sh -t 214 -i 2.1.4-git-sd -v
    Frontend:       http://127.0.21.4/
                    http://214.mdva.dev/
    MailCatcher:    http://127.0.21.4:81/
    ssh:            ssh 214
   
