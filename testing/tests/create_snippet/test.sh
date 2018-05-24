test_file=snippet
test_snippet_file=create
before_test() {
    touch $test_file
    tmux send-keys -t $tmux_session "$vim -n -u ../../testrc $test_file" enter ":redir! > $log_file" enter
}

test_func() {
    tmux send-keys -t SimpleSnippetsTest "ggdGitest start" enter "Qq:SimpleSnippetsEdit $test_snippet_file" enter "ggdGi$\\{0:SimpleSnippets\}Qq0f\\xf\\x:wq" enter "i$test_snippet_file" escape "a" tab tab enter "test endQq"
}

after_test() {
    tmux send-keys -t $tmux_session ":redir END" enter ":x" enter
    while [[ $(stat -c %s $test_file) == 0 ]]; do
        sleep 0.1
        ((--timeout))
        if [[ $timeout == 0 ]]; then
            echo "Timeout reached on deliting $test_snippet_file"
            break
        fi
    done
    rm ../../snippets/all/$test_snippet_file
}
