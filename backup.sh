#!/bin/sh

script_dir="${0%/*}"

. $script_dir/string_utils.sh
. $script_dir/file_utils.sh
. $script_dir/json_utils.sh
. $script_dir/debug.sh

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
debug_echo "INPUT CONFIG: " "'$host'" "'$user'" "'$port'"

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
    if ! directory_exists "$destination" "$host" "$user" "$port"; then
        destination_created="$destination"
        while ! directory_exists "$(dirname "$destination_created")" "$host" "$user" "$port"; do
            destination_created="$(dirname "$destination_created")"
        done
        debug_echo "Create directory ${destination} ('destination: $destination' 'host: $host' 'user: $user' 'port: $port')"
        create_directory "$destination" "$host" "$user" "$port"
        return_code=$?
        if [ "$return_code" -ne "0" ]; then
            echo "Could not create directory ${destination}, failed with code: ${return_code}"
            exit_code=10
        fi
    fi

    source="$source_root/$source_suffix"

    if is_debug; then
        rsync_verbose="-vv"
        ssh_verbose="-vvv"
    fi

    if [ -z "$port" ]; then
        rsync -aE ${rsync_verbose} --protect-args --progress --delete $dry_run --rsh="ssh $ssh_verbose" \
            --link-dest "$latest_link/$backup_path_suffix" \
            "$source" \
            "$remote_prefix$destination"
        return_code=$?

        if [ "$return_code" -ne "0" ]; then
            echo "Unable to backup ${source} to ${remote_prefix}${destination}, failed with code: '$return_code'"
            exit_code=11
        fi
    else
        rsync -aE ${rsync_verbose} --protect-args --progress --delete $dry_run --rsh="ssh -p $port $ssh_verbose" \
            --link-dest "$latest_link/$backup_path_suffix" \
            "$source" \
            "$remote_prefix$destination"
        return_code=$?

        if [ "$return_code" -ne "0" ]; then
            echo "Unable to backup ${source} to ${remote_prefix}${destination} on port '$port', failed with code: '$return_code'"
            exit_code=12
        fi
    fi

    if [ ! -z "$destination_created" ] && [ -n "$dry_run" ]; then
        remove_path "$destination_created" "$host" "$user" "$port"
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
    return_code=$?
    if [ "$return_code" -ne "0" ]; then
        echo "Could not remove previous link to latest backup, failed with code: '$return_code'"
        exit 20
    fi

    create_link "$backup_path" "$latest_link" "$host" "$user" "$port"
    return_code=$?
    if [ "$return_code" -ne "0" ]; then
        echo "Could not link to latest backup, failed with code: '$return_code'"
        exit 30
    fi
fi
