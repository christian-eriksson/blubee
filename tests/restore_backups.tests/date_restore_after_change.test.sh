#!/bin/sh

script_name="restore_after_change.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../../string_utils.sh
. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_after_change.backup.json"
backup_dir="$test_dir/restore_after_change.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/date_restore_after_change_root"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name="date-restore-change"
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

# AND made a few changes in the directory
cd ../..
mkdir "$root_copy/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7"
for file in $files; do
    echo "first change" > $root_copy/$file
done
echo "new file" > "$root_copy/dir2/sub_dir/new-file"
echo "new file" > "$root_copy/dir1/sub_dir/new-dir/a_new_file"
rm "$root_copy/dir2/file4"

# AND we have taken a backup
./blubee -c "$config_path" -b "$backup_json" backup

# AND we note the date of the first backup
first_backup_datetime=$(get_a_backup_datetime "$backup_dir/$name")

# AND we wait for a bit
sleep 1

# AND we make some new changes
rm $root_copy/file2
files="file1 dir1/file3 dir2/file5"
for file in $files; do
    echo "second change" > $root_copy/$file
done

# AND we take another backup
./blubee -c "$config_path" -b "$backup_json" backup

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" -d "$first_backup_datetime" restore

# THEN blubee runs without error
test_results="$?"

# THEN the restored directory contains all the backed up files (and none of the not backed up)
test_results="$test_results $(assert_dirs_equal "$root_copy" "$test_dir/date_restore_after_change.expected")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
