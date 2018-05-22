#!/bin/bash
ERROR=0
cd tests
echo "Running tests:"
vim=nvim
for_test/test.sh $vim || ERROR=$[ $ERROR + 1 ]
cla_test/test.sh $vim || ERROR=$[ $ERROR + 1 ]
exit $ERROR
