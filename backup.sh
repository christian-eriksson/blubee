#!/bin/sh

script_dir="${0%/*}"

. $script_dir/string_utils.sh

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
[ -z "$dry_run" ] && mkdir -p $backup_path
latest_link="$destination_root/latest"

[ ! -L $latest_link ] && echo "First backup! Link to latest previous backup does not exist, it will be created."

[ ! -z $user ] && remote_prefix="$user@"
[ ! -z $host ] && remote_prefix="$remote_prefix$host:"

for source_path in $source_paths; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$source_path")")
    backup_path_suffix=$(trim_right_slash "$(trim_to_first_right_slash "$source_suffix")")
    destination="$backup_path/$backup_path_suffix"
    [ -z "$dry_run" ] && mkdir -p $destination
    source="$source_root/$source_suffix"

    rsync -aE --progress --delete $dry_run \
        --link-dest "$latest_link/$backup_path_suffix" \
        "$source" \
        "$remote_prefix$destination"
done

if [ -z "$dry_run" ]; then
    rm -rf $latest_link
    ln -s $backup_path $latest_link
fi

