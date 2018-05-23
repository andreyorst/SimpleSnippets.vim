test_file=lorem
before_test() {
    touch $test_file
}
test_func() {
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter "ggdGitest start" enter "lorem" escape "a" tab "otest endQw"
}
after_test() {
    return
}
