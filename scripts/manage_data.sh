#!/bin/bash

# .TH MANAGE_DATA 1 "September 30, 2010"
# .SH NAME
# manage_data.sh \- handling replication of data files that cannot be spread.
# .SH SYNOPSIS
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
# sync
# .SM
#   Synchronize shared files between local machine and repository
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

# Many dedicated services like Dropbox provide a way of sharing
# personal data among multiple machines. However, these services often
# fail to consider any kind of file in the whole home
# directory. Moreover, their policy concerning the data they gather is
# not always crystal clear, or the tool they provide is not open
# source.
# .PP
# .B manage_data.sh
# builds on top of
# .B unison
# to provide an answer to this problem.
# It provides commands to share or unshare any file belonging to the
# user's home directory. Sharing a file will move it in a special
# directory and a symbolic link will be created in its previous
# location. After sync'ing on a new machine, the install or
# install_all commands will create these symbolic links as well for
# the files that had no previous version on the machine.
# .PP
# The sync command depends on
# .B $CONFIG_SERVER
# which is used by
# .B unison
# to locate the repository.
# .SH ENVIRONMENT
# .TP 18
# .B CONFIG_SERVER
# The server location. This value is used by
# .B unison
# and MUST be defined for sync'ing. It is considered to be remote if it
# ends with a colon, otherwise it normally should have a trailing
# slash.
# .TP
# .B HOME
# The login directory MUST be defined. It is used to locate the
# local data directory if
# .B XDG_DATA_HOME
# is not defined, the local cache directory if
# .B XDG_CACHE_HOME
# is not defined, and all the shared files.
# .TP
# .B XDG_DATA_HOME
# The directory containing the user local data, as described in XDG
# Base Directory Specification. It defaults to
# .IR $HOME/.local/share .
# Shared data handled by this script are stored in
# .IR $XDG_DATA_HOME/dist_data .
# .B unison
# also uses the
# .I $XDG_DATA_HOME/dist_data.bak
# to store previous versions of the files for conflict resolution when
# sync'ing.
# .TP
# .B XDG_CACHE_HOME
# The directory containing the user's transient data, as described in XDG
# Base Directory Specification. It defaults to
# .IR $HOME/.cache .
# .B unison
# is configured to store there its operation log.
# .SH AUTHOR
# This script was written by David Soulayrol <david.soulayrol@gmail.com>.
# 
# EOD

# NOTE: add and remove take installed names.
#       install takes shared names.

REPOSITORY="dist_data"
DATA_HOME=`[ -n "$XDG_DATA_HOME" ] && echo $XDG_DATA_HOME || echo $HOME/.local/share`
CACHE_HOME=`[ -n "$XDG_CACHE_HOME" ] && echo $XDG_CACHE_HOME || echo $HOME/.cache`
DATA_ROOT=$DATA_HOME/$REPOSITORY
DATA_BACKUP=$DATA_HOME/$REPOSITORY".bak"

UNISON="/usr/bin/unison"
UNISON_OPT=""
UNISON_PRF="dist_data.prf"

UNISON_PROFILE="\
logfile = $CACHE_HOME/$REPOSITORY.log\\
\\
# Keep a backup copy of every file in a central location\\
backuplocation = central\\
backupdir = $DATA_BACKUP\\
backup = Name \*\\
backupcurrent = Name \*\\
backupprefix = \\
backupsuffix = .\$VERSION\\
\\
merge = Name \* -> diff3 -m CURRENT1 CURRENTARCH CURRENT2 > NEW || echo ' \*\* Unresolved conflict' && exit 1\\
"

check_params() {
    if [ $# -gt 2 ]; then
        trap_error "wrong arguments. try manage_config.sh help"
    fi
    if [ $# -gt 1 ]; then
        NAME="$2"
    fi
}

check_no_params() {
    if [ $# -gt 1 ]; then
        trap_error "wrong arguments. try manage_config.sh help"
    fi
}

check_server() {
    if [ -z "$CONFIG_SERVER" ]; then
        trap_error "no server"
    fi
}

check_profile() {
    [ ! -d "$DATA_ROOT" ] && mkdir $DATA_ROOT
    [ ! -d "$DATA_BACKUP" ] && mkdir $DATA_BACKUP
    if [ ! -e ~/.unison/"$UNISON_PRF" ]; then
        mkdir -p ~/.unison
        echo $UNISON_PROFILE \
            | sed "s%\\\\\*%\\*%g;\
                   s%\\\\ %\n%g"\
            > ~/.unison/"$UNISON_PRF"
        echo "Wrote $UNISON_PRF profile"
    fi
}

get_shared_name() {
    local h=`readlink -f $HOME | tr '/' '!'`
    local p=`readlink -f $1 | tr '/' '!'`
    echo $p | sed "s/^$h//"
}

get_installed_name() {
    local p=`readlink -f $1`
    echo $HOME/`basename $p | tr '!' '/'`
}

[ -e "$DATA_HOME" ] || trap_error "data directory does not exist"
[ -x "$UNISON" ] || trap_error "unison not in path"

case "$1" in
    add)
        check_params $*
        check_profile
        if [[ "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
            trap_error "$NAME is already shared"
        fi
        SHARED_PATH=$DATA_ROOT/`get_shared_name $NAME`
        mv $NAME $SHARED_PATH
        ln -s $SHARED_PATH $NAME
        echo "added $NAME to shared data"
        ;;
    remove)
        check_params $*
        check_profile
        if [ -L "$NAME" ]; then
            if [[ "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
                rm $NAME
                mv $SHARED_PATH $NAME
                echo "removed $NAME from shared data"
                exit 0
            fi
        fi
        trap_error "$NAME is not shared"
        ;;
    sync)
        check_no_params
        check_server
        check_profile
        $UNISON $UNISON_OPT $UNISON_PRF $DATA_ROOT $CONFIG_SERVER$REPOSITORY
        ;;
    list)
        check_no_params $*
        check_profile
        ls -l $DATA_ROOT
        ;;
    install)
        check_params $*
        check_profile
        if [[ ! "`readlink -f $NAME`" =~ "$DATA_ROOT" ]]; then
            trap_error "$NAME is not shared"
        fi
        INSTALLED_PATH=`get_installed_name $NAME`
        if [ -e "$INSTALLED_PATH" ]; then
            trap_error "$INSTALLED_PATH already exists"
        fi
        ln -s `readlink -f $NAME` $INSTALLED_PATH
        echo "installed $INSTALLED_PATH"
        ;;
    install_all)
        check_no_params
        check_profile
        for f in `ls $DATA_ROOT`; do
            INSTALLED_PATH=`get_installed_name $DATA_ROOT/$f`
            if [ -e "$INSTALLED_PATH" ]; then
                echo "skipping $INSTALLED_PATH"
                continue
            fi
            ln -s $DATA_ROOT/$f $INSTALLED_PATH
            echo "installed $INSTALLED_PATH"
        done
        ;;
    help)
        cat $0 | sed '1,2d;/# EOD/Q;s/^# //g' | man -l -
        ;;
    *)
        echo "manage_data.sh: error: wrong arguments. try manage_data.sh help"
        exit 1
        ;;
esac

exit 0
