#!/bin/sh

script_dir="${0%/*}"

. $script_dir/string_utils.sh
. $script_dir/file_utils.sh
. $script_dir/json_utils.sh

datetime_of_snapshot="latest"

while getopts ":r:p:d:s:b:xu:h:P:" option; do
    case "${option}" in
        r)
            restore_root=${OPTARG};;
        p)
            restore_paths=${OPTARG};;
        d)
            datetime_of_snapshot=${OPTARG};;
        s)
            backup_source_path=${OPTARG};;
        x)
            dry_run="--dry-run";;
        b)
            backup_copy_path=$(trim_right_slash ${OPTARG});;
        u)
            user=${OPTARG};;
        h)
            host=${OPTARG};;
        P)
            port=${OPTARG};;
        :)
            echo "Missing argument for option '$OPTARG'"
            exit 1
            ;;
        ?)
            echo "Unrecognized option '$OPTARG'";;
    esac
done

if [ -z "$restore_root" ]; then
    echo "Root for restore path is missing, use option -r <path>."
    exit 1
fi

if [ -z "$backup_source_path" ]; then
    echo "Source path for backups is missing, use option -b <path>."
    exit 1
fi

if [ ! -z "$user" ] && [ -z "$host" ]; then
    echo "host is not optional if user is provided, use option -h <user>-"
    exit 1
fi

[ ! -z "$backup_copy_path" ] && [ ! -w "$backup_copy_path" ] \
    && echo "Don't have permissions to write to '$backup_copy_path', rectify this and try again" \
    && exit 1

backup_source_path=$(trim_right_slash "$backup_source_path")
datetime_of_snapshot=$(trim_right_slash "$(trim_left_slash "$datetime_of_snapshot")")
restore_root=$(trim_right_slash "$restore_root")

[ ! -z $user ] && remote_prefix="$user@"
[ ! -z $host ] && remote_prefix="$remote_prefix$host:"

index=0
restore_path="$(dequote_string "$(get_list_item "$restore_paths" "$index")")"
while [ "$restore_path" != "null" ]; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$restore_path")")
    restore_path_suffix=$(trim_to_first_right_slash "$source_suffix")

    source_path="$remote_prefix$backup_source_path/$datetime_of_snapshot/$source_suffix"
    target_dir="$restore_root/$restore_path_suffix"

    # rsync seems to have a problem with some creating directories with
    # spaces and unorthodox characters (not sure why), so we help it on
    # the way.
    [ -z "$dry_run" ] && create_directory "$target_dir" "$host" "$user" "$port"

    if [ ! -z "$backup_copy_path" ]; then
        restore_backup_dir="$backup_copy_path/$datetime_of_snapshot/$restore_path_suffix"
        if [ -z "$port" ]; then
            rsync -aE --progress --delete $dry_run --backup --backup-dir "$restore_backup_dir" "$source_path" "$target_dir"
        else
            rsync -aE --progress --rsh="ssh -p $port" --delete $dry_run --backup --backup-dir "$restore_backup_dir" "$source_path" "$target_dir"
        fi
    else
        if [ -z "$port" ]; then
            rsync -aE --progress --delete $dry_run "$source_path" "$target_dir"
        else
            rsync -aE --progress --rsh="ssh -p $port" --delete $dry_run "$source_path" "$target_dir"
        fi
    fi

    index=$((index + 1))
    restore_path="$(dequote_string "$(get_list_item "$restore_paths" "$index")")"
done

