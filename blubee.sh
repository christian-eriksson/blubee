#!/bin/sh
if [ $# -lt 2 ]; then
    echo "Need at least a source and a destination..."
    exit
fi

destination_root=$(echo "$@" | cut -d' ' -f$#)
datetime="$(date '+%Y%m%d_%H%M%S')"

backup_dir="$destination_root/$datetime"
latest_link="$destination_root/latest"
sources=$(echo "$@" | cut -d' ' -f1-$(expr $# - 1))

[ ! -L $latest_link ] && echo "First backup! Link to latest previous backup does not exist, it will be created."

rsync -av --delete --link-dest "$latest_link" "$sources" "$backup_dir/"
rm -rf $latest_link
ln -s $backup_dir $latest_link

