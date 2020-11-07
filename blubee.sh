#!/bin/sh
while getopts ":e:" option; do
    case "${option}" in
        e)
            exclude_option=${OPTARG};;
        :)
            echo "Missing argument for option $OPTARG"
            exit 1;;
        ?)
            echo "Unrecognized option '$OPTARG'";;
    esac
done

if [ $(expr $# - $OPTIND) -lt 1 ]; then
    echo "Need at least a source and a destination..."
    exit
fi

destination_root=$(echo "$@" | cut -d' ' -f$#)
datetime="$(date '+%Y%m%d_%H%M%S')"

backup_dir="$destination_root/$datetime"
latest_link="$destination_root/latest"
sources=$(echo "$@" | cut -d' ' -f$OPTIND-$(expr $# - 1))

[ ! -L $latest_link ] && echo "First backup! Link to latest previous backup does not exist, it will be created."

rsync_command="rsync -av --delete --link-dest $latest_link"

[ -n "$exclude_option" ] && rsync_command="$rsync_command --exclude-from $exclude_option"

rsync_command="$rsync_command $sources $backup_dir"

eval $rsync_command

rm -rf $latest_link
ln -s $backup_dir $latest_link

