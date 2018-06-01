test_file=visual
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir > $log_file" enter
}
test_func() {
    tmux send-keys -t $tmux_session "ggdGitest start" enter "SimpleSnippetsQqV" tab "vis" escape "a" tab tab enter "test endQq"
}
after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":x" enter
}
