#!/bin/sh

script_name="restore_after_delete.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_after_delete.backup.json"
backup_dir="$test_dir/restore_after_delete.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name=simple-restore
json=$(cat << EOM
{
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root_copy",
            "paths": [
                "file1",
                "dir1/file3",
                "dir1/sub_dir",
                "dir2"
            ]
        }
    ]
}
EOM
)
echo $json > $backup_json

# AND changed to blubee root path
cd ../..

# AND we have taken a backup
./blubee -c "$config_path" -b "$backup_json" backup

# AND mistakenly removed the directory
rm -r "$root_copy"

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" restore

result_dir="$root_copy"

# THEN the restored directory contains all the backed up files (and none of the not backed up)
test_results=$(assert_dirs_equal "$result_dir" "$test_dir/restore_after_delete.expected")

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
