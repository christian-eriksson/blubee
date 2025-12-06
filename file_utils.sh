#!/bin/sh

remove_path() {
    path="$1"
    host="$2"
    user="$3"
    port="$4"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        rm -rf "$path"
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "rm -rf \"$path\""
        else
            ssh $port_flag $user@$host "rm -rf \"$path\""
        fi
    fi
}

create_directory() {
    path="$1"
    host="$2"
    user="$3"
    port="$4"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        mkdir -p "$path"
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "mkdir -p \"$path\""
        else
            ssh $port_flag $user@$host "mkdir -p \"$path\""
        fi
    fi
}

create_link() {
    target="$1"
    link_path="$2"
    host="$3"
    user="$4"
    port="$5"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        ln -s "$target" "$link_path"
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "ln -s \"$target\" \"$link_path\""
        else
            ssh $port_flag $user@$host "ln -s \"$target\" \"$link_path\""
        fi
    fi
}

test_nonexistent_link() {
    link_path="$1"
    message="$2"
    host="$3"
    user="$4"
    port="$5"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        [ ! -L $link_path ] && echo "$message"
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "[ ! -L \"$link_path\" ] && echo \"$message\""
        else
            ssh $port_flag $user@$host "[ ! -L \"$link_path\" ] && echo \"$message\""
        fi
    fi
}

directory_exists() {
    path="$1"
    host="$2"
    user="$3"
    port="$4"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        [ -d "$path" ]
        return $?
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "[ -d \"$path\" ]"
            return $?
        else
            ssh $port_flag $user@$host "[ -d \"$path\" ]"
            return $?
        fi
    fi
}

