#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="simple_backup.backup.json"

# given a test json
name=simple
echo "\
{
    \"backup_destination\": \"$test_dir/simple_backup.result\",
    \"backup_configs\": [
        {
            \"name\": \"$name\",
            \"root\": \"$test_dir/test_files_root\",
            \"paths\": [
                \"file1\",
                \"dir1/file3\",
                \"dir1/sub_dir\",
                \"dir2\"
            ]
        }
    ]
}\
" > $backup_json

# change to blubee root path
cd ../..

# when we run blubee
./blubee -b "$test_dir/$backup_json" backup

result_dir="$test_dir/simple_backup.result/$name"
test_results=""

# THEN there are two files/directories in the backup directory
test_results="$test_results $(assert_files_in_dir "$result_dir" 2)"

# and one of the directories has a name similar to a date stamp
test_results="$test_results $(assert_datetime_dir_count "$result_dir" 1)"

# and the latest backup is a link
[ -L "$result_dir/latest" ]
test_results="$test_results $?"

# and the latest backup has the expected content
has_same_content=$(assert_dirs_equal "$result_dir/latest" "$test_dir/simple_backup.expected")
test_results="$test_results $has_same_content" 

echo "simple_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$test_dir/simple_backup.result"
rm "$test_dir/$backup_json"

