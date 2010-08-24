#!/bin/bash
# Based on François Cerbelle's script.
#   (DUF: [ HS ] Integration abook/remind/mutt [Was: webcalendar])

function get_addressbook_entries() {
  abook --convert --outformat allcsv --infile ~/.abook/addressbook \
    | tail -n +2 | cut -d',' -f1 | sed 's/"//g;s/ /_/g'
}

function find_feast() {
  [ -z "$1" -o -z "$2" -o -z "$3" ] && echo "find_feast: bad call" && return 1
  forename=$1
  name=`echo $2 | tr '_' ' '`
  saint=`grep -i \ $forename\$ ~/.config/remind/saints.dat \
    | sed "s/\([0-9]\+ [a-zA-Z]\{3,3\}\) \(.*\)\$/REM \1 +1 MSG %\"St.\2 ($name)%\" %b%/"`
  [ -z "$saint" ] && return 1
  echo -e $saint | sed 's/ REM/\nREM/g' >> $3
  return 0
}

TARGET_FILE=~/.remind/feastdays
TEMP1_FILE=`mktemp`
TEMP2_FILE=`mktemp`

for fullname in `get_addressbook_entries`; do
  forename=`echo $fullname | cut -d_ -f1`;

  # Look for saint in all first names
  find_feast $forename $fullname $TEMP1_FILE
  if [ $? -eq 1 ]; then
    echo "no $forename in db"
    if [ `echo $forename | grep -- -` ]; then
      for name in `echo $forename | tr '-' ' '`; do
        find_feast $name $forename $TEMP1_FILE
        [ $? -eq 1 ] && "no $name in db"
      done
    fi
  fi
done

sort -u $TEMP1_FILE > $TEMP2_FILE

cat $TEMP2_FILE \
  | sed  -n '1h;1!H;${;g;s/\(REM[^(]*(\)\([^)]*\))%" %b%.\1/\1\2, /g;p;}' \
  | sed  -n '1h;1!H;${;g;s/\(REM[^(]*(\)\([^)]*\))%" %b%.\1/\1\2, /g;p;}' \
  | sed  -n '1h;1!H;${;g;s/\(REM[^(]*(\)\([^)]*\))%" %b%.\1/\1\2, /g;p;}' \
  | sed  -n '1h;1!H;${;g;s/\(REM[^(]*(\)\([^)]*\))%" %b%.\1/\1\2, /g;p;}' \
  > $TARGET_FILE

rm $TEMP1_FILE $TEMP2_FILE
