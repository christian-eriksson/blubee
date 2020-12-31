#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

# WHEN we run blubee with the -h option
cd ../..
output=$(./blubee -h)
exit_code="$?"

# THEN blubee ran without chrashing
test_results="$exit_code"

# AND blubee outputs a usage prompt
usage_output_count=$(echo "$output" | grep -e "usage: blubee \[-c <config-file>\] -b <backup.json> \[options\] <command>" | wc -l)
test_results="$test_results $(assert_greater_than "$usage_output_count" 0)"

echo "remote_destination_host_only_single_backup.test.sh\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

