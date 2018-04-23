" Settings
if !exists('g:SimpleSnippets_search_path')
	let g:SimpleSnippets_search_path = $HOME . '/.vim/snippets/'
endif

if !exists('g:SimpleSnippets_dont_remap_tab')
	nnoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	inoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	inoremap <silent><expr><S-Tab> SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\<S-Tab>"
	snoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	snoremap <silent><expr><S-Tab> SimpleSnippets#isJumpable() ? "<Esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\<S-Tab>"
endif

if !exists('g:SimpleSnippets_similar_filetypes')
	let g:SimpleSnippets_similar_filetypes = [['tex', 'plaintex'], ['bash', 'zsh', 'sh']]
endif

command! SimpleSnippetsEdit call SimpleSnippets#edit()

