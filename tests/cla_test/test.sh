#!/bin/bash
ERROR=0
cd cla_test/
touch cla_test_result.cpp

tmux new-session -d -n SimpleSnippetsTest
tmux send-keys -t SimpleSnippetsTest "nvim -u ../testrc cla_test_result.cpp" enter "ggdGi/* test start */" enter "cla" escape "a" tab "travis" tab "TRAVIS_H" tab "int trav" c-k c-k "SimpleSnippets" c-j "char simple" c-k "SIMPLE_SNIPPETS_H" tab tab enter "/* test end */" escape ":x" enter

sleep 1

SHA_REF=$(sha256sum cla_test_reference.cpp | sed -E "s/(\w+).*/\1/")
SHA_RES=$(sha256sum cla_test_result.cpp | sed -E "s/(\w+).*/\1/")

if [[ $SHA_REF != $SHA_RES ]]; then
    echo "[ERR]: cla test"
    mv cla_test_result.cpp log
    ERROR=1
else
    echo "[OK]: cla test"
    rm cla_test_result.cpp
fi

tmux kill-window -t SimpleSnippetsTest
cd ..
exit $ERROR
