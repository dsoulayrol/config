#!/bin/bash

# .TH MANAGE_DATA 1 "June 26, 2013"
# .SH NAME
# manage_data.sh \- handling data shared among machines.
# .SH SYNOPSIS
# .B manage_data.sh
# mount
# .SM
#   Mount the distant directoy using a DAV channel
# .PP
# .B manage_data.sh
# umount
# .SM
#   Unmount the distant directoy
# .PP
# .B manage_data.sh
# add
# .RI [ name ]
# .SM
#   Share the given file
# .PP
# .B manage_data.sh
# remove
# .RI [ name ]
# .SM
#   Stop sharing of the given file
# .PP
# .B manage_data.sh
# install
# .RI [ name ]
# .SM
#   Install a symbolic link for the given shared path
# .PP
# .B manage_data.sh
# install_all
# .SM
#   Install symbolic links for all the shared paths
# .SH DESCRIPTION

# Nowadays, data which needs to be shared is quite easily stored in
# what's called the cloud. More precisely, on a server somewhere on
# the Internet. Most of the data now is accessed using a specific API
# (think calendar, contacts or mail). But there can still be some
# files that need to be shared among machines and are not handled by a
# specific API.
# .PP
# Many dedicated services like Dropbox provide a way of sharing
# personal data among multiple machines. However, these services often
# fail to consider any kind of file in the whole home directory.
# Moreover, their policy concerning the data they gather is not always
# crystal clear, or the tool they provide is not open source.
# .PP
# .B manage_data.sh
# provides commands to share or unshare any file belonging to the
# user's home directory. Sharing a file will move it in a special
# directory and a symbolic link will be created in its previous
# location. This special directoy is shared using a DAV channel with
# the help of
# .BR fusedav .
# .PP
# The install or install_all commands, contrariwise, will create these
# symbolic links for the files present in the shared directory and
# that did not exist in the user's home directory.
# .SH ENVIRONMENT
# .TP 18
# .B HOME
# The login directory MUST be defined. It is used to locate the
# local data directory if
# .B XDG_DATA_HOME
# is not defined, and all the shared files.
# .TP
# .B XDG_DATA_HOME
# The directory containing the user local data, as described in XDG
# Base Directory Specification. It defaults to
# .IR $HOME/.local/share .
# Shared data handled by this script are stored in
# .IR $XDG_DATA_HOME/dist_data .
# .TP
# .B XDG_CACHE_HOME
# This directory is used to stored the PID from the fusedav process
# when a distant directory is mounted.
# .SH HISTORY
# This command used to rely on a synchronisation mechanism using
# .BR unison .
# However, since only few data now remains to be shared manually, and
# with the development of web services like the ones provided by
# OwnCloud, mounting a webDAV repository became the easiest solution.
# Futhermore, it kills the need to handle clean three-way merges
# between a local copy and the shared distant version.
# .SH SEE ALSO
# .B manage_config.sh
# .SH AUTHOR
# This script was written by David Soulayrol <david.soulayrol@gmail.com>.
# 
# EOD

DATA_HOME=`[ -n "$XDG_DATA_HOME" ] && echo $XDG_DATA_HOME || echo $HOME/.local/share`
CACHE_HOME=`[ -n "$XDG_CACHE_HOME" ] && echo $XDG_CACHE_HOME || echo $HOME/.cache`
DAV_MOUNTPOINT="$DATA_HOME/owncloud/"
DAV_PIDFILE="$CACHE_HOME/manage_data_fusedav.pid"
DATA_ROOT="$DAV_MOUNTPOINT/shared_data"

FUSEDAV="/usr/bin/fusedav"

check_params() {
    if [ $# -gt 2 ]; then
        ds_trap_error "wrong arguments. try manage_data.sh help"
    fi
    if [ $# -gt 1 ]; then
        NAME="$2"
    fi
}

check_no_params() {
    if [ $# -gt 1 ]; then
        ds_trap_error "wrong arguments. try manage_date.sh help"
    fi
}

get_shared_name() {
    local h=`readlink -f $HOME`
    local p=`readlink -f $1`
    echo $p | sed "s,^$h,,"
}

get_installed_name() {
    local r=`readlink -f $DATA_ROOT`
    local p=`readlink -f $1 | sed "s,^$r,,"`
    echo $HOME$p
}

[ -e "$DATA_HOME" ] || ds_trap_error "data directory does not exist"
[ -e "$CACHE_HOME" ] || ds_trap_error "cache directory does not exist"

case "$1" in
    add)
        check_params $*
        if [[ "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
            ds_trap_error "$NAME is already shared"
        fi
        shared_path=$DATA_ROOT/`get_shared_name $NAME`
        mkdir -p $shared_path/`dirname $shared_path`
        mv $NAME $shared_path
        ln -s $shared_path $NAME
        echo "added $NAME to shared data"
        ;;
    remove)
        check_params $*
        if [ -L "$NAME" ]; then
            if [[ "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
                shared_path=$DATA_ROOT/`get_shared_name $NAME`
                rm $NAME
                mv $shared_path $NAME
                echo "removed $NAME from shared data"
                exit 0
            fi
        fi
        ds_trap_error "$NAME is not shared"
        ;;
    mount)
        check_no_params $*
        [ -x "$FUSEDAV" ] || ds_trap_error "fusedav not in path"
        [ -z "$DATA_SERVER" ] && ds_trap_error "no server"
        [ -f "$DAV_PIDFILE" ] && ds_trap_error "data already mounted."
        user=`[ -n "$DATA_SERVER_USERNAME" ] && echo $DATA_SERVER_USERNAME || echo $USER`
        echo -n "Password for $user > " && read -s passwd && echo
        mkdir -p "$DAV_MOUNTPOINT"
        $FUSEDAV -u "$user" -p "$passwd" "$DATA_SERVER" "$DAV_MOUNTPOINT" &
        if [ $? ]; then echo $! > $DAV_PIDFILE; fi
        ;;
    umount)
        check_no_params $*
        if [ -f "$DAV_PIDFILE" ]; then
            kill `cat $DAV_PIDFILE`
            rm $DAV_PIDFILE
            rmdir "$DAV_MOUNTPOINT"
        fi
        ;;
    install)
        check_params $*
        if [[ ! "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
            ds_trap_error "$NAME is not shared"
        fi
        installed_path=`get_installed_name $NAME`
        if [ -e "$installed_path" ]; then
            ds_trap_error "$installed_path already exists"
        fi
        ln -s `readlink -f $NAME` $installed_path
        echo "installed $installed_path"
        ;;
    install_all)
        check_no_params $*
        for f in `find $DATA_ROOT/`; do
            installed_path=`get_installed_name $f`
            if [ -e "$installed_path" ]; then
                echo "skipping $installed_path"
                continue
            fi
            ln -s `readlink -f $f` $installed_path
            echo "installed $installed_path"
        done
        ;;
    help)
        ds_display_help
        ;;
    *)
        ds_trap_error "wrong arguments. try manage_data.sh help"
        exit 1
        ;;
esac

exit 0
