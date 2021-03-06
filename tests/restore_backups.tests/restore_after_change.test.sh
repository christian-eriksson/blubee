#!/bin/sh

script_name="restore_after_change.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/restore_after_change.backup.json"
backup_dir="$test_dir/restore_after_change.result"
root="$test_dir/test_files_root"
root_copy="$test_dir/test_files_root.copy"
cp -r $root $root_copy

config_path="$test_dir/../test_config"

# GIVEN a test json
name=simple-restore
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

# AND changed to blubee root path
cd ../..

# AND made a few changes in the directory
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

# AND we make some new changes
rm $root_copy/file2
files="file1 dir1/file3 dir2/file5"
for file in $files; do
    echo "second change" > $root_copy/$file
done

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" restore

result_dir="$root_copy"

# THEN the restored directory contains all the backed up files (and none of the not backed up)
test_results=$(assert_dirs_equal "$result_dir" "$test_dir/restore_after_change.expected")

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$backup_dir"
rm "$backup_json"
rm -r $root_copy
