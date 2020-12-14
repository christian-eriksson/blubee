#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/specific_restore_after_delete.backup.json"

# GIVEN a test backup json
name_one="specific-one"
name_two="specific-two"
destination="$test_dir/specific_restore_after_delete.copy"
source_root="$test_dir/specific_restore_after_delete.result"
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
config_path="$test_dir/specific_restore_after_delete.config"
restore_backup_copy_path="$test_dir/specific_restore_after_delete.restore_backup"
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

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" -n "$name_two" restore 

# THEN the restored source directory has the expected files, content and structure
test_results=$(assert_dirs_equal "$source_root" "$test_dir/specific_restore_after_delete.expected")

echo "specific_restore_after_delete.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"

