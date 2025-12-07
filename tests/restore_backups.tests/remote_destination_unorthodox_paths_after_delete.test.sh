#!/bin/sh

script_name="remote_destination_unorthodox_paths_after_delete.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/remote_destination_unorthodox_paths_after_delete.backup.json"
backup_dir="$test_dir/remote_destination_unorthodox_paths_after_delete.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_remote_destination_unorthodox_paths_after_delete.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"
activate_mock "ssh" "$test_root"

config_path="$test_dir/../test_config"

# GIVEN a test json
name=unorthodox-remote
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
output=$(./blubee -c "$config_path" -b "$backup_json" restore)
exit_code="$?"

# THEN blubee runs without crashing
test_results="$exit_code"

# AND blubee prepends the remote user and host to the destination
remote_calls=$(echo "$output" | grep -e "$user@$host:$backup_dir/$name/latest/" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 8)"

# AND blubee has created the expected folders for backup on the remote
remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$root_copy/dir with spaces" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$root_copy/åäöÅÄÖ!\$£@øæØÆ{\[()]}+" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$root_copy/no_spaces" | wc -l)
test_results="$test_results $(assert_greater_than $remote_calls 0)"

# AND blubee does not create folders without parents in paths
remote_calls=$(echo "$output" | grep -e "ssh.*$user@$host.*mkdir.*$root_copy/{\]\[@£äøæ" | wc -l)
test_results="$test_results $(assert_equal_numbers $remote_calls 0)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
[ -e "$backup_dir" ] && rm -r "$backup_dir"
rm "$backup_json"
