#!/bin/bash

# A helper for manage_config.sh and manage_data.sh using sshfs.

trap_usage() {
    echo "usage: $0 mount_point remote"
    exit 1
}

trap_error() {
    echo "$0: error: $1"
    exit 1
}

on_exit() {
    fusermount -u $MOUNT_POINT
    rmdir $MOUNT_POINT
}

if [ $# -ne 2 ]; then
    trap_usage
fi

MOUNT_POINT=$1
REMOTE_PATH=$2

if [ -e "$MOUNT_POINT" ]; then
    trap_error "mount point ($MOUNT_POINT) is not free."
fi

mkdir $MOUNT_POINT

if [ ! -d "$MOUNT_POINT" ]; then
    trap_error "failed to create mount point ($MOUNT_POINT)."
fi

sshfs $REMOTE_PATH $MOUNT_POINT

if [ $? -ne 0 ]; then
    rmdir $MOUNT_POINT
    trap_error "ssh mounting failed."
fi

trap on_exit EXIT

export CONFIG_SERVER=$MOUNT_POINT/
export DATA_SERVER=$MOUNT_POINT/
PS1="[server:$MOUNT_POINT] $PS1" bash --norc
