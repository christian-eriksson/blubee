#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/multi_restore_after_delete_dry_run.backup.json"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/multi_restore_after_delete_dry_run.copy"
source_root="$test_dir/multi_restore_after_delete_dry_run.result"
json=$(cat << EOM
{
    "backup_destination": "$destination",
    "backup_configs": [
        {
            "name": "$name_one",
            "root": "$source_root",
            "paths": [
                "file1",
                "dir1",
                "dir3/sub_dir1"
            ]
        },
        {
            "name": "$name_two",
            "root": "$source_root",
            "paths": [
                "file2",
                "dir2",
                "dir3/sub_dir2"
            ]
        }
    ]
}
EOM
)
echo "$json" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/multi_restore_after_delete_dry_run.config"
restore_backup_copy_path="$test_dir/multi_restore_after_delete_dry_run.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we are in blubee root path
cd ../..

# AND we have created a backup
./blubee -b "$backup_json" backup

# AND we accidentally deleted the original directory
rm -r $source_root

# WHEN we make a dry run to restore the backup
./blubee -b "$backup_json" -c "$config_path" dry restore

test_results=""

# THEN the backuped directory does not exist
test_results="$test_results $(assert_no_path "$source_root")"

# AND the backup is untouched
test_results="$test_results $(assert_dirs_equal "$destination/$name_one/latest" "$test_dir/multi_restore_after_delete_dry_run.expected/$name_one")"
test_results="$test_results $(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/multi_restore_after_delete_dry_run.expected/$name_two")"

echo "multi_restore_after_delete_dry_run.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
[ -e "$source_root" ] && rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"

