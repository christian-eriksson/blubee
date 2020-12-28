#!/bin/sh

script_name="consecutive_backups_dry_run.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/consecutive_backups_dry_run.backup.json"
backup_dir="$test_dir/consecutive_backups_dry_run.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_consecutive_backups_dry_run.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name=consecutive
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
echo "$json" > $backup_json

# WHEN we make a dry backup run with blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" dry backup

# AND we change a few files
files="file1 dir1/sub_dir/file7 dir2/file5"
for file in $files; do
    echo "updated once" > $root_copy/$file
done

# AND we make a dry backup run with blubee
./blubee -c "$config_path" -b "$backup_json" dry backup

# THEN blubee ran without crashing
test_results="$?"

# AND there is no backup directory created
test_results="$test_results $(assert_no_path "$backup_dir")"

# AND the backuped directory maintains the changes
has_same_content=$(assert_dirs_equal "$root_copy" "$test_dir/consecutive_backups_dry_run.expected")
test_results="$test_results $has_same_content"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
