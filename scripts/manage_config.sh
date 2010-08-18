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
# directory. A setup is described by a list of files stored in
# .IR $XDG_CONFIG_HOME/.local .
# Paths written in this file must be relative to the user-specific
# configuration directory.
# .PP
# However, programs that do not obey to XDG Base Directory
# Specification often read their configuration from the home
# directory. The install command will install symbolic links for these
# programs, using the
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
# colon.
# .TP
# .B XDG_CONFIG_HOME
# The single base directory relative to which user-specific
# configuration files should be written, as described in XDG Base
# Directory Specification.
# .TP
# .B HOME
# The login directory MUST be defined. It is used to set the default
# local configuration name, to locate the local configuration
# directory if
# .B XDG_CONFIG_HOME
# is not defined, and to setup symbolic links.
# .SH FILES
# .TP
# .I $HOME/.config/.local
# The list of files to handle. Paths must be relative to the
# .I $HOME/.config
# directory.
# .TP
# .I $HOME/.config/.links
# The description of symbolic links needed be some programs. Each line
# of this file is composed of the name of the link to be created in
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
# .I $HOME/.config/.local
# example to take care of this.
# .RS
# \f(CWofflineimap/offlineimaprc\fP
# .br
# \f(CWimapfilter/config.lua\fP
# .br
# \f(CWmutt/local-accounts\fp
# .br
# \f(CWmutt/local-aliases\fp
# .RE
# .PP
# Here is a
# .I $HOME/.config/.links
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


FILES=".local"
LINKS=".links"
NAME=`hostname -s`_`basename $HOME`

CONFIG_DIR=`[ -n "$XDG_CONFIG_HOME" ] && echo $XDG_CONFIG_HOME || echo $HOME/.config`
TEMP_DIR="/tmp/tmp_config"
REPOSITORY="configs/"

RSYNC="/usr/bin/rsync"
RSYNC_OPT="-ctur"

[ -x "$RSYNC" ] || exit 1


check_params() {
    if [ $# -gt 2 ]; then
        echo "manage_config.sh: error: wrong arguments. try manage_config.sh help"
        exit 1
    fi
    if [ $# -gt 1 ]; then
        NAME="$2"
    fi
    if [ -z "$CONFIG_SERVER" ]; then
        echo "manage_config.sh: error: no server"
        exit 1
    fi
    echo "Using $NAME on $CONFIG_SERVER"
}

check_no_params() {
    if [ $# -gt 1 ]; then
        echo "manage_config.sh: error: wrong arguments. try manage_config.sh help"
        exit 1
    fi
}

case "$1" in
    fetch)
        check_params $*
        $RSYNC $RSYNC_OPT -r \
            $CONFIG_SERVER$REPOSITORY$NAME/ $CONFIG_DIR
        ;;
    store)
        check_params $*
        $RSYNC $RSYNC_OPT --files-from $CONFIG_DIR/$FILES \
            $CONFIG_DIR $CONFIG_SERVER$REPOSITORY$NAME
        ;;
    diff)
        check_params $*
        $RSYNC $RSYNC_OPT -r \
            $CONFIG_SERVER$REPOSITORY$NAME/ $TEMP_DIR
        for f in `cat $CONFIG_DIR/$FILES`; do
            if [ ! -e $CONFIG_DIR/$f ]; then
                echo "$f does not exist in current configuration"
            elif [ ! -e $TEMP_DIR/$f ]; then
                echo "$f does not exist in $NAME"
            else
                diff -u $CONFIG_DIR/$f $TEMP_DIR/$f
            fi
        done
        rm -rf $TEMP_DIR
        ;;
    list)
        check_no_params $*
        $RSYNC $CONFIG_SERVER$REPOSITORY | sed '1d;s/^.* //g'
        ;;
    install)
        check_no_params $*
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
        ;;
    uninstall)
        check_no_params $*
        for line in `cat $CONFIG_DIR/$LINKS`; do
            link=$HOME/`echo $line | sed 's/:.*$//'`
            if [ ! -L "$link" ]; then
                echo "  skipping static target: $link"
            else
                echo "  removing $link"
                rm -f $link
            fi
        done
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
