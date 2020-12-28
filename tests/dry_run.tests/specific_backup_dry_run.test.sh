#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/multi_backup_dry_run.backup.json"
backup_dir="$test_dir/multi_backup_dry_run.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_multi_backup_dry_run.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test backup json
name_one="specific-one"
name_two="specific-two"
json=$(cat << EOM
{
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name_one",
            "root": "$root_copy",
            "paths": [
                "file1",
                "dir1",
                "dir3/sub_dir1"
            ]
        },
        {
            "name": "$name_two",
            "root": "$root_copy",
            "paths": [
                "file2",
                "dir2",
                "dir3/sub_dir2"
            ]
        }
    ]
}
EOM
)
echo "$json" > $backup_json

# WHEN we make a dry run with blubee
cd ../..
output=$(./blubee -c "$config_path" -b "$backup_json" -n "$name_two" dry backup)

# THEN blubee ran without crashing
test_results="$?"

# AND the output indicates that the second config will be backuped
found_later_removed=$(echo "$output" | grep -e "dir2/file4")
test_results="$test_results $(assert_non_empty_string "$found_later_removed")"

# AND the output does not indicate that the first config will be backuped
not_found_later_removed=$(echo "$output" | grep -e "dir1/file3")
test_results="$test_results $(assert_empty_string "$not_found_later_removed")"

# AND there is no backup directory created
test_results="$test_results $(assert_no_path "$backup_dir")"

# AND the backuped directory has not been changed
has_same_content=$(assert_dirs_equal "$root_copy" "$root")
test_results="$test_results $has_same_content"

echo "multi_backup_dry_run.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
rm "$backup_json"
rm -r "$root_copy"
