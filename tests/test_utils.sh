#!/bin/sh

get_a_backup_datetime() {
    backup_path="$(trim_right_slash $1)"
    for dir in $backup_path/*/; do
        [ -d "$dir" ] || continue
        dir_no_slash="$(trim_right_slash "$dir")"
        dir_name="$(get_path_name "$dir_no_slash")"
        if [ "$dir_name" != "latest" ]; then
            datetime="$dir_name"
        fi
    done
    echo "$datetime"
}

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

assert_dirs_equal() {
    directory_one="$1"
    directory_two="$2"
    diff -r "$directory_one" "$directory_two" > /dev/null
    echo "$?"
}

assert_not_equal() {
    value_one="$1"
    value_two="$2"
    [ "$value_one" -ne "$value_two" ]
    echo "$?"
}

assert_files_in_dir() {
    directory="$1"
    expected_count="$2"
    file_count=$(count $directory/*)
    [ "$file_count" -eq "$expected_count" ]
    echo "$?"
}

assert_datetime_dir_count() {
    directory="$1"
    expected_count="$2"
    date_dir_count=$(find "$directory" -maxdepth 1 -type d | grep -e "[0-9]\{8\}_[0-9]\{6\}$" | wc -l)
    [ "$date_dir_count" -eq "$expected_count" ]
    echo "$?"
}

assert_is_link() {
    directory="$1"
    [ -L "$directory" ]
    echo "$?"
}

assert_dir_exists() {
    directory="$1"
    [ -d "$directory" ]
    echo "$?"
}

assert_no_path() {
    path="$1"
    [ ! -e "$path" ]
    echo "$?"
}

assert_empty_string() {
    string="$1"
    if [ -z "$string" ]; then
        echo "0"
    else
        echo "1"
    fi
}

assert_non_empty_string() {
    string="$1"
    if [ -z "$string" ]; then
        echo "1"
    else
        echo "0"
    fi
}

