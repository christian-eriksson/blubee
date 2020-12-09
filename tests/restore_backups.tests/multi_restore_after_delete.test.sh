#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="multi_restore_after_delete.backup.json"
backup_json_path="$test_dir/$backup_json"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/multi_restore_after_delete.copy"
source_root="$test_dir/multi_restore_after_delete.result"
echo "\
{
    \"backup_destination\": \"$destination\",
    \"backup_configs\": [
        {
            \"name\": \"$name_one\",
            \"root\": \"$source_root\",
            \"paths\": [
                \"file1\",
                \"dir1\",
                \"dir3/sub_dir1\"
            ]
        },
        {
            \"name\": \"$name_two\",
            \"root\": \"$source_root\",
            \"paths\": [
                \"file2\",
                \"dir2\",
                \"dir3/sub_dir2\"
            ]
        }
    ]
}\
" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/multi_restore_after_delete.config"
restore_backup_copy_path="$test_dir/multi_restore_after_delete.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we are in blubee root path
cd ../..

# AND we have created a backup
./blubee -b "$backup_json_path" backup

# AND we accidentally deleted the original directory
rm -r $source_root

test_results=""

# WHEN we restore the backup
./blubee -b "$backup_json_path" -c "$config_path" restore

# THEN the restored source directory has the expected files, content and structure
diff -r "$source_root" "$test_dir/multi_restore_after_delete.expected"
test_results="$test_results $?"

echo "multi_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$test_dir/$backup_json"
rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"
