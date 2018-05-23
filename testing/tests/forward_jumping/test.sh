test_file=jumping.c
before_test() {
    touch $test_file
}
test_func() {
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "100" tab ">" tab "--" tab "char" tab "// for body" tab enter "/* test end */Qw"
}
after_test() {
    return
}
