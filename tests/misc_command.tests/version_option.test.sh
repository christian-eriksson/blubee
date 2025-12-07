#!/bin/sh

script_name="version_option.test.sh"
relative_dir="${0%/*}"
cd $relative_dir
test_dir="$(pwd)"
cd ..
test_root="$(pwd)"
cd $test_dir

. ../test_utils.sh

blubee_script=$test_dir/blubee-version_option
blubee_result=$test_dir/version_option.result
blubee_info=$test_dir/blubee.info

# GIVEN a blubee script
cp ../../blubee $blubee_script

# AND it's dependencies
cp ../../debug.sh $test_dir

# AND a blubee.info file next to the script
echo "some info for blubee to display" > $blubee_info

# WHEN we run blubee with the -v option
output=$($blubee_script -v)
exit_code="$?"

# AND we save the output
echo $output > $blubee_result

# THEN blubee ran without chrashing
test_results="$exit_code"

# AND blubee outputs the blubee.info config
test_results="$test_results $(assert_equal_files $blubee_info $blubee_result)"

echo "$script_name\nRESULTS:"
echo "$(asserts_to_text "$test_results")"

# clean up
rm "$blubee_result"
rm "$blubee_info"
rm "$blubee_script"
rm "$test_dir/debug.sh"

