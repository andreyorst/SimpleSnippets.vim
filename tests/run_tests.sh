#!/bin/bash
ERROR=0
echo "Starting tmux session"
tmux new-session -d -n SimpleSnippetsTest

echo "Running tests"
tests/for_test/test.sh || ERROR=$[ $ERROR + 1 ]
tests/cla_test/test.sh || ERROR=$[ $ERROR + 1 ]

pkill tmux
exit $ERROR
