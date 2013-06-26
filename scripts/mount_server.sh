#!/bin/bash

# A helper for manage_setup.sh and manage_data.sh using sshfs.

on_exit() {
    popd > /dev/null
    fusermount -u $MOUNT_POINT
    rmdir $MOUNT_POINT
}

set_mount_point() {
    MOUNT_POINT=$1
    if [ -e "$MOUNT_POINT" ]; then
        ds_trap_error "mount point ($MOUNT_POINT) is not free."
    fi
    mkdir $MOUNT_POINT
}

if [ $# -eq 0 ]; then
    [ -n "$CONFIG_SERVER" ] || ds_trap_error "set CONFIG_SERVER or specify locations"
    REMOTE_PATH=$CONFIG_SERVER
    MOUNT_POINT=`mktemp -d --suffix=_$CONFIG_SERVER`
elif [ $# -eq 1 ]; then
    [ -n "$CONFIG_SERVER" ] || ds_trap_error "set CONFIG_SERVER or specify locations"
    REMOTE_PATH=$CONFIG_SERVER
    set_mount_point $1
elif [ $# -eq 2 ]; then
    REMOTE_PATH=$2
    set_mount_point $1
else
    ds_trap_usage "mount_point [server]"
fi

if [ ! -d "$MOUNT_POINT" ]; then
    ds_trap_error "failed to create mount point ($MOUNT_POINT)."
fi

sshfs $REMOTE_PATH $MOUNT_POINT

if [ $? -ne 0 ]; then
    rmdir $MOUNT_POINT
    ds_trap_error "ssh mounting failed."
fi

trap on_exit EXIT

export CONFIG_SERVER=$MOUNT_POINT/
pushd $MOUNT_POINT > /dev/null

if [ -z "$CONFIG_ACTION" ]; then
    PS1="[server:$MOUNT_POINT] $PS1" bash --norc
else
    $CONFIG_ACTION
fi

