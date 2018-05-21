#!/bin/bash
tmux send-keys -t SimpleSnippetsTest "nvim -u ../testrc for.c" enter "i/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */" escape ":x! for_test_result.c" enter
