#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../../string_utils.sh
. ../test_utils.sh

backup_json="$test_dir/backup_with_same_datetime_if_config_takes_time.backup.json"

config_path="$test_dir/../test_config"

activate_mock "date" "$test_root"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/backup_with_same_datetime_if_config_takes_time.result"
json=$(cat << EOM
{
    "backup_destination": "$destination",
    "backup_configs": [
        {
            "name": "$name_one",
            "root": "$test_dir/test_files_root",
            "paths": [
                "file1",
                "dir1",
                "dir3/sub_dir1"
            ]
        },
        {
            "name": "$name_two",
            "root": "$test_dir/test_files_root",
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
echo $json > $backup_json

# AND we are in blubee root path
cd ../..

# WHEN we run blubee
./blubee -c "$config_path" -b "$backup_json" backup
exit_code="$?"

# THEN blubee ran without crashing
test_results="$exit_code"

# THEN there is one directory per config in the backup destination
test_results="$test_results $(assert_dir_exists "$destination/$name_one")"
test_results="$test_results $(assert_dir_exists "$destination/$name_two")"

# AND each config's directory has one directory with a name similar to a date stamp and one link called 'latest'
test_results="$test_results $(assert_datetime_dir_count "$destination/$name_one" 1)"
test_results="$test_results $(assert_is_link "$destination/$name_one/latest")"

test_results="$test_results $(assert_datetime_dir_count "$destination/$name_two" 1)"
test_results="$test_results $(assert_is_link "$destination/$name_two/latest")"

# AND the datetime dirs have the same name
datetime_one=$(get_a_backup_datetime "$destination/$name_one")
datetime_two=$(get_a_backup_datetime "$destination/$name_two")

test_results="$test_results $(assert_equal_strings "$datetime_one" "$datetime_two")"

echo "backup_with_same_datetime_if_config_takes_time.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
reset_mock_data "date" "$test_root"

