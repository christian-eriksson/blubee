#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../../string_utils.sh
. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/date_specific_restore_after_change_dry_run.backup.json"

# GIVEN a test backup json
name_one="date_specific_one"
name_two="date_specific_two"
destination="$test_dir/date_specific_restore_after_change_dry_run.backup"
source_root="$test_dir/date_specific_restore_after_change_dry_run.root"
json=$(cat << EOM
{
    "backup_destination": "$destination",
    "backup_configs": [
        {
            "name": "$name_one",
            "root": "$source_root",
            "paths": [
                "file1",
                "dir1",
                "dir3/sub_dir1"
            ]
        },
        {
            "name": "$name_two",
            "root": "$source_root",
            "paths": [
                "file2",
                "dir2",
                "dir3/sub_dir2"
            ]
        }
    ]
}
EOM
)
echo " $json" > $backup_json

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/date_specific_restore_after_change_dry_run.config"
restore_backup_copy_path="$test_dir/date_specific_restore_after_change_dry_run.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND made a few changes in the directory
mkdir "$source_root/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7 dir3/file11 dir3/sub_dir2/file10"
for file in $files; do
    echo "first change" > $source_root/$file
done
echo "new file" > "$source_root/dir2/sub_dir/new-file"
echo "new file" > "$source_root/dir1/sub_dir/new-dir/a_new_file"
rm "$source_root/dir2/file4"

# AND we have created a backup
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup

# AND we note the date of the first backup
first_backup_datetime=$(get_a_backup_datetime "$destination/$name_one")

# AND we wait for a bit
sleep 1

# AND we make some new changes
files="file1 dir2/file5 dir3/sub_dir2/file10"
for file in $files; do
    echo "second change" > $source_root/$file
done
rm $source_root/dir2/sub_dir/new-file
rm $source_root/dir1/file6
echo "new file" > "$source_root/dir2/sub_dir/another-new-file"
echo "new file" > "$source_root/dir1/sub_dir/another-new-file"

# AND we take another backup
./blubee -c "$config_path" -b "$backup_json" backup

# AND we make a last change
rm $source_root/dir2/sub_dir/another-new-file
rm $source_root/dir1/sub_dir/another-new-file
files="file1 dir2/file5"
for file in $files; do
    echo "third change" > $source_root/$file
done

# WHEN we make a dry restore run with blubee
output=$(./blubee -b "$backup_json" -c "$config_path" -n "$name_two" -d "$first_backup_datetime" dry restore)

# THEN blubee ran without crashing
test_results="$?"

# AND the output indicates that the first backup of the second config will be restored
found_later_removed=$(echo "$output" | grep -e "dir2/sub_dir/new-file")
test_results="$test_results $(assert_non_empty_string "$found_later_removed")"

# AND the output does not indicate that the first backup of the first config will be restored
not_found_later_removed=$(echo "$output" | grep -e "dir1/file6")
test_results="$test_results $(assert_empty_string "$not_found_later_removed")"

# AND the output does not indicate that the second backup of the second config will be restored
not_found_new_file=$(echo "$output" | grep -e "dir2/sub_dir/another-new-file")
test_results="$test_results $(assert_empty_string "$not_found_new_file")"

# AND the output does not indicate that the second backup of the first config will be restored
not_found_a_new_file=$(echo "$output" | grep -e "dir1/sub_dir/another-new-file")
test_results="$test_results $(assert_empty_string "$not_found_a_new_file")"

# AND the first backup is untouched
test_results="$test_results $(assert_dirs_equal "$destination/$name_one/$first_backup_datetime" "$test_dir/date_specific_restore_after_change_dry_run.expected/backup/first/$name_one")"
test_results="$test_results $(assert_dirs_equal "$destination/$name_two/$first_backup_datetime" "$test_dir/date_specific_restore_after_change_dry_run.expected/backup/first/$name_two")"

# AND the second backup is untouched
test_results="$test_results $(assert_dirs_equal "$destination/$name_one/latest" "$test_dir/date_specific_restore_after_change_dry_run.expected/backup/second/$name_one")"
test_results="$test_results $(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/date_specific_restore_after_change_dry_run.expected/backup/second/$name_two")"

# AND the backuped directory retains its latest changes
test_results="$test_results $(assert_dirs_equal "$source_root" "$test_dir/date_specific_restore_after_change_dry_run.expected/root")"

echo "date_specific_restore_after_change_dry_run.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$destination" ] && rm -r "$destination"
rm "$backup_json"
[ -e "$source_root" ] && rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"

