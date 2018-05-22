#!/bin/bash
error=0
verbose=1
vim_versions=("nvim" "vim")

cd tests
for vim in ${vim_versions[*]}; do
    echo -n "Running tests for $vim:"
    [[ $verbose != 0 ]] && echo

    lorem_test/test.sh $vim $verbose || error=$[ $error + 1 ]
    for_test/test.sh $vim $verbose || error=$[ $error + 1 ]
    cla_test/test.sh $vim $verbose || error=$[ $error + 1 ]

    if [[ $verbose == 0 ]]; then
        if [[ $error == 0 ]]; then
            echo " OK"
        else
            echo " Error"
        fi
    fi
done
exit $error
