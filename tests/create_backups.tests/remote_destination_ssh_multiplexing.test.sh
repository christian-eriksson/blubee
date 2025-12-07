#!/bin/sh

script_name="remote_destination_ssh_multiplexing.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_ssh_multiplexing.backup.json"
backup_dir="$test_dir/remote_destination_ssh_multiplexing.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_ssh_multiplexing.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "ssh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json with remote destination
name=ssh_multiplex
user=test-user
host=test-host.xyz
json=$(cat << EOM
{
    "destination_user": "$user",
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

# change to blubee root path
cd ../..

# WHEN we run blubee
output=$(./blubee -c "$config_path" -b "$backup_json" backup)
exit_code="$?"

# THEN blubee ran without crashing
test_results="$exit_code"

# AND SSH ControlMaster option is used in rsync commands
# This allows SSH to reuse existing connections
ssh_control_master=$(echo "$output" | grep -e "rsync.*-o ControlMaster=auto" | wc -l)
test_results="$test_results $(assert_equal_numbers $ssh_control_master 4)"

# AND SSH ControlPath option is used to specify the socket location
ssh_control_path=$(echo "$output" | grep -e "rsync.*-o ControlPath=/tmp/ssh-%r@%h:%p" | wc -l)
test_results="$test_results $(assert_equal_numbers $ssh_control_path 4)"

# AND SSH ControlPersist option is used to keep connections alive
ssh_control_persist=$(echo "$output" | grep -e "rsync.*-o ControlPersist=10m" | wc -l)
test_results="$test_results $(assert_equal_numbers $ssh_control_persist 4)"

# AND all three SSH multiplexing options are present together
all_ssh_opts=$(echo "$output" | grep -e "rsync.*-o ControlMaster=auto.*-o ControlPath=/tmp/ssh-%r@%h:%p.*-o ControlPersist=10m" | wc -l)
test_results="$test_results $(assert_equal_numbers $all_ssh_opts 4)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm "$backup_json"
rm -r $root_copy
[ -e "$backup_dir" ] && rm -r "$backup_dir"
reset_mock_data "rsync" "$test_root"
reset_mock_data "ssh" "$test_root"
