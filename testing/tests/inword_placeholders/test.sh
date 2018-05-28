test_file=for.c
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir > $log_file" enter
}
test_func() {
    tmux send-keys -t $tmux_session "ggdGitest start" enter "inword" escape "a" tab "Simp" tab "Snipp" c-k "Simple" tab "Snippets" tab enter "test endQq"
}
after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":x" enter
}

