#!/bin/bash
cd for_test
tmux send-keys -t SimpleSnippetsTest "nvim -u ./testrc for.c" enter "i/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */" escape ":x! for_test_result.c" enter
[[ $(sha256sum for_test_reference.c | sed -E "s/(\w+).*/\1/") == $(sha256sum for_test_result.c | sed -E "s/(\w+).*/\1/") ]]
cd ..
