#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../../string_utils.sh
. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/date_specific_restore_after_delete.backup.json"

# GIVEN a test backup json
name_one="date-specific-one"
name_two="date-specific-two"
destination="$test_dir/date_specific_restore_after_delete.source"
source_root="$test_dir/date_specific_restore_after_delete.result"
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
config_path="$test_dir/date_specific_restore_after_delete.config"
restore_backup_copy_path="$test_dir/date_specific_restore_after_delete.restore_backup"
mkdir $restore_backup_copy_path
echo "\
RESTORE_BACKUP_COPY=$restore_backup_copy_path
" > $config_path

# AND the source root contains some content
cp -r "$test_dir/test_files_root" "$source_root"

# AND we have created a backup
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup

# AND we note the date of the first backup
first_backup_datetime=$(get_a_backup_datetime "$destination/$name_two")

# AND we wait for a bit
sleep 1

# AND made a few changes in the directory
mkdir "$source_root/dir1/sub_dir/new-dir"
files="file1 dir2/file5 dir1/sub_dir/file7"
for file in $files; do
    echo "first change" > $source_root/$file
done
echo "new file" > "$source_root/dir2/sub_dir/new-file"
echo "new file" > "$source_root/dir1/sub_dir/new-dir/a_new_file"
rm "$source_root/dir2/file4"

# AND we take another backup
./blubee -c "$config_path" -b "$backup_json" backup

# AND we accidentally deleted the original directory
rm -r $source_root

# WHEN we restore the backup with name two and from first datetime
./blubee -b "$backup_json" -c "$config_path" -n "$name_two" -d "$first_backup_datetime" restore

# THEN blubee runs without error
test_results="$?"

# AND the restored source directory has the expected files, content and structure
test_results="$test_results $(assert_dirs_equal "$source_root" "$test_dir/date_specific_restore_after_delete.expected")"

echo "date_specific_restore_after_delete.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$destination"
rm "$backup_json"
[ -e "$source_root" ] && rm -r "$source_root"
rm -r "$restore_backup_copy_path"
rm "$config_path"

