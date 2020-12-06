#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

# create backups
test_scripts="
./create_backups.tests/simple_backup.test.sh
./create_backups.tests/consecutive_backups.test.sh
./restore_backups.tests/simple_restore.test.sh
"

for test_script in $test_scripts; do
    results=$(eval $test_script 2> /dev/null | grep -e "^PASS$" -e "^FAIL$")
    echo "\033[1mRESULTS:\033[m"
    echo "\033[1m$test_script\033[m"
    for result in $results; do
        if [ "$result" = "PASS" ]; then
            echo "\033[1m\033[38;5;2m$result\033[m"
        fi

        if [ "$result" = "FAIL" ]; then
            echo "\033[1m\033[38;5;9m$result\033[m"
        fi
    done
done
