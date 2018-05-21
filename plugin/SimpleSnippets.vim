" Settings
if !exists('g:SimpleSnippets_search_path')
	let g:SimpleSnippets_search_path = $HOME . '/.vim/snippets/'
endif

let s:allow_remap = 1

if exists('g:SimpleSnippets_dont_remap_tab')
	if g:SimpleSnippets_dont_remap_tab == 0
		let s:allow_remap = 1
	else
		let s:allow_remap = 0
	endif
endif

if !exists('g:SimpleSnippetsExpandOrJumpTrigger')
	let g:SimpleSnippetsExpandOrJumpTrigger = "<Tab>"
endif

if !exists('g:SimpleSnippetsJumpBackwardTrigger')
	let g:SimpleSnippetsJumpBackwardTrigger = "<S-Tab>"
endif

if !exists('g:SimpleSnippetsJumpToLastTrigger')
	let g:SimpleSnippetsJumpToLastTrigger = "<C-j>"
endif

if s:allow_remap == 1
	exec "nnoremap <silent><expr>".g:SimpleSnippetsExpandOrJumpTrigger.' SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\'.g:SimpleSnippetsExpandOrJumpTrigger.'"'
	exec "inoremap <silent><expr>".g:SimpleSnippetsExpandOrJumpTrigger.' SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\'.g:SimpleSnippetsExpandOrJumpTrigger.'"'
	exec "snoremap <silent><expr>".g:SimpleSnippetsExpandOrJumpTrigger.' SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\'.g:SimpleSnippetsExpandOrJumpTrigger.'"'
	exec "nnoremap <silent><expr>".g:SimpleSnippetsJumpBackwardTrigger.' SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpBackwards()<Cr>" : "\'.g:SimpleSnippetsJumpBackwardTrigger.'"'
	exec "inoremap <silent><expr>".g:SimpleSnippetsJumpBackwardTrigger.' SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpBackwards()<Cr>" : "\'.g:SimpleSnippetsJumpBackwardTrigger.'"'
	exec "snoremap <silent><expr>".g:SimpleSnippetsJumpBackwardTrigger.' SimpleSnippets#isJumpable() ? "<Esc>:call SimpleSnippets#jumpBackwards()<Cr>" : "\'.g:SimpleSnippetsJumpBackwardTrigger.'"'
	exec "nnoremap <silent><expr>".g:SimpleSnippetsJumpToLastTrigger.' SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\'.g:SimpleSnippetsJumpToLastTrigger.'"'
	exec "inoremap <silent><expr>".g:SimpleSnippetsJumpToLastTrigger.' SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\'.g:SimpleSnippetsJumpToLastTrigger.'"'
	exec "snoremap <silent><expr>".g:SimpleSnippetsJumpToLastTrigger.' SimpleSnippets#isJumpable() ? "<Esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\'.g:SimpleSnippetsJumpToLastTrigger.'"'
endif

let s:similar_filetypes = [['tex', 'plaintex'], ['bash', 'zsh', 'sh']]

if exists('g:SimpleSnippets_similar_filetypes')
	let g:SimpleSnippets_similar_filetypes += s:similar_filetypes
else
	let g:SimpleSnippets_similar_filetypes = s:similar_filetypes
endif

command! -nargs=? SimpleSnippetsEdit call SimpleSnippets#edit("<args>")
command! SimpleSnippetsList call SimpleSnippets#listSnippets()

