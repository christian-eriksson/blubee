#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_after_change_dry_run.backup.json"
backup_dir="$test_dir/restore_after_change_dry_run.backup"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root_restore_after_change.copy"
cp -r $root $root_copy

# GIVEN a test json
name="dry_run_restore"
echo "\
{
    \"backup_destination\": \"$backup_dir\",
    \"backup_configs\": [
        {
            \"name\": \"$name\",
            \"root\": \"$root_copy\",
            \"paths\": [
                \"file1\",
                \"dir1/file3\",
                \"dir1/sub_dir\",
                \"dir2\"
            ]
        }
    ]
}\
" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/restore_after_change_dry_run.config"
restore_backup_copy_path="$test_dir/restore_after_change_dry_run.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND made a few changes in the directory
mkdir "$root_copy/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7"
for file in $files; do
    echo "first change" > $root_copy/$file
done
echo "new file" > "$root_copy/dir2/sub_dir/new-file"
echo "new file" > "$root_copy/dir1/sub_dir/new-dir/a_new_file"
rm "$root_copy/dir2/file4"

# AND have taken a backup
cd ../../
./blubee -b "$backup_json" backup

# AND we make some new changes
rm $root_copy/file2
files="file1 dir1/file3 dir2/file5"
for file in $files; do
    echo "second change" > $root_copy/$file
done

# WHEN we make a dry restore run with blubee
./blubee -b "$backup_json" -c "$config_path" dry restore

# THEN blubee ran without crashing
test_results="$?"

# AND the backup directory retains its changes
test_results="$test_results $(assert_dirs_equal "$root_copy" "$test_dir/restore_after_change_dry_run.expected/root")"

# AND the backup is untouched
test_results="$test_results $(assert_dirs_equal "$backup_dir/$name/latest" "$test_dir/restore_after_change_dry_run.expected/backup")"

echo "restore_after_change_dry_run.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$backup_dir" ] && rm -r "$backup_dir"
[ -e "$root_copy" ] && rm -r "$root_copy"
rm -r "$restore_backup_copy_path"
rm "$backup_json"
rm "$config_path"
