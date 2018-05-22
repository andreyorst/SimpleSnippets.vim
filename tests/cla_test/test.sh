#!/bin/bash
echo $(pwd)
tmux send-keys -t SimpleSnippetsTest "nvim -u tests/testrc tests/cla_test/cla.cpp" enter "i/* test start */" enter "cla" escape "a" tab "travis" tab "TRAVIS_H" tab "int trav" c-k c-k "SimpleSnippets" c-j "char simple" c-j "SIMPLE_SNIPPETS_H" tab tab enter "/* test end */" escape ":x! tests/cla_test/cla_test_result.cpp" enter

SHA_REF=$(sha256sum tests/cla_test/cla_test_reference.cpp | sed -E "s/(\w+).*/\1/")
SHE_RES=$(sha256sum tests/cla_test/cla_test_result.cpp | sed -E "s/(\w+).*/\1/")

if [[ $SHA_REF != $SHA_RES ]]; then
    echo "[ERR]: cla test"
    exit 1
else
    echo "[OK]: cla test"
    exit 0
fi
