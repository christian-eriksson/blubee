#!/bin/sh

script_name="remote_destination_multi_restore.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_multi_restore.backup.json"
backup_dir="$test_dir/remote_destination_multi_restore.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_multi_restore.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "ssh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json
name_one=simple-remote-one
name_two=simple-remote-two
user=test-user
host=test-host.xyz
json=$(cat << EOM
{
    "destination_user": "$user",
    "destination_host": "$host",
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name_one",
            "root": "$root_copy",
            "paths": [
                "file1",
                "dir1",
                "dir3/sub_dir1"
            ]
        },
        {
            "name": "$name_two",
            "root": "$root_copy",
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

# WHEN we run blubee
cd ../..
output=$(./blubee -c "$config_path" -b "$backup_json" restore)
exit_code="$?"
test_results=""

# THEN blubee prepends the remote user and host to the backup destination
remote_calls=$(echo "$output" | grep -e "$user@$host:$backup_dir/$name_one/latest" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 3)"

remote_calls=$(echo "$output" | grep -e "$user@$host:$backup_dir/$name_two/latest" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 3)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
rm "$backup_json"

