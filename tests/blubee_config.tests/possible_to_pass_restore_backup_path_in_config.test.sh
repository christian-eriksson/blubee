#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/possible_to_pass_restore_backup_path_in_config.backup.json"

# GIVEN a test backup json
name="permissions"
destination="$test_dir/possible_to_pass_restore_backup_path_in_config.copy"
source_root="$test_dir/possible_to_pass_restore_backup_path_in_config.result"
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
config_path="$test_dir/possible_to_pass_restore_backup_path_in_config.config"
restore_backup_path="$test_dir/possible_to_pass_restore_backup_path_in_config.restore_backup"
mkdir $restore_backup_path
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

# THEN the restore backup copy directory will have the expected content
test_results=$(assert_dirs_equal "$restore_backup_path/latest" "$test_dir/possible_to_pass_restore_backup_path_in_config.expected")

echo "possible_to_pass_restore_backup_path_in_config.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

rm -r "$destination"
rm "$backup_json"
rm -r "$source_root"
rm -r "$restore_backup_path"
rm "$config_path"
