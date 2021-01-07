#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.backup.json"

# GIVEN a test backup json
name="permissions"
destination="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.copy"
source_root="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.result"
json=$(cat << EOM
{
    "backup_destination": "$destination",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$source_root",
            "paths": [
                "dir1"
            ]
        }
    ]
}
EOM
)
echo $json > $backup_json

# AND a config with a RESTORE_BACKUP_PATH variable
config_path="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.config"
restore_backup_path="$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.restore_backup"
mkdir $restore_backup_path
chmod -w $restore_backup_path
echo "\
RESTORE_BACKUP_PATH=$restore_backup_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we have created a backup
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup

# AND we make some new changes
echo "first change" > "$source_root/dir1/file1"
echo "new file" > "$source_root/dir1/new-file"

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" restore
exit_code=$?

test_results=""
# THEN blubee exits with non 0 code
test_results="$test_results $(assert_not_equal "$exit_code" "0")"

# AND the resulting source directory has not restored
has_same_content=$(assert_dirs_equal "$source_root" "$test_dir/fail_if_no_permissions_to_write_to_backup_copy_during_restore.expected")
test_results="$test_results $has_same_content"

echo "fail_if_no_permissions_to_write_to_backup_copy_during_restore.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

rm -r "$destination"
rm "$backup_json"
rm -r "$source_root"
chmod +w "$restore_backup_path"
rm -r "$restore_backup_path"
rm "$config_path"
