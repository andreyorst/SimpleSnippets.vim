test_file=cla.cpp
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir => log" enter
}

test_func() {
    tmux send-keys -t $tmux_session "ggdGi/* test start */" enter "cla" escape "a" tab "travis" tab "TRAVIS_H" tab "int trav" c-k c-k "SimpleSnippets" c-j "char simple" c-k "SIMPLE_SNIPPETS_H" tab tab enter "/* test end */Qq"
}

after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":let @\" = log" enter "p:x" enter
}
