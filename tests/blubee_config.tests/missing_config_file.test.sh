#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/missing_config_file.backup.json"

# GIVEN a test backup json
name="missing-config"
destination="$test_dir/missing_config_file.backup"
source_root="$test_dir/missing_config_file.root"
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
echo "$json" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/missing_config_file.config"
restore_backup_copy_path="$test_dir/missing_config_file.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# WHEN we try to create a backup without config
cd ../..
./blubee -b "$backup_json" backup
backup_exit="$?"

# THEN blubee exits with non 0 code
test_results="$(assert_not_equal "$backup_exit" "0")"

# AND there was no backup created nor was the original touched
test_results="$test_results $(assert_no_path "$destination")"
has_same_content=$(assert_dirs_equal "$source_root" "$test_dir/test_files_root")
test_results="$test_results $has_same_content"

# WHEN we create a backup with a config
./blubee -c "$config_path" -b "$backup_json" backup
backup_with_config_exit="$?"

# AND we delete the original directory
rm -r $source_root

# AND we try restore the backup without config
./blubee -b "$backup_json" restore
restore_exit="$?"

# THEN blubee exits with non 0 code on restore
test_results="$test_results $(assert_not_equal "$restore_exit" "0")"

# AND blubee exited with 0 code on backup
test_results="$test_results $(assert_equal_numbers "$backup_with_config_exit" "0")"

# AND there is a backup created nor was the original touched
test_results="$test_results $(assert_dir_exists "$destination")"

# AND nothing was restored
test_results="$test_results $(assert_no_path "$source_root")"

echo "missing_config_file.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

[ -e "$destination" ] && rm -r "$destination"
rm "$backup_json"
rm "$config_path"
[ -e "$source_root" ] && rm -r "$source_root"
rm -r "$restore_backup_copy_path"

