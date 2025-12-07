#!/bin/sh

script_name="hard_links_between_backups.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/hard_links_between_backups.backup.json"
backup_dir="$test_dir/hard_links_between_backups.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name=hardlink_test
json=$(cat << EOM
{
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root_copy",
            "paths": [
                "file1",
                "file2",
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

# AND we are in blubee root path
cd ../..

# WHEN we run blubee for the first backup
./blubee -c "$config_path" -b "$backup_json" backup >/dev/null 2>&1
result_dir="$backup_dir/$name"
first_backup=$(readlink -f "$result_dir/latest")

# AND we wait for a bit to ensure different timestamp
sleep 1

# AND we modify only some files (leaving others unchanged)
# file1 will be modified, file2 will remain unchanged
echo "modified content" > $root_copy/file1
echo "modified content" > $root_copy/dir1/sub_dir/file7

# AND we run blubee for the second backup
./blubee -c "$config_path" -b "$backup_json" backup >/dev/null 2>&1
exit_code="$?"
second_backup=$(readlink -f "$result_dir/latest")


# THEN blubee ran without crashing
test_results="$exit_code"

# AND unchanged files are hard-linked between backups (same inode number)
# file2 was not modified, so it should be hard-linked
# dir1/file3 was not modified
# dir2/file4 was not modified
test_results="$test_results $(assert_files_are_hardlinked "$first_backup/file2" "$second_backup/file2")"
test_results="$test_results $(assert_files_are_hardlinked "$first_backup/dir1/file3" "$second_backup/dir1/file3")"
test_results="$test_results $(assert_files_are_hardlinked "$first_backup/dir2/file4" "$second_backup/dir2/file4")"

# AND files in nested subdirectories of dir2 are hard-linked
# dir2/sub_dir/file8 was not modified
test_results="$test_results $(assert_files_are_hardlinked "$first_backup/dir2/sub_dir/file8" "$second_backup/dir2/sub_dir/file8")"

# AND modified files have different inodes (not hard-linked)
# file1 was modified
# dir1/sub_dir/file7 was modified
test_results="$test_results $(assert_files_are_not_hardlinked "$first_backup/file1" "$second_backup/file1")"
test_results="$test_results $(assert_files_are_not_hardlinked "$first_backup/dir1/sub_dir/file7" "$second_backup/dir1/sub_dir/file7")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
