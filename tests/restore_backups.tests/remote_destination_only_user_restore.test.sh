#!/bin/sh

script_name="remote_destination_only_user_restore.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_restore.backup.json"
backup_dir="$test_dir/remote_destination_restore.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_restore.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "shh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json
name=simple-remote
user=test-user
json=$(cat << EOM
{
    "destination_user": "$user",
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root_copy",
            "paths": [
                "file1",
                "dir1/file3",
                "dir1/sub_dir",
                "dir2"
            ]
        }
    ]
}
EOM
)
echo "$json" > $backup_json

# WHEN we run blubee
cd ../..
output=$(./blubee -c "$config_path" -b "$backup_json" restore)
exit_code="$?"

# THEN blubee exits with error code
test_results="$(assert_not_equal $exit_code 0)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
[ -e "$backup_dir" ] && rm -r "$backup_dir"
rm "$backup_json"
