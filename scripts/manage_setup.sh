#!/bin/bash

# .TH MANAGE_SETUP 1 "October 22, 2010"
# .SH NAME
# manage_setup.sh \- high level setup handling.
# .SH SYNOPSIS
# .B manage_setup.sh
# options
# .SH AUTHOR
# This script was written by David Soulayrol <david.soulayrol@gmail.com>.
# 
# EOD

CONFIG_HOME=`[ -n "$XDG_CONFIG_HOME" ] && echo $XDG_CONFIG_HOME || echo $HOME/.config`
DATA_HOME=`[ -n "$XDG_DATA_HOME" ] && echo $XDG_DATA_HOME || echo $HOME/.local/share`

BOLD="\033[1m"
NORM="\033[0m"

[ -n "$CONFIG_SERVER" ] || ds_trap_error "no server"
[ -e "$CONFIG_HOME" ] || ds_trap_error "configuration directory does not exist"
[ -e "$DATA_HOME" ] || ds_trap_error "data directory does not exist"

SYNC_CONTENT=""

sync_data() {
    echo -e "$BOLD* Syncing data...$NORM"
    $CONFIG_HOME/scripts/manage_data.sh sync
    echo -e "$BOLD* Syncing data... done$NORM"
}

install_data() {
    echo -e "$BOLD* Installing data...$NORM"
    $CONFIG_HOME/scripts/manage_data.sh install_all
    echo -e "$BOLD* Installing data... done$NORM"
}

update_local_data() {
    echo -e "$BOLD* Updating local data (birthdays)...$NORM"
    $CONFIG_HOME/scripts/update_birthdays.sh
    echo -e "$BOLD* Updating local data (saints)...$NORM"
    $CONFIG_HOME/scripts/update_saints_days.sh
    echo -e "$BOLD* Updating local data (remind->org)...$NORM"
    $CONFIG_HOME/scripts/remind2org.py $CONFIG_HOME/remind/org.rem $HOME/org/remind.org
    echo -e "$BOLD* Updating local data... done$NORM"
}

install_config() {
    echo -e "$BOLD* Installing config...$NORM"
    $CONFIG_HOME/scripts/manage_config.sh install
    echo -e "$BOLD* Installing config... done$NORM"
}

pull_config() {
    echo -e "$BOLD* Pulling config...$NORM"
    $CONFIG_HOME/scripts/manage_config.sh fetch
    echo -e "$BOLD* Pulling config... done$NORM"
}

push_config() {
    echo -e "$BOLD* Pushing config...$NORM"
    $CONFIG_HOME/scripts/manage_config.sh store
    echo -e "$BOLD* Pushing config... done$NORM"
}

while getopts "siuhm:pP" o; do
    case "$o" in
        h)
            cat $0 | sed '1,2d;/# EOD/Q;s/^# //g' | man -l -;;
        i)  SYNC_CONTENT=$SYNC_CONTENT"install_config;install_data;";;
        m)  MOUNT_POINT="$OPTARG";;
        p)  SYNC_CONTENT=$SYNC_CONTENT"pull_config;";;
        P)  SYNC_CONTENT=$SYNC_CONTENT"push_config;";;
        s)
            # Add it on top of list.
            SYNC_CONTENT="sync_data;"$SYNC_CONTENT;;
        u)  SYNC_CONTENT=$SYNC_CONTENT"update_local_data;";;
	[?])
            ds_trap_usage "[-s] [-i] [-h]";;
    esac
done

eval "do_sync() { $SYNC_CONTENT }"

# All functions and variables used in do_sync must be exported prior
# to call mount_server.sh
export -f \
    sync_data install_data update_local_data \
    install_config pull_config push_config \
    do_sync
export CONFIG_HOME BOLD NORM CONFIG_ACTION=do_sync

$CONFIG_HOME/scripts/mount_server.sh $MOUNT_POINT

exit 0
