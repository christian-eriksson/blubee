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
            \"root\": \"$test_dir/simple_backup\",
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
blubee -b "$test_dir/$backup_json" backup

result_dir="$test_dir/simple_backup.result/$name"
test_restults=""

# then there are two files/directories in the backup directory
file_count=$(count $result_dir/*)
[ $file_count -eq 2 ] \
    && test_results="$test_results PASS" \
    || test_results="$test_results FAIL"

# and one of the directories has a name similar to a date stamp
date_dir_count=$(find $result_dir -maxdepth 1 -type d | grep -e "[0-9]\{8\}_[0-9]\{6\}$" | wc -l)
[ $date_dir_count -eq 1 ] \
    && test_results="$test_results PASS" \
    || test_results="$test_results FAIL"

# and the latest backup is a link
[ -L "$result_dir/latest" ] \
    && test_results="$test_results PASS" \
    || test_results="$test_results FAIL"

# and the latest backup has the expected content
diff -r "$result_dir/latest" "$test_dir/simple_backup.expected" \
    && test_results="$test_results PASS" \
    || test_results="$test_results FAIL"

echo "simple_backup.test.sh\nRESULTS:"
for result in $test_results; do
    echo $result
done

# clean up
rm -r "$test_dir/simple_backup.result"
rm "$test_dir/$backup_json"

