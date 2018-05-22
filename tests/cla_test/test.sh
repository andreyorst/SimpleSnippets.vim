#!/bin/bash
ref_file=cla_ref.cpp
test_file=cla.cpp
log=log.txt
start_size=$(stat -c %s $test_file)
tmux_session=SimpleSnippetsTest

cd cla_test/
touch $test_file
tmux new-session -d -n $tmux_session
tmux send-keys -t SimpleSnippetsTest "$1 -n -u ../testrc $test_file" enter "ggdGi/* test start */" enter "cla" escape "a" tab "travis" tab "TRAVIS_H" tab "int trav" c-k c-k "SimpleSnippets" c-j "char simple" c-k "SIMPLE_SNIPPETS_H" tab tab enter "/* test end */Qw"

while [[ $start_size == $(stat -c %s $test_file) ]]; do
    sleep 0.1
done

sha_ref=$(sha256sum $ref_file | sed -E "s/(\w+).*/\1/")
sha_res=$(sha256sum $test_file | sed -E "s/(\w+).*/\1/")

if [[ $sha_ref != $sha_res ]]; then
    echo "[ERR]: cla test"
    mv $test_file $log
    error=1
else
    echo "[OK]: cla test"
    rm $test_file
    error=0
fi

tmux kill-window -t $tmux_session
cd ..
exit $error
