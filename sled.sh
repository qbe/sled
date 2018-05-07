#!/bin/bash
VERSIONSTRING="SLED V 1.0.1"
if [ "$1" == "--version" ]; then echo "$VERSIONSTRING" && exit; elif [ "$1" == "--" ]; then shift; fi
find /tmp/ -maxdepth 1 -type f -name "sled:$USER:*" \! -exec fuser -s '{}' \; -delete
tmpfile=$(mktemp "/tmp/sled:$USER:tmp.XXXXXXXXXX") && exec 3<> "$tmpfile" || echo "failed to create tempfile"
editfile=$(mktemp "/tmp/sled:$USER:edit.XXXXXXXXXX") && exec 4<> "$editfile" || echo "failed to create tempfile"
if [ "$1" != "" ]; then
    cat -- "$1" >"$tmpfile"
fi
while read -r proto; do
    command=`echo "$proto" | cut -f 1 -d " "`
    line=`echo "$proto" | cut -f 1 -d " " --complement`
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
