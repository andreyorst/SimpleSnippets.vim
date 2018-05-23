test_file=shell.c
before_test() {
    touch $test_file
}
test_func() {
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter "ggdGitest start" enter "echo" escape "a" tab tab enter "test endQw"
}
after_test() {
    return
}
