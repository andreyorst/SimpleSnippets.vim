test_file=flash.c
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir! > $log_file" enter
}

test_func() {
    tmux send-keys -t $tmux_session ":call SimpleSnippets#addFlashSnippet('flash_test', 'flash_test(\${1:a}, \${0:b})')" enter "ggdGi/* test start */" enter "flash_test" escape "a" tab "simple" tab "snippets" tab "\;" enter "/* test end */Qq"
}

after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":x" enter
}
