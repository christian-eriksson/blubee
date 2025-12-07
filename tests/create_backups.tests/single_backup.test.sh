#!/bin/sh

script_name="single_backup.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/single_backup.backup.json"

config_path="$test_dir/../test_config"

# GIVEN a test json
backup_dir="$test_dir/single_backup.result"
root="$test_dir/test_files_root"
name=simple
json=$(cat << EOM
{
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root",
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
echo "$json" > $backup_json

# WHEN we run blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup

result_dir="$backup_dir/$name"
test_results=""

# THEN there are two files/directories in the backup directory
test_results="$test_results $(assert_files_in_dir "$result_dir" 2)"

# and one of the directories has a name similar to a date stamp
test_results="$test_results $(assert_datetime_dir_count "$result_dir" 1)"

# and the latest backup is a link
test_results="$test_results $(assert_is_link "$result_dir/latest")"

# and the latest backup has the expected content
has_same_content=$(assert_dirs_equal "$result_dir/latest" "$test_dir/single_backup.expected")
test_results="$test_results $has_same_content"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$backup_json"

