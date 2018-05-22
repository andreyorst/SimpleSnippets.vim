#!/bin/bash
ERROR=0
cd tests
echo "Running tests:"
for_test/test.sh || ERROR=$[ $ERROR + 1 ]
cla_test/test.sh || ERROR=$[ $ERROR + 1 ]
exit $ERROR
