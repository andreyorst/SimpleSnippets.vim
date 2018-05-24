test_file=jumping.c
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir! > $log_file" enter
}
test_func() {
    tmux send-keys -t $tmux_session "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "100" tab ">" tab "--" tab "char" tab "// for body" tab enter "/* test end */Qq"
}
after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":x" enter
}
