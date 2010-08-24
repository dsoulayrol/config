#!/bin/bash
# Based on François Cerbelle's script.
#   (DUF: [ HS ] Integration abook/remind/mutt [Was: webcalendar])

SED_TR_MONTHS='
s/^\(REM [0-9]\+ \)0\?1 /\1Jan /g
s/^\(REM [0-9]\+ \)0\?2 /\1Feb /g
s/^\(REM [0-9]\+ \)0\?3 /\1Mar /g
s/^\(REM [0-9]\+ \)0\?4 /\1Apr /g
s/^\(REM [0-9]\+ \)0\?5 /\1May /g
s/^\(REM [0-9]\+ \)0\?6 /\1Jun /g
s/^\(REM [0-9]\+ \)0\?7 /\1Jul /g
s/^\(REM [0-9]\+ \)0\?8 /\1Aug /g
s/^\(REM [0-9]\+ \)0\?9 /\1Sep /g
s/^\(REM [0-9]\+ \)10 /\1Oct /g
s/^\(REM [0-9]\+ \)11 /\1Nov /g
s/^\(REM [0-9]\+ \)12 /\1Dec /g
'

abook --convert --outformat allcsv --infile ~/.abook/addressbook \
  | sed 's/"//g' \
  | cut -d"," -f1,17 \
  | sed 's#\([^,]*\),\([0-9]*\)/\([0-9]*\)/\([0-9]*\)#REM \2 \3 ++12 MSG %"[_yr_age(\4)] ans de \1%" (%b)%#g' \
  | grep '^REM [0-9]' \
  | sed "$SED_TR_MONTHS" \
> ~/.remind/birthdays
