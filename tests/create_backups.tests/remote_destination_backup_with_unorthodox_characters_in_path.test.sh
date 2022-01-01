#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_backup_with_unorthodox_characters_in_path.backup.json"
backup_dir="$test_dir/remote_destination_backup_with_unorthodox_characters_in_path.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_backup_with_unorthodox_characters_in_path.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "ssh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json
name=simple-remote
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
                "dir with spaces/space within space",
                "dir with spaces/file with spaces",
                "dir with spaces/dir1",
                "åäöÅÄÖ!$£@øæØÆ{[()]}+/]{[@##åäöÖÄÅ",
                "åäöÅÄÖ!$£@øæØÆ{[()]}+/dir5",
                "{][@£äøæ",
                "no_spaces/dir3",
                "no_spaces/dir4"
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
exit_code="$?"

echo "OUTPUT: $output"

# THEN blubee ran without chrashing
test_results="$exit_code"

# AND blubee prepends the remote user and host to the backup destination
remote_calls=$(echo "$output" | grep -e "rsync.*--protect-args.*$user@$host:$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 8)"

# AND blubee has created the expected folders for backup on the remote
remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}/dir with spaces" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}/åäöÅÄÖ!\$£@øæØÆ{\[()]}+" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}/no_spaces" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

# AND blubee does not create folders without parents in paths
remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$backup_dir/$name/[0-9]\{8\}_[0-9]\{6\}/{\]\[@£äøæ" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 0)"

echo "remote_destination_backup_with_unorthodox_characters_in_path.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
rm "$backup_json"

