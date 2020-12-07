#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="multi_backup.backup.json"

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
./blubee -b "$test_dir/$backup_json" backup

test_results=""

# THEN there is one directory per config in the backup destination
[ -d "$destination/$name_one" ]
test_results="$test_results $?"

[ -d "$destination/$name_two" ]
test_results="$test_results $?"

# AND each config's directory has one directory with a name similar to a date stamp and one link called 'latest'
date_dir_count=$(find "$destination/$name_one" -maxdepth 1 -type d | grep -e "[0-9]\{8\}_[0-9]\{6\}$" | wc -l)
[ $date_dir_count -eq 1 ]
test_results="$test_results $?"

[ -L "$destination/$name_one/latest" ]
test_results="$test_results $?"

date_dir_count=$(find "$destination/$name_two" -maxdepth 1 -type d | grep -e "[0-9]\{8\}_[0-9]\{6\}$" | wc -l)
[ $date_dir_count -eq 1 ]
test_results="$test_results $?"

[ -L "$destination/$name_two/latest" ]
test_results="$test_results $?"

# AND the latest backup links point to the expected content
diff -r "$destination/$name_one/latest" "$test_dir/multi_backup.expected/$name_one"
test_results="$test_results $?"

diff -r "$destination/$name_two/latest" "$test_dir/multi_backup.expected/$name_two"
test_results="$test_results $?"

echo "multi_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$test_dir/$backup_json"

