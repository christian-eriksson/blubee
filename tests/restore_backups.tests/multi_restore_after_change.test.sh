#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="multi_restore_after_change.backup.json"
backup_json_path="$test_dir/$backup_json"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/multi_restore_after_change.backup"
source_root="$test_dir/multi_restore_after_change.copy"
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
config_path="$test_dir/multi_restore_after_change.config"
restore_backup_copy_path="$test_dir/multi_restore_after_change.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND made a few changes in the directory
mkdir "$source_root/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7 dir3/file11 dir3/sub_dir2/file10"
for file in $files; do
    echo "first change" > $source_root/$file
done
echo "new file" > "$source_root/dir2/sub_dir/new-file"
echo "new file" > "$source_root/dir1/sub_dir/new-dir/a_new_file"
rm "$source_root/dir2/file4"

# AND we have created a backup
cd ../..
./blubee -b "$backup_json_path" backup

# AND we make some new changes
rm $source_root/file2
files="file1 dir1/file3 dir2/file5 dir3/file11 dir3/sub_dir1/file9"
for file in $files; do
    echo "second change" > $source_root/$file
done
echo "new file" > "$source_root/dir3/new-file-no-backup"

# WHEN we restore the backup
./blubee -b "$backup_json_path" -c "$config_path" restore

# THEN the restored source directory has the expected files, content and structure
test_results=$(assert_dirs_equal "$source_root" "$test_dir/multi_restore_after_change.expected")

echo "multi_restore_after_change.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$test_dir/$backup_json"
rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"
