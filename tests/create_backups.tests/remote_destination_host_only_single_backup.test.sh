#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_host_only_single_backup.backup.json"
backup_dir="$test_dir/remote_destination_host_only_single_backup.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_host_only_single_backup.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json
name=simple-remote
host=test-host.xyz
json=$(cat << EOM
{
    "destination_host": "$host",
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
output=$(./blubee -c "$config_path" -b "$backup_json" backup)
test_results=""

# THEN blubee prepends the remote user and host to the backup destination
remote_calls=$(echo "$output" | grep -e "$host:$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}/" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 4)"

# AND blubee has created the expected folders for backup
test_results="$test_results $(assert_dir_exists "$backup_dir/$name")"

echo "remote_destination_host_only_single_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
rm -r "$backup_dir"
rm "$backup_json"

