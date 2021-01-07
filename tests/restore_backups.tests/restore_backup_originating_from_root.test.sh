#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh
. ../../string_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_backup_originating_from_root.backup.json"

config_path="$test_dir/../test_config"
root="$test_dir/test_files_root"
root_copy="$test_dir/restore_backup_originating_from_root.root"
cp -r "$root" "$root_copy"

# GIVEN a test json
backup_dir="$test_dir/restore_backup_originating_from_root.result"
pre_path="$(trim_left_slash "$root_copy")"
name=root_origin
json=$(cat << EOM
{
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "/",
            "paths": [
                "$pre_path/file1",
                "$pre_path/dir1/file3",
                "$pre_path/dir1/sub_dir",
                "$pre_path/dir2"
            ]
        }
    ]
}
EOM
)
echo "$json" > $backup_json

# AND we have taken a backup
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup
exit_code="$?"

# AND mistakenly removed the backuped files
rm -r "$root_copy"

# WHEN we run blubee to restore
./blubee -c "$config_path" -b "$backup_json" restore
exit_code="$?"

# THEN blubee ran without error
test_results="$exit_code"

# AND the restored directory contains all the backed up files (and none of the not backed up)
result_dir="$root_copy"
test_results=$(assert_dirs_equal "$result_dir" "$test_dir/restore_backup_originating_from_root.expected")

echo "restore_backup_originating_from_root.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] &&  rm -r "$backup_dir"
[ -e "$root_copy" ] && rm -r "$root_copy"
rm "$backup_json"

