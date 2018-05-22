#!/bin/bash
touch tests/for_test/for_test_result.c
tmux send-keys -t SimpleSnippetsTest "nvim -u tests/testrc tests/for_test/for_test_result.c" enter "i/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */" escape ":w tests/for_test/for_test_result.c" enter

SHA_REF=$(sha256sum tests/for_test/for_test_reference.c | sed -E "s/(\w+).*/\1/")
SHE_RES=$(sha256sum tests/for_test/for_test_result.c | sed -E "s/(\w+).*/\1/")

if [[ $SHA_REF != $SHA_RES ]]; then
    echo "[ERR]: for test"
    exit 1
else
    echo "[OK]: for test"
    exit 0
fi
