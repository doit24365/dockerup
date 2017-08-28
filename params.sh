#!/usr/bin/env bash

ERRORS=false;
TICKET_NUMBER='';
DOCKER_IMAGE_NAME='';
VERBOSE=false;
HELP=false;

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
        cat usage.txt;
        HELP=true;
        exit 0;
    ;;
    -t|--ticket)
        TICKET_NUMBER="$2"
        shift
    ;;
    -i|--image)
        DOCKER_IMAGE_NAME="$2"
        shift
    ;;
    -v|--verbose)
        VERBOSE=true
        shift
    ;;
    *)
        echo "'$1' is unknown param"
    ;;
esac
shift # past argument or value
done

if [ -z $TICKET_NUMBER ]; then
   echo "ERROR: Please specify ticket number";
   ERRORS=true
else
    re='^[0-9][0-9][0-9][0-9]$'
    if ! [[ $TICKET_NUMBER =~ $re ]] ; then
        echo "ERROR: Wrong format for ticket number. Right example: 1234";
        ERRORS=true
    fi
fi

if [ -z $DOCKER_IMAGE_NAME ]; then
    echo "ERROR: Please specify docker image version";
    ERRORS=true
else
    re='^[0-9.a-z\-]+$'
    if ! [[ $DOCKER_IMAGE_NAME =~ $re ]] ; then
        echo "ERROR: Wrong format docker for image version. Right example: 2.1.8-git-sd";
        ERRORS=true
    fi
fi

if $ERRORS ; then
    exit 0;
fi
