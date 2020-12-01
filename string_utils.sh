#!/bin/sh

trim_right_slash() {
    string="$*"
    echo ${string%/}
}

trim_left_slash() {
    string="$*"
    echo ${string#/}
}

trim_to_first_right_slash() {
    string="$*"
    while :; do
        case $string in
            */)
                break;;
            *)
                if [ -z $string ]; then
                    break
                fi
                string=${string%?};;
        esac
    done
    echo $string
}

