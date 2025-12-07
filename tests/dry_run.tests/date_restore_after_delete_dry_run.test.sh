#!/bin/sh

script_name="date_restore_after_delete_dry_run.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../../string_utils.sh
. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/date_restore_after_delete_dry_run.backup.json"
backup_dir="$test_dir/date_restore_after_delete_dry_run.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_date_restore_after_delete_dry_run.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name="date_dry_run_restore"
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

# AND have taken a backup
cd ../../
./blubee -c "$config_path" -b "$backup_json" backup

# AND we note the date of the first backup
first_backup_datetime=$(get_a_backup_datetime "$backup_dir/$name")

# AND we wait for a bit
sleep 1

# AND made a few changes in the directory
mkdir "$root_copy/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7"
for file in $files; do
    echo "first change" > $root_copy/$file
done
echo "new file" > "$root_copy/dir2/sub_dir/new-file"
echo "new file" > "$root_copy/dir1/sub_dir/new-dir/a_new_file"
rm "$root_copy/dir2/file4"

# AND we take another backup
./blubee -c "$config_path" -b "$backup_json" backup

# And we delete the backuped directory
rm -r $root_copy

# WHEN we make a dry restore run with blubee
output=$(./blubee -b "$backup_json" -c "$config_path" -d "$first_backup_datetime" dry restore)

# THEN blubee ran without crashing
test_results="$?"

# AND the output indicate that the first backup will be restored
found_later_removed=$(echo "$output" | grep -e "dir2/file4")
test_results="$test_results $(assert_non_empty_string "$found_later_removed")"

# AND the output does not indicate that the second backup will be restored
found_new_file=$(echo "$output" | grep -e "dir2/sub_dir/new-file" -e "sub_dir/new-dir/a_new_file")
test_results="$test_results $(assert_empty_string "$found_new_file")"

# AND the backup directory is not restored
test_results="$test_results $(assert_no_path "$root_copy")"

# AND the first backup is untouched
test_results="$test_results $(assert_dirs_equal "$backup_dir/$name/$first_backup_datetime" "$test_dir/date_restore_after_delete_dry_run.expected/first")"

# AND the second backup is untouched
test_results="$test_results $(assert_dirs_equal "$backup_dir/$name/latest" "$test_dir/date_restore_after_delete_dry_run.expected/second")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
[ -e "$root_copy" ] && rm -r "$root_copy"
rm "$backup_json"
