#!/bin/bash
ERROR=0
cd for_test/
touch for_test_result.c

tmux new-session -d -n SimpleSnippetsTest
tmux send-keys -t SimpleSnippetsTest "nvim -u ../testrc for_test_result.c" enter "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */" escape ":x" enter

sleep 1

SHA_REF=$(sha256sum for_test_reference.c | sed -E "s/(\w+).*/\1/")
SHA_RES=$(sha256sum for_test_result.c | sed -E "s/(\w+).*/\1/")

if [[ $SHA_REF != $SHA_RES ]]; then
    echo "[ERR]: for test"
    mv for_test_result.c log
    ERROR=1
else
    echo "[OK]: for test"
    rm for_test_result.c
fi

tmux kill-window -t SimpleSnippetsTest
cd ..
exit $ERROR
