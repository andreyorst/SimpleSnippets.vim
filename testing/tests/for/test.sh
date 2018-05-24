test_file=for.c
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir => log" enter
}
test_func() {
    tmux send-keys -t $tmux_session "ggdGi/* test start */" enter "for" escape "a" tab "22" tab "j" tab "10" c-k c-k "0" tab "l" tab "100" tab ">" tab "--" c-j "while body" c-k "char" tab "// for body" tab enter "/* test end */Qq"
}
after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":let @\" = log" enter "p:x" enter
}
