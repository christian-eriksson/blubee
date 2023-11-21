#!/bin/sh

script_dir="${0%/*}"

. $script_dir/string_utils.sh
. $script_dir/file_utils.sh
. $script_dir/json_utils.sh

backup_version="$(date '+%Y%m%d_%H%M%S')"

while getopts ":s:d:r:xh:u:v:p:" option; do
    case "${option}" in
    d)
        destination_root=${OPTARG}
        ;;
    s)
        source_paths=${OPTARG}
        ;;
    r)
        source_root=${OPTARG}
        ;;
    x)
        dry_run="--dry-run"
        ;;
    u)
        user=${OPTARG}
        ;;
    h)
        host=${OPTARG}
        ;;
    p)
        port=${OPTARG}
        ;;
    v)
        backup_version=${OPTARG}
        ;;
    :)
        echo "Missing argument for option $OPTARG"
        exit 1
        ;;
    ?)
        echo "Unrecognized option '$OPTARG'"
        ;;
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

backup_path="$destination_root/$backup_version"
latest_link="$destination_root/latest"

message="First backup! Link to latest previous backup does not exist, it will be created."
test_nonexistent_link "$latest_link" "$message" "$host" "$user" "$port"

[ ! -z $user ] && remote_prefix="$user@"
[ ! -z $host ] && remote_prefix="$remote_prefix$host:"

index=0
source_path="$(dequote_string "$(get_list_item "$source_paths" "$index")")"
if [ "$?" -ne "0" ]; then
    echo "Could not get source paths from ${source_paths}, json may be malformed"
    exit 4
fi

exit_code=0
while [ "$source_path" != "null" ]; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$source_path")")
    backup_path_suffix=$(trim_right_slash "$(trim_to_first_right_slash "$source_suffix")")
    destination=$(trim_right_slash "$backup_path/$backup_path_suffix")
    [ -z "$dry_run" ] && create_directory "$destination" "$host" "$user" "$port"

    if [ "$?" -ne "0" ]; then
        echo "Could not not create directory ${destination}"
        exit_code=10
    fi

    source="$source_root/$source_suffix"

    if [ -z "$port" ]; then
        rsync -aE --protect-args --progress --delete $dry_run \
            --link-dest "$latest_link/$backup_path_suffix" \
            "$source" \
            "$remote_prefix$destination"

        if [ "$?" -ne "0" ]; then
            echo "Unable to backup ${source} to ${remote_prefix}${destination}"
            exit_code=10
        fi
    else
        rsync -aE --protect-args --progress --delete $dry_run --rsh="ssh -p $port" \
            --link-dest "$latest_link/$backup_path_suffix" \
            "$source" \
            "$remote_prefix$destination"

        if [ "$?" -ne "0" ]; then
            echo "Unable to backup ${source} to ${remote_prefix}${destination}"
            exit_code=10
        fi
    fi

    index=$((index + 1))
    source_path="$(dequote_string "$(get_list_item "$source_paths" "$index")")"
    if [ "$?" -ne "0" ]; then
        echo "Could not get source paths from ${source_paths}"
        exit_code=15
    fi
done

if [ "$exit_code" -ne "0" ]; then
    exit $exit_code
fi

if [ -z "$dry_run" ]; then
    remove_path "$latest_link" "$host" "$user" "$port"
    if [ "$?" -ne "0" ]; then
        echo "Could not remove previous link to latest backup"
        exit 20
    fi

    create_link "$backup_path" "$latest_link" "$host" "$user" "$port"
    if [ "$?" -ne "0" ]; then
        echo "Could not link to latest backup"
        exit 30
    fi
fi
