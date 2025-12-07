#!/bin/sh

script_name="passing_args_to_blubee.test.sh"
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

# AND a config path
config_path="a/config/path/"

# AND some dummy option
dummy_option="-8 dummy"

# AND some command
command="some_command"

# AND some dummy command
dummy_command="dummy"

# WHEN we run blubee with config and backup
output=$(./launcher -c "$config_path" -b "$backup_json")
exit_code="$?"

# THEN launcher ran without crashing
test_results="$(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the expected arguments to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c $config_path" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

backup_json_option_count=$(echo "$output" | grep -e "blubee.*-b $backup_json" | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_json_option_count" 1)"

dummy_option_count=$(echo "$output" | grep -e "blubee.*$dummy_option" | wc -l)
test_results="$test_results $(assert_equal_numbers "$dummy_option_count" 0)"

# WHEN we run blubee with only config
output=$(./launcher -c "$config_path")
exit_code="$?"

# THEN launcher ran without crashing
test_results="$test_results $(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the expected arguments to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c $config_path" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

backup_json_option_count=$(echo "$output" | grep -e "blubee.*-b $backup_json" | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_json_option_count" 0)"

dummy_option_count=$(echo "$output" | grep -e "blubee.*$dummy_option" | wc -l)
test_results="$test_results $(assert_equal_numbers "$dummy_option_count" 0)"

# WHEN we run blubee with only config and dummy option
output=$(./launcher -c "$config_path" $dummy_option)
exit_code="$?"

# THEN launcher ran without crashing
test_results="$test_results $(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the expected arguments to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c $config_path" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

backup_json_option_count=$(echo "$output" | grep -e "blubee.*-b $backup_json" | wc -l)
test_results="$test_results $(assert_equal_numbers "$backup_json_option_count" 0)"

dummy_option_count=$(echo "$output" | grep -e "blubee.*$dummy_option" | wc -l)
test_results="$test_results $(assert_equal_numbers "$dummy_option_count" 1)"

# WHEN we run blubee with a command
output=$(./launcher -c "$config_path" $command)
exit_code="$?"

# THEN launcher ran without crashing
test_results="$test_results $(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the expected arguments to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c $config_path" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

command_count=$(echo "$output" | grep -e "blubee.*$command" | wc -l)
test_results="$test_results $(assert_equal_numbers "$command_count" 1)"

dummy_command_count=$(echo "$output" | grep -e "blubee.*$dummy_command" | wc -l)
test_results="$test_results $(assert_equal_numbers "$dummy_command_count" 0)"

# WHEN we run blubee with two commands
output=$(./launcher -c "$config_path" $dummy_command $command)
exit_code="$?"

# THEN launcher ran without crashing
test_results="$test_results $(assert_equal_numbers "$exit_code" 0)"

# AND launcher passed the expected arguments to blubee
config_option_count=$(echo "$output" | grep -e "blubee.*-c $config_path" | wc -l)
test_results="$test_results $(assert_equal_numbers "$config_option_count" 1)"

command_count=$(echo "$output" | grep -e "blubee.*$command" | wc -l)
test_results="$test_results $(assert_equal_numbers "$command_count" 1)"

dummy_command_count=$(echo "$output" | grep -e "blubee.*$dummy_command" | wc -l)
test_results="$test_results $(assert_equal_numbers "$dummy_command_count" 1)"
echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

rm $test_dir/launcher
