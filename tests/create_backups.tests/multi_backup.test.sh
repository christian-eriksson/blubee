#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="multi_backup.backup.json"

config_path="$test_dir/../test_config"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/multi_backup.result"
echo "\
{
    \"backup_destination\": \"$destination\",
    \"backup_configs\": [
        {
            \"name\": \"$name_one\",
            \"root\": \"$test_dir/test_files_root\",
            \"paths\": [
                \"file1\",
                \"dir1\",
                \"dir3/sub_dir1\"
            ]
        },
        {
            \"name\": \"$name_two\",
            \"root\": \"$test_dir/test_files_root\",
            \"paths\": [
                \"file2\",
                \"dir2\",
                \"dir3/sub_dir2\"
            ]
        }
    ]
}\
" > $backup_json

# AND we are in blubee root path
cd ../..

# WHEN we run blubee
./blubee -c "$config_path" -b "$test_dir/$backup_json" backup

test_results=""

# THEN there is one directory per config in the backup destination
test_results="$test_results $(assert_dir_exists "$destination/$name_one")"
test_results="$test_results $(assert_dir_exists "$destination/$name_two")"

# AND each config's directory has one directory with a name similar to a date stamp and one link called 'latest'
test_results="$test_results $(assert_datetime_dir_count "$destination/$name_one" 1)"
test_results="$test_results $(assert_is_link "$destination/$name_one/latest")"

test_results="$test_results $(assert_datetime_dir_count "$destination/$name_two" 1)"
test_results="$test_results $(assert_is_link "$destination/$name_two/latest")"

# AND the latest backup links point to the expected content
has_same_content=$(assert_dirs_equal "$destination/$name_one/latest" "$test_dir/multi_backup.expected/$name_one")
test_results="$test_results $has_same_content"

has_same_content=$(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/multi_backup.expected/$name_two")
test_results="$test_results $has_same_content"

echo "multi_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$test_dir/$backup_json"

