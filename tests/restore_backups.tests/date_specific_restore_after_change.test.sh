#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../../string_utils.sh
. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/date_specific_restore_after_change.backup.json"

# GIVEN a test backup json
name_one="multi-one"
name_two="multi-two"
destination="$test_dir/date_specific_restore_after_change.copy"
source_root="$test_dir/date_specific_restore_after_change.result"
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

# AND a config with a RESTORE_BACKUP_COPY variable
config_path="$test_dir/date_specific_restore_after_change.config"
restore_backup_copy_path="$test_dir/date_specific_restore_after_change.restore_backup"
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
./blubee -b "$backup_json" backup

# AND we note the date of the first backup
first_backup_datetime=$(get_a_backup_datetime "$destination/$name_two")

# AND we wait for a bit
sleep 1

# AND we make some new changes
rm $source_root/file2
files="file1 dir1/file3 dir2/file5 dir3/file11 dir3/sub_dir1/file9"
for file in $files; do
    echo "second change" > $source_root/$file
done
echo "new file" > "$source_root/dir3/new-file-no-backup"

# AND we take another backup
./blubee -b "$backup_json" backup

# WHEN we restore the backup
./blubee -b "$backup_json" -c "$config_path" -n "$name_one" -d "$first_backup_datetime" restore

# THEN blubee runs without error
test_results="$?"

# AND the restored source directory has the expected files, content and structure
test_results="$test_results $(assert_dirs_equal "$source_root" "$test_dir/date_specific_restore_after_change.expected")"

echo "date_specific_restore_after_change.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
[ -e "$destination" ] && rm -r "$destination"
rm "$backup_json"
[ -e "$source_root" ] && rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"

