# This script should be sourced by .bashrc or equivalent.

search_mail()
{
    mairix -t $*

    if test -n "`ls ~/mail/mairix/cur`" -o -n "`ls ~/mail/mairix/new`"; then
        mutt -f =mairix;
    fi
 }
