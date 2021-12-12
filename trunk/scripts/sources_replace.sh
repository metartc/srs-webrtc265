#!/bin/bash

from=$1
to=$2

if [[ $from == '' ]]; then
    echo "replace from must not be empty"
    exit 1
fi

if [[ $to == '' ]]; then
    echo "replace to must not be empty"
    exit 1
fi

if [[ ! -d src || ! -d ide ]]; then
    echo "please execute the script under trunk"
    exit 1
fi

echo "from=$from"
echo "to=$to"

files="configure `ls auto` `ls conf` `ls scripts` `find etc -type f` `find ide -type f|grep -v xcuserdata` `find research -type f|grep -v objs` `find src -type f`"
for file in $files; do 
    grep -in "$from" $file >/dev/null 2>&1; 
    if [[ 0 -eq $? ]]; then 
        echo "replace $file"; 
        sed -i '' "s|$from|$to|g" $file; 
    fi; 
done
