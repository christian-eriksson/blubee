#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/backup_dry_run.backup.json"
backup_dir="$test_dir/backup_dry_run.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_backup_dry_run.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name="dry_run"
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

# WHEN we run a dry run with blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" dry backup

# THEN blubee ran without crashing
test_results="$?"

# AND there are no backup directory
test_results="$test_results $(assert_no_path "$backup_dir")"

# AND the original files are untouched
test_results="$test_results $(assert_dirs_equal "$root_copy" "$root")"

echo "backup_dry_run.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
rm -r "$root_copy"
rm "$backup_json"

