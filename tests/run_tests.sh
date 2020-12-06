#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

# create backups
test_script="./create_backups.tests/simple_backup.test.sh"
results=$(eval $test_script | grep -e "^PASS$" -e "^FAIL$")
echo "RESULTS:"
echo "$test_script"
for result in $results; do
    echo $result
done
