#!/bin/sh

script_name="multi_restore_after_change_dry_run.test.sh"
relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/multi_restore_after_change_dry_run.backup.json"

config_path="$test_dir/../test_config"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/multi_restore_after_change_dry_run.copy"
source_root="$test_dir/multi_restore_after_change_dry_run.result"
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
echo "$json" > $backup_json

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
./blubee -b "$backup_json" -c "$config_path" backup

# AND we make some new changes
rm $source_root/file2
files="file1 dir1/file3 dir2/file5 dir3/file11 dir3/sub_dir1/file9"
for file in $files; do
    echo "second change" > $source_root/$file
done
echo "new file" > "$source_root/dir3/new-file-no-backup"

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" dry restore

# THEN blubee ran without crashing
test_results="$?"

# AND the backuped directory retains its latest changes
test_results="$test_results $(assert_dirs_equal "$source_root" "$test_dir/multi_restore_after_change_dry_run.expected/root")"

# AND the backup is untouched
test_results="$test_results $(assert_dirs_equal "$destination/$name_one/latest" "$test_dir/multi_restore_after_change_dry_run.expected/backup/$name_one")"
test_results="$test_results $(assert_dirs_equal "$destination/$name_two/latest" "$test_dir/multi_restore_after_change_dry_run.expected/backup/$name_two")"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
rm -r "$source_root"
