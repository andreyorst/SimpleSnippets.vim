#!/bin/bash
ERROR=0
tmux new-session -d -n SimpleSnippetsTest
tests/for_test/test.sh || ERROR=$[ $ERROR + 1 ]
pkill tmux
exit $ERROR
