#!/bin/sh

script_name="passing_no_config_to_launcher.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh
activate_blubee_mock ../../launcher $test_dir/launcher

# GIVEN a test json path
backup_json="some/backup/json"

# AND some command
command="some_command"

# WHEN we run blubee without config
output=$(./launcher -b "$backup_json" $command)
exit_code="$?"

# THEN launcher ran without crashing
test_results="$(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the default config to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c /etc/blubee/blubee.conf" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

# AND the other options are passed as expected
backup_json_option_count=$(echo "$output" | grep -e "blubee.*-b $backup_json" | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_json_option_count" 1)"

command_count=$(echo "$output" | grep -e "blubee.*$command" | wc -l)
test_results="$test_results $(assert_equal_numbers "$command_count" 1)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

rm $test_dir/launcher
