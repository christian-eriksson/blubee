#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="fail_if_no_permissions_to_write_to_backup_copy_during_restore.backup.json"
backup_json_path="$test_dir/$backup_json"

# GIVEN a test backup json
name="permissions"
destination="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.copy"
source_root="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.result"
echo "\
{
    \"backup_destination\": \"$destination\",
    \"backup_configs\": [
        {
            \"name\": \"$name\",
            \"root\": \"$source_root\",
            \"paths\": [
                \"dir1\"
            ]
        }
    ]
}\
" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.config"
restore_backup_copy_path="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.restore_backup"
mkdir $restore_backup_copy_path
chmod -w $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we have created a backup
cd ../..
./blubee -b "$backup_json_path" backup

# AND we make some new changes
echo "first change" > "$source_root/dir1/file1"
echo "new file" > "$source_root/dir1/new-file"

# WHEN we restore the backup
./blubee -b "$backup_json_path" -c "$config_path" restore
exit_code=$?

test_results=""
# THEN blubee exits with non 0 code
[ "$exit_code" -ne "0" ]
test_results="$test_results $?"

# AND the resulting source directory has not restored
diff -r "$source_root" "$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.expected"
test_results="$test_results $?"

echo "fail_if_no_permissions_to_write_to_backup_copy_during_restore.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

rm -r "$destination"
rm "$test_dir/$backup_json"
rm -r "$source_root"
chmod +w "$restore_backup_copy_path"
rm -r "$restore_backup_copy_path"
rm "$config_path"
