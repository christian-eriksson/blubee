#!/bin/sh

script_name="restore_after_delete_dry_run.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_after_delete_dry_run.backup.json"
backup_dir="$test_dir/restore_after_delete_dry_run.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_restore_after_delete_dry_run.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name="dry_run_restore"
json=$(cat << EOM
{
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
echo $json > $backup_json

# AND have taken a backup
cd ../../
./blubee -c "$config_path" -b "$backup_json" backup

# And we delete the backuped directory
rm -r $root_copy

# WHEN we make a dry restore run with blubee
./blubee -b "$backup_json" -c "$config_path" dry restore

# THEN blubee ran without crashing
test_results="$?"

# AND the backup directory retains its changes
test_results="$test_results $(assert_no_path "$root_copy")"

# AND the backup is untouched
test_results="$test_results $(assert_dirs_equal "$backup_dir/$name/latest" "$test_dir/restore_after_delete_dry_run.expected")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
[ -e "$root_copy" ] && rm -r "$root_copy"
rm "$backup_json"
