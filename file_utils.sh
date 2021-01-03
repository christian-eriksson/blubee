#!/bin/sh

remove_path() {
    path="$1"
    host="$2"
    user="$3"

    if [ -z "$host" ]; then
        rm -rf $path
    else
        if [ -z "$user" ]; then
            ssh $host "rm -rf $path"
        else
            ssh $user@$host "rm -rf $path"
        fi
    fi
}

create_directory() {
    path="$1"
    host="$2"
    user="$3"

    if [ -z "$host" ]; then
        mkdir -p "$path"
    else
        if [ -z "$user" ]; then
            ssh $host "mkdir -p $path"
        else
            ssh $user@$host "mkdir -p $path"
        fi
    fi
}

create_directory_if_not_exist() {
    path="$1"
    [ ! -e "$path" ] && mkdir -p  "$path"
}

create_link() {
    target="$1"
    link_path="$2"
    host="$3"
    user="$4"

    if [ -z "$host" ]; then
        ln -s $target $link_path
    else
        if [ -z "$user" ]; then
            ssh $host "ln -s $target $link_path"
        else
            ssh $user@$host "ln -s $target $link_path"
        fi
    fi
}

test_nonexistent_link() {
    link_path="$1"
    message="$2"
    host="$3"
    user="$4"

    if [ -z "$host" ]; then
        [ ! -L $link_path ] && echo "$message"
    else
        if [ -z "$user" ]; then
            ssh $host "[ ! -L $link_path ] && echo \"$message\""
        else
            ssh $user@$host "[ ! -L $link_path ] && echo \"$message\""
        fi
    fi
}

