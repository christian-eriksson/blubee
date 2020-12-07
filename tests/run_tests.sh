#!/bin/sh

relative_dir="${0%/*}"
cd $relative_dir

# create backups
test_scripts=$(find ./ -type f -regex ".*\.test\.sh")

passed=0
failed=0
for test_script in $test_scripts; do
    results=$(eval $test_script 2> /dev/null | grep -e "^PASS$" -e "^FAIL$")
    echo "\033[1mRESULTS:\033[m"
    echo "\033[1m$test_script\033[m"
    for result in $results; do
        if [ "$result" = "PASS" ]; then
            echo "\033[1m\033[38;5;2m$result\033[m"
            passed=$((passed + 1))
        fi

        if [ "$result" = "FAIL" ]; then
            echo "\033[1m\033[38;5;9m$result\033[m"
            failed=$((failed + 1))
        fi
    done
    echo ""
done

echo "\033[1mRESULT SUMMARY:\033[m"
echo "\033[1m\033[38;5;2m$passed tests passed\033[m"
echo "\033[1m\033[38;5;9m$failed tests failed\033[m"

