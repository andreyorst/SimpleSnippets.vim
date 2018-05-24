test_file=for.c
before_test() {
    touch $test_file
}
test_func() {
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */Qw"
}
after_test() {
    return
}
