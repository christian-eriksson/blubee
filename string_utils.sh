#!/bin/sh

trim_right_slash() {
    string="$*"
    echo ${string%/}
}

trim_left_slash() {
    string="$*"
    echo ${string#/}
}

