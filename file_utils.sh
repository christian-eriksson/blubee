#!/bin/sh

remove_path() {
    path="$1"
    host="$2"
    user="$3"
    port="$4"

    [ -n "$port" ] && port_flag="-p$port"

    if [ -z "$host" ]; then
        rm -rf "$path"
        return_code=$?
        if [ "$return_code" -ne "0" ]; then
            echo "Failed to remove local directory: $path. Failed with return code $return_code"
            return 31
        fi
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "rm -rf \"$path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to remove remote directory on $host: $path. Failed with return code $return_code"
                return 32
            fi
        else
            ssh $port_flag $user@$host "rm -rf \"$path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to remove remote directory on $host as $user: $path. Failed with return code $return_code"
                return 33
            fi
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
        return_code=$?
        if [ "$return_code" -ne "0" ]; then
            echo "Failed to create local directory: $path. Failed with return code $return_code"
            return 41
        fi
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "mkdir -p \"$path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to create remote directory on $host: $path. Failed with return code $return_code"
                return 42
            fi
        else
            ssh $port_flag $user@$host "mkdir -p \"$path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to create remote directory on $host as $user: $path. Failed with return code $return_code"
                return 43
            fi
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
        return_code=$?
        if [ "$return_code" -ne "0" ]; then
            echo "Failed to create local link: $path. Failed with return code $return_code"
            return 51
        fi
    else
        if [ -z "$user" ]; then
            ssh $port_flag $host "ln -s \"$target\" \"$link_path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to create remote link on $host: $path. Failed with return code $return_code"
                return 52
            fi
        else
            ssh $port_flag $user@$host "ln -s \"$target\" \"$link_path\""
            return_code=$?
            if [ "$return_code" -ne "0" ]; then
                echo "Failed to create remote link on $host as $user: $path. Failed with return code $return_code"
                return 53
            fi
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

