#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/specific_backup.backup.json"

# GIVEN a test backup json
name_one="specific-one"
name_two="specific-two"
destination="$test_dir/specific_backup.backup"
source_root="$test_dir/specific_backup.root"
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
config_path="$test_dir/specific_backup.config"
restore_backup_copy_path="$test_dir/specific_backup.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND there is data in the source to backup
cp -r $test_dir/test_files_root $source_root

# WHEN we run blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" -n "$name_two" backup

test_results=""

# THEN there is a backup directory for config two in the backup destination
test_results="$test_results $(assert_dir_exists "$destination/$name_two")"

# AND there is no backup directory for config one in the backup destination
test_results="$test_results $(assert_no_path "$destination/$name_one")"

# AND directory for the second config has one directory with a name similar to a date stamp and one link called 'latest'
test_results="$test_results $(assert_datetime_dir_count "$destination/$name_two" 1)"
test_results="$test_results $(assert_is_link "$destination/$name_two/latest")"

# AND the latest backup link point to the expected content
has_same_content=$(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/specific_backup.expected/$name_two")
test_results="$test_results $has_same_content"

echo "specific_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
rm -r "$source_root"
rm "$config_path"

