#!/bin/sh

script_name="specific_restore_after_delete_dry_run.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/specific_restore_after_delete_dry_run.backup.json"

config_path="$test_dir/../test_config"

# GIVEN a test backup json
name_one="specific-one"
name_two="specific-two"
destination="$test_dir/specific_restore_after_delete_dry_run.copy"
source_root="$test_dir/specific_restore_after_delete_dry_run.result"
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

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we are in blubee root path
cd ../..

# AND we have created a backup
./blubee -c "$config_path" -b "$backup_json" backup

# AND we accidentally deleted the original directory
rm -r $source_root

# WHEN we make a dry restore of the backup
./blubee -b "$backup_json" -c "$config_path" -n "$name_two" dry restore

# THEN blubee ran without crashing
test_results="$?"

# AND the backuped directory does not exist
test_results="$test_results $(assert_no_path "$source_root")"

# AND the backup is untouched
test_results="$test_results $(assert_dirs_equal "$destination/$name_one/latest" "$test_dir/specific_restore_after_delete_dry_run.expected/$name_one")"
test_results="$test_results $(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/specific_restore_after_delete_dry_run.expected/$name_two")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
[ -e "$source_root" ] && rm -r "$source_root"

