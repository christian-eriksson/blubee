#!/bin/sh

script_name="remote_destination_hard_links_between_backups_w_custom_port.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_hard_links_between_backups_port.backup.json"
backup_dir="$test_dir/remote_destination_hard_links_between_backups_port.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_hard_links_between_backups_port.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "ssh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json with remote destination and custom port
name=hardlink_remote_port
user=test-user
host=test-host.xyz
port=666999
json=$(cat << EOM
{
    "destination_user": "$user",
    "destination_host": "$host",
    "destination_port": "$port",
    "backup_destination": "$backup_dir",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root_copy",
            "paths": [
                "file1",
                "file2",
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

# AND we are in blubee root path
cd ../..

# WHEN we run blubee for the first backup
output=$(./blubee -c "$config_path" -b "$backup_json" backup)
exit_code="$?"

# THEN blubee ran without crashing
test_results="$exit_code"

# AND the --link-dest option is used in rsync commands
# This ensures rsync will create hard links for unchanged files
link_dest_calls=$(echo "$output" | grep -e "rsync.*--link-dest.*$backup_dir/$name/latest" | wc -l)
test_results="$test_results $(assert_equal_numbers $link_dest_calls 5)"

# AND we wait for a bit to ensure different timestamp
sleep 1

# AND we modify only some files (leaving others unchanged)
echo "modified content" > $root_copy/file1
echo "modified content" > $root_copy/dir1/sub_dir/file7

# AND we run blubee for the second backup
output=$(./blubee -c "$config_path" -b "$backup_json" backup)
exit_code="$?"

# THEN blubee ran without crashing
test_results="$test_results $exit_code"

# AND the --link-dest option is STILL used in rsync commands
# This verifies consecutive backups continue to use hard links
link_dest_calls=$(echo "$output" | grep -e "rsync.*--link-dest.*$backup_dir/$name/latest" | wc -l)
test_results="$test_results $(assert_equal_numbers $link_dest_calls 5)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm "$backup_json"
rm -r $root_copy
[ -e "$backup_dir" ] && rm -r "$backup_dir"
reset_mock_data "rsync" "$test_root"
reset_mock_data "ssh" "$test_root"
