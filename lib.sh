#!/usr/bin/env bash

function log {
    if $VERBOSE; then
        echo $1;
    fi;
}