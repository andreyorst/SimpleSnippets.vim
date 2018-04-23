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

if s:allow_remap == 1
	nnoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	inoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	inoremap <silent><expr><S-Tab> SimpleSnippets#isJumpable() ? "<esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\<S-Tab>"
	snoremap <silent><expr><Tab> SimpleSnippets#isExpandableOrJumpable() ? "<Esc>:call SimpleSnippets#expandOrJump()<Cr>" : "\<Tab>"
	snoremap <silent><expr><S-Tab> SimpleSnippets#isJumpable() ? "<Esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>" : "\<S-Tab>"
endif

let s:similar_filetypes = [['tex', 'plaintex'], ['bash', 'zsh', 'sh']]

if exists('g:SimpleSnippets_similar_filetypes')
	let g:SimpleSnippets_similar_filetypes += s:similar_filetypes
else
	let g:SimpleSnippets_similar_filetypes = s:similar_filetypes
endif

command! SimpleSnippetsEdit call SimpleSnippets#edit()

