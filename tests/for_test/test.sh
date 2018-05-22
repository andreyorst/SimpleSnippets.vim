#!/bin/bash
ref_file=for_ref.c
test_file=for.c
log=log.txt
start_size=$(stat -c %s $test_file)
tmux_session=SimpleSnippetsTest

cd for_test/
touch $test_file
tmux new-session -d -n $tmux_session
tmux send-keys -t SimpleSnippetsTest "$1 -n -u ../testrc $test_file" enter "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */Qw"

while [[ $start_size == $(stat -c %s $test_file) ]]; do
    sleep 0.1
done

sha_ref=$(sha256sum $ref_file | sed -E "s/(\w+).*/\1/")
sha_res=$(sha256sum $test_file | sed -E "s/(\w+).*/\1/")

if [[ $sha_ref != $sha_res ]]; then
    echo "[ERR]: for test"
    mv $test_file $log
    error=1
else
    echo "[OK]: for test"
    rm $test_file
    error=0
fi

tmux kill-window -t $tmux_session
cd ..
exit $error
