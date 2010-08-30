#!/bin/bash
#
# EOD


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
follow = Path \*\\
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

trap_error() {
    echo "manage_data.sh: error: $1"
    exit 1
}

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
    if [ -z "$DATA_SERVER" ]; then
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

[ -e "$DATA_HOME" ] || trap_error "data directory does not exist"
[ -x "$UNISON" ] || trap_error "unison not in path"

case "$1" in
    add)
        check_params $*
        check_profile
        ln -s $NAME $DATA_ROOT/`basename $NAME`
        echo "added $NAME to shared data"
        ;;
    remove)
        check_params $*
        check_profile
        rm $DATA_ROOT/`basename $NAME`
        echo "removed $NAME from shared data"
        ;;
    sync)
        check_no_params
        check_server
        check_profile
        $UNISON $UNISON_OPT $UNISON_PRF $DATA_ROOT $DATA_SERVER$REPOSITORY
        ;;
    list)
        check_no_params $*
        check_profile
        ls -l $DATA_ROOT
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
