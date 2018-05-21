#!/bin/bash
tmux send-keys -t SimpleSnippetsTest "nvim -u tests/testrc tests/cla_test/cla.cpp" enter "i/* test start */" enter "cla" escape "a" tab "travis" tab "TRAVIS_H" tab "int trav" c-k c-k "SimpleSnippets" c-j "char simple" c-j "SIMPLE_SNIPPETS_H" tab tab enter "/* test end */" escape ":x! tests/cla_test/cla_test_result.c" enter
[[ $(sha256sum tests/cla_test/cla_test_reference.c | sed -E "s/(\w+).*/\1/") == $(sha256sum tests/cla_test/cla_test_result.c | sed -E "s/(\w+).*/\1/") ]]
