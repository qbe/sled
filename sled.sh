#!/bin/bash
VERSIONSTRING="SLED V 1.0.1"
#update VERSIONSTRING for release commits

if [ "$1" == "--version" ]; then echo "$VERSIONSTRING" && exit; elif [ "$1" == "--" ]; then shift; fi
#minimal POSIX compliance code

find /tmp/ -maxdepth 1 -type f -name "sled:$USER:*" \! -exec fuser -s '{}' \; -delete
#removes every sled tempfile not currently used by any process

tmpfile=$(mktemp "/tmp/sled:$USER:tmp.XXXXXXXXXX") && exec 3<> "$tmpfile" || echo "failed to create tempfile"
editfile=$(mktemp "/tmp/sled:$USER:edit.XXXXXXXXXX") && exec 4<> "$editfile" || echo "failed to create tempfile"
#creates necessary tempfiles and opens permanent file descriptors to them to protect them

if [ "$1" != "" ]; then
    cat -- "$1" >"$tmpfile"
fi
#the first non-option argument is read in as a file into the primary buffer

while read -r proto; do
    command=`echo "$proto" | cut -f 1 -d " "`
    line=`echo "$proto" | cut -f 1 -d " " --complement`
    #does not use a 'IFS=" " read -r command line' construct to enable indented input

    if [ "$command" == "show" ]; then
        cat -n "$tmpfile" | more +"$line"
    elif [ ! -z "${command##*[!0-9]*}" ]; then
        cat "$tmpfile" | head -n $(expr "$command" - 1) >"$editfile"
        echo "$line" >>"$editfile"
        cat "$tmpfile" | tail -n +"$command" >>"$editfile"
        cat "$editfile" >"$tmpfile"
    elif [ "$command" == "write" ]; then
        if [ "$line" != "" ]; then
            cat "$tmpfile" >"${line/#\~/$HOME}"
        elif [ "$1" != "" ]; then
            cat "$tmpfile" >"$1"
        else
            while [ "$line" == "" ]; do
               echo "write where ? :"
                read -r line;
            done
            cat "$tmpfile" >"${line/#\~/$HOME}"
        fi
    elif [ "$command" == "append" ]; then
        echo "$line" | tee >>"$tmpfile"
    elif [ "$command" == "delete" ]; then
        while ! [ "$line" -eq "$line" ]; do
            echo "delete what ? :"
        done
        cat "$tmpfile" | head -n $(expr "$line" - 1) >"$editfile"
        cat "$tmpfile" | tail -n +$(expr "$line" + 1) >>"$editfile"
        cat "$editfile" >"$tmpfile"
    else
        while [ "$line" == "" ]; do
            echo "$command _ ?"
            read -r line
        done
        if [ "$command" == "open" ]; then
            cat -- "${line/#\~/$HOME}" >"$tmpfile"
        elif [ "$command" == "first" ]; then
            cat -n "$tmpfile" | head -n "$line" | more
        elif [ "$command" == "last" ]; then
            cat -n "$tmpfile" | tail -n "$line" | more
        fi
    fi
done

exec 3>&- && exec 4>&- && find /tmp/ -maxdepth 1 -type f -name "sled:$USER:*" \! -exec fuser -s '{}' \; -delete
#closes the protective file descriptors and repeats the deletion procedure
