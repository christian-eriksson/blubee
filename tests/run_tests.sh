#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

# create backups
test_scripts="
./create_backups.tests/simple_backup.test.sh
./create_backups.tests/consecutive_backups.test.sh
"

for test_script in $test_scripts; do
    results=$(eval $test_script | grep -e "^PASS$" -e "^FAIL$")
    echo "RESULTS:"
    echo "$test_script"
    for result in $results; do
        echo $result
    done
done
