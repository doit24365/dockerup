# dockerup
#### The script automates some routine operations with containers:
1. Create project directory (named such as ticket number or magento version).
2. Create docker-compose.yml.
3. Run container.
4. Create host config.
5. Mount container volume to your file system.

#### You can run several containers simultaneously. Each container will have own ports.

### Installing: 
    cd ~/scripts
    git clone https://github.com/doit24365/dockerup.git
    cd dockerup
    chmod +x dockerup.sh

### Before usage:
#### Insert to file ~/.ssh/config:
        Include cnt_cnf/*
    
### Usage:
    Help:           ~/work/scripts/dockerup/dockerup.sh -h
    Run container:  ~/work/scripts/dockerup/dockerup.sh -t 214 -i 2.1.4-git-sd
    Frontend:       http://127.0.0.1:2140/
    MailCatcher:    http://127.0.0.1:2141/
    ssh:            ssh 214
   
