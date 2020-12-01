#!/bin/sh

. ./string_utils.sh

while getopts ":e:s:d:r:" option; do
    case "${option}" in
        e)
            exclude_pattern=${OPTARG};;
        d)
            destination_root=${OPTARG};;
        s)
            source_paths=${OPTARG};;
        r)
            source_root=${OPTARG};;
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

source_root=$(trim_right_slash $source_root)
destination_root=$(trim_right_slash $destination_root)

datetime="$(date '+%Y%m%d_%H%M%S')"

backup_path="$destination_root/$datetime"
mkdir -p $backup_path
latest_link="$destination_root/latest"

[ ! -L $latest_link ] && echo "First backup! Link to latest previous backup does not exist, it will be created."

for source in $source_paths; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$source")")
    backup_path_suffix=$(trim_right_slash "$(trim_to_first_right_slash "$source")")

    rsync_command="rsync -aE --progress --delete --link-dest $latest_link/$backup_path_suffix"
    [ -n "$exclude_pattern" ] && rsync_command="$rsync_command --exclude-from $exclude_pattern"
    rsync_command="$rsync_command $source_root/$source_suffix $backup_path/$backup_path_suffix"

    eval $rsync_command
done

rm -rf $latest_link
ln -s $backup_path $latest_link

