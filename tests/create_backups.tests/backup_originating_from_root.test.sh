#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh
. ../../string_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/backup_originating_from_root.backup.json"

config_path="$test_dir/../test_config"

# GIVEN a test json
backup_dir="$test_dir/backup_originating_from_root.result"
pre_path="$(trim_left_slash "$test_dir/test_files_root")"
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

# WHEN we run blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup
exit_code="$?"

# THEN blubee ran without error
test_results="$exit_code"

# THEN there are two files/directories in the backup directory
result_dir="$test_dir/backup_originating_from_root.result/$name"
test_results="$test_results $(assert_files_in_dir "$result_dir" 2)"

# and one of the directories has a name similar to a date stamp
test_results="$test_results $(assert_datetime_dir_count "$result_dir" 1)"

# and the latest backup is a link
test_results="$test_results $(assert_is_link "$result_dir/latest")"

# and the latest backup has the expected content
has_same_content=$(assert_dirs_equal "$result_dir/latest/$pre_path" "$test_dir/backup_originating_from_root.expected")
test_results="$test_results $has_same_content"

echo "backup_originating_from_root.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] &&  rm -r "$backup_dir"
rm "$backup_json"

