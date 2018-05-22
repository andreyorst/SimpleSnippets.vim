#!/bin/bash
ERROR=0
cd tests
vim_versions=("nvim" "vim")
for vim in ${vim_versions[*]}; do
    echo "Running tests for: $vim"
    for_test/test.sh $vim || ERROR=$[ $ERROR + 1 ]
    cla_test/test.sh $vim || ERROR=$[ $ERROR + 1 ]
done
exit $ERROR
