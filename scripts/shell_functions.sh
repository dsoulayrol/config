# This script should be sourced by .bashrc or equivalent.

# make use of both CPU when compiling.
export MAKEFLAGS="-j`ls -1 /sys/devices/system/cpu/cpu* | wc -l`"

# dh_make environment.
export DEBEMAIL=david.soulayrol@gmail.com
export DEBFULLNAME="David Soulayrol"

# Personal environment.
export TERM=linux
export EDITOR="emacsclient -c -a emacs"
export VISUAL="emacsclient -c -a emacs"

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
