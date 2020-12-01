#!/bin/sh

. ./string_utils.sh

get_json_element() {
    path="$1"
    #json=$(echo $@ | cut -d' ' -f2-)
    json="$2"
    element=$(echo "$json" | jq "$path")
    if [ "$element" = "null" ]; then
        echo ""
    else
        echo $element
    fi
}

extract_json_list() {
    json_list="$1"
    echo $(dequote_string "$(echo "$json_list" | jq 'join(" ")')")
}

get_list_item() {
    list="$1"
    index="$2"
    echo $(echo $list | jq ".[$index]")
}

list_length() {
    list="$1"
    echo $(echo $list | jq ". | length")
}

