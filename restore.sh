#!/bin/sh

. ./string_utils.sh

datetime_of_snapshot="latest"

while getopts ":r:p:d:s:x" option; do
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

backup_source_path=$(trim_right_slash "$backup_source_path")
datetime_of_snapshot=$(trim_right_slash "$(trim_left_slash "$datetime_of_snapshot")")
restore_root=$(trim_right_slash "$restore_root")

for restore_path in $restore_paths; do
    source_suffix=$(trim_right_slash "$(trim_left_slash "$restore_path")")
    restore_path_suffix=$(trim_right_slash "$(trim_to_first_right_slash "$source_suffix")")
    rsync -aE --progress --delete $dry_run --backup \
        --backup-dir "/var/local/blubee/backups/$datetime_of_snapshot/$restore_path_suffix" \
        "$backup_source_path/$datetime_of_snapshot/$source_suffix" \
        "$restore_root/$restore_path_suffix"
done

