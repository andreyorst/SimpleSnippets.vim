let s:trigger = ''

function! SimpleSnippets#core#getTrigger()
	return s:trigger
endfunction

function! SimpleSnippets#core#isExpandable()
	let s:trigger = SimpleSnippets#input#getText()
	if s:GetSnippetFiletype(s:trigger) != -1
		return 1
	endif
	let s:trigger =  s:ObtainTrigger()
	if s:GetSnippetFiletype(s:trigger) != -1
		return 1
	endif
	let s:trigger = s:ObtainAlternateTrigger()
	if s:GetSnippetFiletype(s:trigger) != -1
		return 1
	endif
	let s:trigger = ''
	return 0
endfunction

function! s:ObtainTrigger()
	if s:trigger == ''
		if mode() == 'i'
			let l:cursor_pos = getpos(".")
			call cursor(line('.'), col('.') - 1)
			let l:trigger = expand("<cWORD>")
			call cursor(l:cursor_pos[1], l:cursor_pos[2])
		else
			let l:trigger = expand("<cWORD>")
		endif
	endif
	return l:trigger
endfunction

function! s:ObtainAlternateTrigger()
	if mode() == 'i'
		let l:cursor_pos = getpos(".")
		call cursor(line('.'), col('.') - 1)
		let l:trigger = expand("<cword>")
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	else
		let l:trigger = expand("<cword>")
	endif
	return l:trigger
endfunction

function! s:GetSnippetFiletype(snip)
	call s:CheckExternalSnippetPlugin()
	let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	if filereadable(g:SimpleSnippets_search_path . l:filetype . '/' . a:snip)
		return l:filetype
	endif
	if s:checkFlashSnippetExists(a:snip)
		return 'flash'
	endif
	if s:snippetPluginInstalled == 1
		let l:plugin_filetype = s:GetMainFiletype(g:SimpleSnippets_snippets_similar_filetypes)
		if filereadable(g:SimpleSnippets_snippets_plugin_path . l:plugin_filetype . '/' . a:snip)
			return l:plugin_filetype
		endif
	endif
	if filereadable(g:SimpleSnippets_search_path . 'all/' . a:snip)
		return 'all'
	endif
	if s:snippetPluginInstalled == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . 'all/' . a:snip)
			return 'all'
		endif
	endif
	return -1
endfunction

function! s:CheckExternalSnippetPlugin()
	if exists('g:SimpleSnippets_snippets_plugin_path')
		let s:snippetPluginInstalled = 1
	else
		let s:snippetPluginInstalled = 0
	endif
endfunction

function! s:GetMainFiletype(similar_filetypes)
	let l:ft = &ft
	if l:ft == ''
		return 'all'
	endif
	for l:filetypes in a:similar_filetypes
		if index(l:filetypes, l:ft) != -1
			return l:filetypes[0]
		endif
	endfor
	return l:ft
endfunction

" 7.4 compability layer
function! SimpleSnippets#core#execute(command, ...)
	if a:0 != 0
		let l:silent = a:1
	else
		let l:silent = ""
	endif
	if exists("*execute")
		let l:result = execute(a:command, l:silent)
	else
		redir => l:result
		if l:silent == "silent"
			silent execute a:command
		elseif l:silent == "silent!"
			silent! execute a:command
		else
			execute a:command
		endif
		redir END
	endif
	return l:result
endfunction

function! s:checkFlashSnippetExists(snip)
	if has_key(s:flash_snippets, a:snip)
		return 1
	endif
	return 0
endfunction

