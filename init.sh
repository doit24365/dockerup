#!/usr/bin/env bash

if [ ! -d "$CONTAINERS_DIR_PATH" ]; then
    log "Create $CONTAINERS_DIR_PATH";
    mkdir -p "$CONTAINERS_DIR_PATH"
fi
