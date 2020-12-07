#!/bin/sh

script_name="consecutive_backups.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="consecutive_backups.backup.json"
backup_dir="$test_dir/consecutive_backups.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root.copy"
cp -r $root $root_copy

# given a test json
name=consecutive
echo "\
{
    \"backup_destination\": \"$backup_dir\",
    \"backup_configs\": [
        {
            \"name\": \"$name\",
            \"root\": \"$root_copy\",
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

# and we change a few files
files="file1 dir1/sub_dir/file7 dir2/file5"
for file in $files; do
    echo "updated once" > $root_copy/$file
done

# and we wait for a bit
sleep 1

# and we run blubee
./blubee -b "$test_dir/$backup_json" backup

result_dir="$backup_dir/$name"
test_restults=""

# then there are three files/directories in the backup directory
file_count=$(count $result_dir/*)
[ $file_count -eq 3 ]
test_results="$test_results $?"

# and two of the directories has a name similar to a date stamp
date_dir_count=$(find $result_dir -maxdepth 1 -type d | grep -e "[0-9]\{8\}_[0-9]\{6\}$" | wc -l)
[ $date_dir_count -eq 2 ]
test_results="$test_results $?"

# and the latest backup is a link
[ -L "$result_dir/latest" ]
test_results="$test_results $?"

# and the latest backup has the expected content
diff -r "$result_dir/latest" "$test_dir/consecutive_backups.expected"
test_results="$test_results $?"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$test_dir/$backup_json"
rm -r $root_copy
