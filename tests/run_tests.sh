#!/bin/bash
tmux new-session -n SimpleSnippetsTest
./for_test/test.sh || ERROR=1
return $ERROR
