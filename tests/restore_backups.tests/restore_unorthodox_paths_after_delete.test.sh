#!/bin/sh

script_name="restore_unorthodox_paths_after_delete.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_unorthodox_paths_after_delete.backup.json"
backup_dir="$test_dir/restore_unorthodox_paths_after_delete.result"
root="$test_dir/test_files_weird_paths_root"
root_copy="$test_dir/test_files_weird_paths_root.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
destination="$test_dir/restore_unorthodox_paths_after_delete.result"
name=unorthodox-paths
json=$(cat << EOM
{
    "backup_destination": "$destination",
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

# AND we have taken a backup
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup

# AND mistakenly removed the directory
rm -r "$root_copy"

# WHEN we restore the backup
echo "RESTORE!!!!!"
./blubee -b "$backup_json" -c "$config_path" restore

# THEN blubee ran without crashing
test_results="$?"

# AND the restored directory contains all the backed up files (and none of the not backed up)
result_dir="$root_copy"
test_results="$test_results $(assert_dirs_equal "$result_dir" "$test_dir/restore_unorthodox_paths_after_delete.expected")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"
[ ! -z "$1" ] && exit

# clean up
rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
