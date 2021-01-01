#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

backup_json="$test_dir/not_passing_restore_backup_in_config.test.sh.backup.json"
backup_dir="$test_dir/not_passing_restore_backup_in_config.test.sh.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_not_passing_restore_backup_in_config.test.sh.copy"
cp -r $root $root_copy

activate_mock "rsync" "$test_root"

# GIVEN a test json
name=simple-remote
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

# AND a config with no RESTORE_BACKUP_PATH variable
config_path="$test_dir/possible_to_pass_restore_backup_path_in_config.config"
restore_backup_path="$test_dir/possible_to_pass_restore_backup_path_in_config.restore_backup"
mkdir $restore_backup_path
echo "\
" > $config_path

# WHEN we run blubee
cd ../..
output=$(./blubee -c "$config_path" -b "$backup_json" restore)
exit_code="$?"

# THEN blubee ran without crashing
test_results="$(assert_equal_numbers "$exit_code" 0)"

# AND blubee does not prepend the --backup option to the rsync command
backup_option_count=$(echo "$output" | grep --color -e "rsync.*--backup " | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_option_count" 0)"

# THEN blubee does not prepend the --backup-dir option to the rsync command
backup_dir_option_count=$(echo "$output" | grep --color -e "rsync.*--backup-dir " | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_dir_option_count" 0)"

echo "not_passing_restore_backup_in_config.test.sh.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$root_copy"
rm "$backup_json"
[ -e "$restore_backup_path" ] && rm -r $restore_backup_path
[ -e "$config_path" ] && rm $config_path

