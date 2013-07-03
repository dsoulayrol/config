# This script should be sourced by .bashrc or equivalent.

# optimize the use of CPU when compiling.
export MAKEFLAGS="-j`ls -1d /sys/devices/system/cpu/cpu? | wc -l`"

# Personal environment.
export TERM=linux
export EDITOR="emacsclient -c -a emacs"
export VISUAL="emacsclient -c -a emacs"

if [ -d ~/.config/scripts ] ; then
    PATH=~/.config/scripts:"${PATH}"
fi
export PATH

# generic way of reporting errors for configuration scripts
ds_trap_error() {
    echo `basename $0`": error: $1"
    exit 1
}

ds_trap_usage() {
    echo "usage: "`basename $0`" $1"
    exit 1
}

ds_display_help() {
    cat $0 | sed '1,2d;/# EOD/Q;s/^# //g' | man -l -
}

# open mutt on a mairix search results
search_mail() {
    mairix -t $*

    if test -n "`ls ~/mail/mairix/cur`" -o -n "`ls ~/mail/mairix/new`"; then
        mutt -f =mairix;
    fi
 }

# make svn diff more friendly
svndiff () {
    svn diff -x -w "${@}" | colordiff | less -R
}

# http://chris-lamb.co.uk/2010/04/22/locating-source-any-python-module/
cdp () {
    cd "$(python -c "import os.path as _, ${1}; \
        print _.dirname(_.realpath(${1}.__file__[:-1]))"
  )"
}

# Load all these macros when called non-interactively.
export BASH_ENV="~/.config/scripts/shell_functions.sh"
