#!/bin/sh

count() {
    [ -e "$1" ] && printf '%s\n' "$#" || printf '%s\n' 0
}

