#!/bin/sh

datetime_of_snapshot="latest"

while getopts ":r:d:s:" option; do
    case "${option}" in
        r)
            restore_path=${OPTARG};;
        d)
            datetime_of_snapshot=${OPTARG};;
        s)
            backup_source_path=${OPTARG};;
        :)
            echo "Missing argument for option '$OPTARG'"
            exit 1
            ;;
        ?)
            echo "Unrecognized option '$OPTARG'";;
    esac
done

if [ -z "$restore_path" ]; then
    echo "Root for restore path is missing, use option -r <path>."
    exit 1
fi

if [ -z "$backup_source_path" ]; then
    echo "Source path for backups is missing, use option -b <path>."
    exit 1
fi

rsync -av --delete --backup --backup-dir "~/temp/saved/backups" "$backup_source_path/$datetime_of_snapshot/" "$restore_path"

