#!/bin/bash
error=0
verbose=1
vim_versions=("nvim" "vim")
tests=("lorem_test" "for_test" "cla_test")

cd tests
for vim in ${vim_versions[*]}; do
    echo -n "Running tests for $vim:"
    [[ $verbose != 0 ]] && echo

    for test in ${tests[*]}; do
        $test/test.sh $vim $verbose || error=$[ $error + 1 ]
    done

    if [[ $verbose == 0 ]]; then
        if [[ $error == 0 ]]; then
            echo " OK"
        else
            echo " Error"
        fi
    fi
done
exit $error
