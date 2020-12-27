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

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/consecutive_backups.config"
restore_backup_copy_path="$test_dir/consecutive_backups.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# change to blubee root path
cd ../..

# when we run blubee
./blubee -c "$config_path" -b "$test_dir/$backup_json" backup

# and we change a few files
files="file1 dir1/sub_dir/file7 dir2/file5"
for file in $files; do
    echo "updated once" > $root_copy/$file
done

# and we wait for a bit
sleep 1

# and we run blubee
./blubee -c "$config_path" -b "$test_dir/$backup_json" backup

result_dir="$backup_dir/$name"
test_restults=""

# THEN there are three files/directories in the backup directory
test_results="$test_results $(assert_files_in_dir "$result_dir" 3)"

# AND two of the directories has a name similar to a date stamp
test_results="$test_results $(assert_datetime_dir_count "$result_dir" 2)"

# AND the latest backup is a link
test_results="$test_results $(assert_is_link "$result_dir/latest")"

# AND the latest backup has the expected content
has_same_content=$(assert_dirs_equal "$result_dir/latest" "$test_dir/consecutive_backups.expected")
test_results="$test_results $has_same_content"


echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$test_dir/$backup_json"
rm "$config_path"
rm -r $root_copy

