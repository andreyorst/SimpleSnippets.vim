test_file=jumping.c
before_test() {
    touch $test_file
}
test_func() {
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter "ggdGi/* test start */" enter "for" escape "a" tab c-j "// for body" c-k "char" c-k "--" c-k ">" c-k "100" c-k "j" c-k "0" c-j tab enter "/* test end */Qw"
}
after_test() {
    return
}
