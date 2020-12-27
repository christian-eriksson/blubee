#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_multi_backup.backup.json"
backup_dir="$test_dir/remote_destination_multi_backup.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_multi_backup.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"

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

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/remote_destination_multi_backup.config"
restore_backup_copy_path="$test_dir/remote_destination_multi_backup.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# WHEN we run blubee
cd ../..
output=$(./blubee -c "$config_path" -b "$backup_json" backup)
test_results=""

# THEN blubee prepends the remote user and host to the backup destination
remote_calls=$(echo "$output" | grep -e "$user@$host:$backup_dir/$name_one/[0-9]\{8\}_[0-9]\{6\}/" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 3)"

remote_calls=$(echo "$output" | grep -e "$user@$host:$backup_dir/$name_two/[0-9]\{8\}_[0-9]\{6\}/" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 3)"

# AND blubee has created the expected folders for backup
test_results="$test_results $(assert_dir_exists "$backup_dir/$name_one")"
test_results="$test_results $(assert_dir_exists "$backup_dir/$name_two")"

echo "remote_destination_multi_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
rm -r "$backup_dir"
rm "$backup_json"
rm "$config_path"

