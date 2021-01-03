#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

. ../test_utils.sh

test_dir="$(pwd)"
backup_json="$test_dir/backup_with_unorthodox_characters_in_path.backup.json"
config_path="$test_dir/../test_config"

# GIVEN a test json
destination="$test_dir/backup_with_unorthodox_characters_in_path.result"
name=simple
root="$test_dir/test_files_weird_paths_root"
json=$(cat << EOM
{
    "backup_destination": "$destination",
    "backup_configs": [
        {
            "name": "$name",
            "root": "$root",
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

# WHEN we run blubee
cd ../..
./blubee -c "$config_path" -b "$backup_json" backup
exit_code=$?

# THEN blubee ran without exception
test_results="$exit_code"

# AND there are two files/directories in the backup directory
result_dir="$destination/$name"
test_results="$test_results $(assert_files_in_dir "$result_dir" 2)"

# and one of the directories has a name similar to a date stamp
test_results="$test_results $(assert_datetime_dir_count "$result_dir" 1)"

# and the latest backup is a link
test_results="$test_results $(assert_is_link "$result_dir/latest")"

# and the latest backup has the expected content
has_same_content=$(assert_dirs_equal "$result_dir/latest" "$test_dir/backup_with_unorthodox_characters_in_path.expected")
test_results="$test_results $has_same_content"

echo "backup_with_unorthodox_characters_in_path.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm -r "$test_dir/backup_with_unorthodox_characters_in_path.result"
rm "$backup_json"

