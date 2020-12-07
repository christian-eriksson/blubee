#!/bin/sh

count() {
    [ -e "$1" ] && printf '%s\n' "$#" || printf '%s\n' 0
}

get_result_text() {
    if [ "$1" -eq "0" ]; then
        echo "PASS"
    else
        echo "FAIL"
    fi
}

asserts_to_text() {
    results="$1"
    result_text=""
    for result in $results; do
         echo $(get_result_text $result)
    done
}

