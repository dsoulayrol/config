#!/bin/bash

# .TH MANAGE_CONFIG 1 "August 18, 2010"
# .SH NAME
# manage_config.sh \- handling configuration files that cannot be spread.
# .SH SYNOPSIS
# .B manage_config.sh
# fetch
# .RI [ name ]
# .SM
#   Retrieve the configuration stored for name
# .PP
# .B manage_config.sh
# store
# .RI [ name ]
# .SM
#   Store the current configuration as name
# .PP
# .B manage_config.sh
# list
# .SM
#   List the names of the stored configurations
# .PP
# .B manage_config.sh
# diff
# .RI [ name ]
# .SM
#   Display diff between the current config and the one store for name
# .PP
# .B manage_config.sh
# install
# .SM
#   install symbolic links (should follow a fetch)
# .PP
# .B manage_config.sh
# uninstall
# .SM
#   remove symbolic links.
# .SH DESCRIPTION
# Revision control systems are a nice way to keep configuration files
# in a repository so as to share the same environment on more than one
# machine. However, some files must be rewritten on each machine,
# because of contraints (eg. work environment), authentication data,
# slight differences in machines use. Those files should not be kept
# in a revision control system, however it is often useful to share
# them among the machines so as to propagate a modification, or to
# build a new configuration using the one from another machine.
# .PP
# .B manage_config.sh
# builds on top of
# .B rsync
# to provide a way to store those specific files. Each setup is
# identified by a local name which defaults to
# .I hostname_login
# , where the host name is read from
# .B hostname
# output, and the login deduced from
# .RB $ HOME .
# Setups can be fetched or stored using a name, and it is possible to
# view a diff between the local configuration and another one from the
# repository.
# .PP
# This script is aimed at working on configuration files stored under
# .RB $ XDG_CONFIG_HOME
# or
# .I $HOME/.config
# by default, hereafter named the user-specific configuration
# directory. A setup is described by a list of files and directories
# stored in
# .IR $XDG_CONFIG_HOME/.local .
# Paths written in this file must be relative to the user-specific
# configuration directory.
# .PP
# Programs that do not obey to XDG Base Directory Specification often
# read their configuration from the home directory. The install
# command will install symbolic links for these programs, using the
# .IR $XDG_CONFIG_HOME/.links .
# .PP
# All the commands but install uninstall depend on
# .B $CONFIG_SERVER
# which is used by
# .B rsync
# to locate the repository.
# .SH ENVIRONMENT
# .TP 18
# .B CONFIG_SERVER
# The server location. This value is used by
# .B rsync
# and MUST be defined. It is considered to be remote if it ends with a
# colon, otherwise it normally should have a trailing slash.
# .TP
# .B HOME
# The login directory MUST be defined. It is used to set the
# user-specific configuration name, to locate the local configuration
# directory if
# .B XDG_CONFIG_HOME
# is not defined, and to setup symbolic links.
# .TP
# .B XDG_CONFIG_HOME
# The single base directory relative to which user-specific
# configuration files should be written, as described in XDG Base
# Directory Specification.
# .SH FILES
# .TP
# .I $XDG_CONFIG_HOME/.local
# The list of files to handle. Each line must be a path to a file or a
# directory. In the case of directories, its whole content will be
# stored.  Paths must be relative to
# .IR $XDG_CONFIG_HOME .
# .TP
# .I $XDG_CONFIG_HOME/.links
# The description of symbolic links needed by some programs. Each line
# of this file must be composed of the name of the link to be created in
# .I $HOME/
# and the name of the target file or directory, separated by a colon.
# .SH EXAMPLES
# Consider a mail setup using
# .B offlineimap
# ,
# .B imapfilter
# and
# .B mutt
# as the MUA. This setup is installed on an office machine and on a
# personal desktop. The office configuration handles an additional
# mailbox for work, with its own filtering rules, its own aliases, and
# doesn't host a whole copy of the personal mail. However, the
# configuration for
# .B muttprint
# is the same on both machines.
# .PP
# Here is a
# .I $XDG_CONFIG_HOME/.local
# example to take care of this.
# .RS
# \f(CWofflineimap/offlineimaprc\fP
# .br
# \f(CWimapfilter/config.lua\fP
# .br
# \f(CWmutt/accounts/\fP
# .br
# \f(CWmutt/local-aliases\fp
# .RE
# .PP
# Here is a
# .I $XDG_CONFIG_HOME/.links
# example to setup the symbolic links needed by those programs which
# ignore XDG standard paths. Note how
# .I muttprintrc
# is handled here but not listed in the stored files since it is not
# personalized.
# .RS
# \f(CW.offlineimaprc:offlineimap/offlineimaprc\fp
# .br
# \f(CW.imapfilter:imapfilter/\fp
# .br
# \f(CW.mutt:mutt/\fp
# .br
# \f(CW.muttprintrc:mutt/muttprintrc\fp
# .RE

# .SH AUTHOR
# This script was written by David Soulayrol <david.soulayrol@gmail.com>.
# 
# EOD

# TODO:
# * Add a way to plug shell functions and variables in .bashrc
#

FILES=".local"
LINKS=".links"
NAME=`hostname -s`_`basename $HOME`

CONFIG_DIR=`[ -n "$XDG_CONFIG_HOME" ] && echo $XDG_CONFIG_HOME || echo $HOME/.config`
REPOSITORY="configs/"

RSYNC="/usr/bin/rsync"
RSYNC_OPT="-ctur"

[ -e "$CONFIG_DIR" ] || exit 1
[ -x "$RSYNC" ] || exit 1


check_params() {
    if [ $# -gt 2 ]; then
        echo "manage_config.sh: error: wrong arguments. try manage_config.sh help"
        exit 1
    fi
    if [ $# -gt 1 ]; then
        NAME="$2"
    fi
}

check_no_params() {
    if [ $# -gt 1 ]; then
        echo "manage_config.sh: error: wrong arguments. try manage_config.sh help"
        exit 1
    fi
}

check_server() {
    if [ -z "$CONFIG_SERVER" ]; then
        echo "manage_config.sh: error: no server"
        exit 1
    fi
}

build_local_files_list() {
    LIST_FILE=`mktemp`
    if [ -f "$CONFIG_DIR/$FILES" ]; then
        cp $CONFIG_DIR/$FILES $LIST_FILE
        echo $FILES >> $LIST_FILE
    fi
    if [ -f "$CONFIG_DIR/$LINKS" ]; then
        echo $LINKS >> $LIST_FILE
    fi
    echo $LIST_FILE
}

hide_local_files() {
    GIT_EXCLUDE_FILE="$CONFIG_DIR/.git/info/exclude"
    if [ -f "$GIT_EXCLUDE_FILE" ]; then
        TEMP_LIST=`build_local_files_list`
        TEMP_FILE=`mktemp`
        cp $GIT_EXCLUDE_FILE $TEMP_FILE
        sed '/# BEGIN_LOCAL_CONFIG/,/# END_LOCAL_CONFIG/d' \
            $TEMP_FILE > $GIT_EXCLUDE_FILE
        echo "# BEGIN_LOCAL_CONFIG" >> $GIT_EXCLUDE_FILE
        cat $TEMP_LIST >> "$GIT_EXCLUDE_FILE"
        echo "# END_LOCAL_CONFIG" >> $GIT_EXCLUDE_FILE
        rm $TEMP_LIST
        rm $TEMP_FILE
    fi
}

case "$1" in
    fetch)
        check_params $*
        check_server
        $RSYNC $RSYNC_OPT \
            $CONFIG_SERVER$REPOSITORY$NAME/ $CONFIG_DIR
        hide_local_files
        echo "fetched $NAME from $CONFIG_SERVER"
        ;;
    store)
        check_params $*
        check_server
        TEMP_LIST=`build_local_files_list`
        $RSYNC $RSYNC_OPT --delete --files-from $TEMP_LIST \
            $CONFIG_DIR $CONFIG_SERVER$REPOSITORY$NAME
        rm $TEMP_LIST
        hide_local_files
        echo "stored $NAME on $CONFIG_SERVER"
        ;;
    diff)
        check_params $*
        check_server
        TEMP_LIST=`build_local_files_list`
        TEMP_DIR=`mktemp -d`
        $RSYNC $RSYNC_OPT -r \
            $CONFIG_SERVER$REPOSITORY$NAME/ $TEMP_DIR/other
        mkdir $TEMP_DIR/mine
        cd $CONFIG_DIR
        cp -r --parents `cat $TEMP_LIST` $TEMP_DIR/mine
        cd $OLDPWD
        diff -urwN $TEMP_DIR/mine $TEMP_DIR/other
        rm $TEMP_LIST
        rm -rf $TEMP_DIR
        ;;
    list)
        check_no_params $*
        check_server
        $RSYNC $CONFIG_SERVER$REPOSITORY | sed '1d;s/^.* //g'
        ;;
    install)
        check_no_params $*
        if [ -f "$CONFIG_DIR/$LINKS" ]; then
            for line in `cat $CONFIG_DIR/$LINKS`; do
                link=$HOME/`echo $line | sed 's/:.*$//'`
                src=$CONFIG_DIR/`echo $line | sed 's/^.*://'`
                if [ ! -e "$src" ]; then
                    echo "  skipping missing source: $src"
                elif [ -e "$link" -a ! -L "$link" ]; then
                    echo "  skipping static target: $link"
                else
                    echo "  linking $link to $src"
                    rm -f $link
                    ln -s $src $link
                fi
            done
        fi
        ;;
    uninstall)
        check_no_params $*
        if [ -f "$CONFIG_DIR/$LINKS" ]; then
            for line in `cat $CONFIG_DIR/$LINKS`; do
                link=$HOME/`echo $line | sed 's/:.*$//'`
                if [ ! -L "$link" ]; then
                    echo "  skipping static target: $link"
                else
                    echo "  removing $link"
                    rm -f $link
                fi
            done
        fi
        ;;
    help)
        cat $0 | sed '1,2d;/# EOD/Q;s/^# //g' | man -l -
        ;;
    *)
        echo "manage_config.sh: error: wrong arguments. try manage_config.sh help"
        exit 1
        ;;
esac

exit 0
