#!/bin/sh

script_dir="${0%/*}"

. $script_dir/string_utils.sh
. $script_dir/file_utils.sh
. $script_dir/json_utils.sh

while getopts ":s:d:r:xh:u:" option; do
    case "${option}" in
        d)
            destination_root=${OPTARG};;
        s)
            source_paths=${OPTARG};;
        r)
            source_root=${OPTARG};;
        x)
            dry_run="--dry-run";;
        u)
            user=${OPTARG};;
        h)
            host=${OPTARG};;
        :)
            echo "Missing argument for option $OPTARG"
            exit 1;;
        ?)
            echo "Unrecognized option '$OPTARG'";;
    esac
done

if [ -z "$source_root" ]; then
    echo "No source root provided, use option -r <path>."
    exit 1
fi

if [ -z "$source_paths" ]; then
    echo "No source paths provided, use option -s <paths>. Where <paths> may be a single path or a space separated double-qouted (\") string of paths."
    exit 1
fi

if [ -z "$destination_root" ]; then
    echo "No destination path provided, use option -d <path>."
    exit 1
fi

if [ ! -z "$user" ] && [ -z "$host" ]; then
    echo "host is not optional if user is provided, use option -h <user>-"
    exit 1
fi

source_root=$(trim_right_slash $source_root)
destination_root=$(trim_right_slash $destination_root)

datetime="$(date '+%Y%m%d_%H%M%S')"

backup_path="$destination_root/$datetime"
latest_link="$destination_root/latest"

message="First backup! Link to latest previous backup does not exist, it will be created."
test_nonexistent_link "$latest_link" "$message" "$host" "$user"

[ ! -z $user ] && remote_prefix="$user@"
[ ! -z $host ] && remote_prefix="$remote_prefix$host:"

index=0
source_path="$(dequote_string "$(get_list_item "$source_paths" "$index")")"
while [ "$source_path" != "null" ]; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$source_path")")
    backup_path_suffix=$(trim_right_slash "$(trim_to_first_right_slash "$source_suffix")")
    destination=$(trim_right_slash "$backup_path/$backup_path_suffix")
    [ -z "$dry_run" ] && create_directory "$destination" "$host" "$user"
    source="$source_root/$source_suffix"

    rsync -aE --progress --delete $dry_run \
        --link-dest "$latest_link/$backup_path_suffix" \
        "$source" \
        "$remote_prefix$destination"

    index=$((index + 1))
    source_path="$(dequote_string "$(get_list_item "$source_paths" "$index")")"
done

if [ -z "$dry_run" ]; then
    remove_path "$latest_link" "$host" "$user"
    create_link "$backup_path" "$latest_link" "$host" "$user"
fi

