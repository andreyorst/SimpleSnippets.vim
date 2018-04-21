" Globals
let s:ph_contents = []
let s:ph_types = []
let s:ph_amount = 0
let s:jumped_ph = 0
let s:active = 0
let s:snip_start = 0
let s:snip_end = 0
let s:snip_line_count = 0
let s:current_file = ''
let s:snip_edit_buf = 0
let s:snip_edit_win = 0


if !exists('g:SimpleSnippets_search_path')
	let g:SimpleSnippets_search_path = $HOME . '/.vim/snippets/'
endif

function! SimpleSnippets#isExpandable()
	let l:mode = mode()
	let l:snip = ''
	if l:mode == 'i'
		let l:col = col('.') - 1
		let l:snip = matchstr(getline('.'), '\v\w+%' . l:col . 'c.')
	else
		let l:snip = expand("<cword>")
	endif
	if SimpleSnippets#getSnipFileType(l:snip) != -1
		return 1
	else
		return 0
	endif
endfunction

function! SimpleSnippets#isExpandableOrJumpable()
	if SimpleSnippets#isExpandable()
		return 1
	elseif SimpleSnippets#isJumpable()
		return 1
	else
		return 0
	endif
endfunction

function! SimpleSnippets#isInside()
	if SimpleSnippets#isActive()
		if s:current_file == @%
			if line(".") >= s:snip_start && line(".") <= s:snip_end
				return 1
			else
				return 0
			endif
		else
			let s:active = 0
		endif
	endif
	let s:active = 0
	return 0
endfunction

function! SimpleSnippets#isActive()
	if s:active == 1
		return 1
	else
		return 0
	endif
endfunction

function! SimpleSnippets#isJumpable()
	if SimpleSnippets#isInside()
		if SimpleSnippets#isActive()
			return 1
		endif
	endif
	let s:active = 0
	return 0
endfunction

function! SimpleSnippets#expandOrJump()
	if SimpleSnippets#isExpandable()
		call SimpleSnippets#expand()
	elseif SimpleSnippets#isJumpable()
		call SimpleSnippets#jump()
	endif
endfunction

function! SimpleSnippets#expand()
	let l:snip = expand("<cword>")
	if SimpleSnippets#isExpandable()
		let l:filetype = SimpleSnippets#getSnipFileType(l:snip)
		let a:path = g:SimpleSnippets_search_path . l:filetype . '/' . l:snip
		let s:snip_line_count = 0
		for i in readfile(a:path)
			let s:snip_line_count +=1
		endfor
		if s:snip_line_count != 0
			normal! diw
			silent exec ':read' . a:path
			silent exec "normal! i\<Bs>"
			if s:snip_line_count != 1
				let l:indent_lines = s:snip_line_count - 1
				silent exec 'normal! V' . l:indent_lines . 'j='
			else
				normal! ==
			endif
			silent call SimpleSnippets#parseAndInit()
		else
			echo '[ERROR] Snippet body is empty'
		endif
	else
		echo '[ERROR] No "' . l:snip . '" snippet in ' . g:SimpleSnippets_search_path . &ft . '/'
	endif
endfunction

"Checks if snippet availible via current filetype, if not searches in all
"snippets. If snippet still not found returns -1
function! SimpleSnippets#getSnipFileType(snip)
	let l:filetype = SimpleSnippets#filetypeWrapper()
	if filereadable(g:SimpleSnippets_search_path . l:filetype . '/' . a:snip)
		return l:filetype
	elseif filereadable(g:SimpleSnippets_search_path . 'all/' . a:snip)
		return 'all'
	else
		echo "[ERROR] Can't" . ' find "' . a:snip . '" snippet in '. g:SimpleSnippets_search_path . l:filetype . '/'
		return -1
	endif
endfunction

function! SimpleSnippets#filetypeWrapper()
	let l:ft = &ft
	if l:ft == ''
		return 'all'
	elseif l:ft == 'tex' || l:ft == 'plaintex'
		 return 'tex'
	elseif l:ft == 'sh' || l:ft == 'bash' || l:ft == 'zsh'
		 return 'bash'
	endif
	return l:ft
endfunction

function! SimpleSnippets#parseAndInit()
	let a:cursor_pos = getpos(".")
	let s:ph_contents = []
	let s:ph_types = []
	let s:active = 1
	let s:jumped_ph = 0
	let g:snippet_end = 0
	let s:current_file = @%
	let s:ph_amount = SimpleSnippets#countPlaceholders('\v\$(\{)?[0-9]+(:|!|\|)?')
	if s:ph_amount != 0
		call SimpleSnippets#parseSnippet(s:ph_amount)
		call cursor(a:cursor_pos[1], a:cursor_pos[2])
		call SimpleSnippets#jump()
	else
		let s:active = 0
		call cursor(a:cursor_pos[1], a:cursor_pos[2])
	endif
endfunction

function! SimpleSnippets#countPlaceholders(pattern)
	redir => l:cnt
	silent! exe '%s/' . a:pattern . '//gn'
	redir END
	let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
	let l:count = substitute(l:count, '\v%^\_s+|\_s+%$', '', 'g')
	return l:count
endfunction

function! SimpleSnippets#parseSnippet(amount)
	let l:i = 1
	let l:current = l:i
	let s:snip_start = line(".")
	let s:snip_end = s:snip_start + s:snip_line_count - 1
	let l:type = 0
	while l:i <= a:amount
		call cursor(s:snip_start, 1)
		if l:i == a:amount
			let l:current = 0
		endif
		call search('\v\$(\{)?' . l:current . '(:)?', 'c')
		let l:type = SimpleSnippets#getPlaceholderType()
		call SimpleSnippets#initPlaceholder(l:current, l:type)
		let l:i += 1
		let l:current = l:i
	endwhile
endfunction

function! SimpleSnippets#Edit()
	let l:filetype = SimpleSnippets#filetypeWrapper()
	let l:path = g:SimpleSnippets_search_path . l:filetype
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	let l:trigger = input('Select a trigger: ')
	if l:trigger != ''
		if win_gotoid(s:snip_edit_win)
			execute "edit " . l:path . '/' . l:trigger
		else
			vertical new
			try
				exec "buffer " . s:snip_edit_buf
			catch
				execute "edit " . l:path . '/' . l:trigger
				let g:term_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	endif
endfunction

command! SimpleSnippetsEdit call SimpleSnippets#Edit()

function! SimpleSnippets#getPlaceholderType()
		if match(expand("<cWORD>"),'\v.*\$\{[0-9]+:') == 0
			return 1
		elseif match(expand("<cWORD>"), '\v.*\$\{[0-9]+\|') == 0
			return 2
		elseif match(expand("<cWORD>"),'\v.*\$\{[0-9]+!') == 0
			return 3
		endif
endfunction

function! SimpleSnippets#initPlaceholder(current, type)
	call add(s:ph_types, a:type)
	if a:type == 1
		call SimpleSnippets#initNormal(a:current)
	elseif a:type == 2
		call SimpleSnippets#initMirror(a:current)
	elseif a:type == 3
		call SimpleSnippets#initShell(a:current)
	endif
endfunction

function! SimpleSnippets#initNormal(current)
	let l:placeholder = '\v(\$\{'. a:current . ':)@<=.{-}(\})@='
	call add(s:ph_contents, matchstr(getline('.'), l:placeholder))
	exe "normal! df:f}i\<Del>\<Esc>"
endfunction

function! SimpleSnippets#initMirror(current)
	let l:placeholder = '\v(\$\{'. a:current . '\|)@<=.{-}(\})@='
	call add(s:ph_contents, matchstr(getline('.'), l:placeholder))
	exe "normal! df|f}i\<Del>\<Esc>"
endfunction

function! SimpleSnippets#initShell(current)
	let l:placeholder = '\v(\$\{'. a:current . '!)@<=.{-}(\})@='
	let l:command = matchstr(getline('.'), l:placeholder)
	let l:result = system(l:command)
	let l:result = substitute(l:result, '\n\+$', '', '')
	let @s = l:result
	exe "normal! df}"
	normal! "sp
	call add(s:ph_contents, l:result)
endfunction

function! SimpleSnippets#jump()
	if SimpleSnippets#isInside()
		let l:current_ph = escape(s:ph_contents[s:jumped_ph], '/\*')
		let l:current_jump = s:jumped_ph
		let s:jumped_ph += 1
		if s:jumped_ph == s:ph_amount
			let s:active = 0
			let s:jumped_ph = 0
		endif
		if match(s:ph_types[l:current_jump], '1') == 0
			call SimpleSnippets#jumpNormal(l:current_ph)
		elseif match(s:ph_types[l:current_jump], '2') == 0
			call SimpleSnippets#jumpMirror(l:current_ph)
		elseif match(s:ph_types[l:current_jump], '3') == 0
			call SimpleSnippets#jumpShell(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpToLastPlaceholder()
	if SimpleSnippets#isInside()
		let s:active = 0
		let l:current_ph = escape(s:ph_contents[-1], '/\*')
		if match(s:ph_types[-1], '1') == 0
			call SimpleSnippets#jumpNormal(l:current_ph)
		elseif match(s:ph_types[-1], '2') == 0
			call SimpleSnippets#jumpMirror(l:current_ph)
		elseif match(s:ph_types[-1], '3') == 0
			call SimpleSnippets#jumpShell(l:current_ph)
		endif
		let s:jumped_ph = 0
		let s:active = 0
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpNormal(placeholder)
	let ph = a:placeholder
	if ph !~ "\\W"
		let ph = '\<' . ph . '\>'
	endif
	call cursor(s:snip_start, 1)
	call search(ph, 'c', s:snip_end)
	normal! ms
	call search(ph, 'ce', s:snip_end)
	normal! me
	call feedkeys("`sv`e\<c-g>")
endfunction

function! SimpleSnippets#jumpMirror(placeholder)
	let ph = a:placeholder
	if ph =~ "\\W"
		echo '[ERROR] Placeholder "'.ph.'"'."can't be mirrored"
	else
		redir => l:cnt
		silent! exe s:snip_start.','.s:snip_end.'s/\<' . a:placeholder . '\>//gn'
		redir END
		noh
		let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
		let l:count = substitute(l:count, '\v%^\_s+|\_s+%$', '', 'g')
		let l:i = 0
		let l:matchpositions = []
		while l:i < l:count
			call search('\<' .ph .'\>', '', s:snip_end)
			let l:line = line('.')
			let l:start = col('.')
			call search('\<' .ph .'\>', 'ce', s:snip_end)
			let l:length = col('.') - l:start + 1
			call add(l:matchpositions, matchaddpos('Visual', [[l:line, l:start, l:length]]))
			let l:i += 1
		endwhile
		call cursor(s:snip_start, 1)
		call search('\<' .ph .'\>', 'c', s:snip_end)
		let a:cursor_pos = getpos(".")
		let l:reenable_cursorline = 0
		if &cursorline == 1
			set nocursorline
			let l:reenable_cursorline = 1
		endif
		redraw
		let l:rename = input('Replace placeholder "'.ph.'" with: ')
		if l:rename != ''
			execute s:snip_start . "," . s:snip_end . "s/\\<" . ph ."\\>/" . l:rename . "/g"
			noh
		endif
		let l:i = 0
		while l:i < l:count
			call matchdelete(l:matchpositions[l:i])
			let l:i += 1
		endwhile
		redraw
		call cursor(a:cursor_pos[1], a:cursor_pos[2])
		if l:reenable_cursorline == 1
			set cursorline
		endif
		call SimpleSnippets#jump()
	endif
endfunction

function! SimpleSnippets#jumpShell(placeholder)
	call SimpleSnippets#jumpNormal(a:placeholder)
endfunction

function! SimpleSnippets#flashSnippet(snippet_defenition, line_count)
		normal! diw
		exec "normal! a " . a:snippet_defenition
		let s:snip_line_count = a:line_count
		if s:snip_line_count != 1
			let l:indent_lines = s:snip_line_count - 1
			silent exec 'normal! V' . l:indent_lines . 'j='
		else
			normal! ==
		endif
		silent call SimpleSnippets#parseAndInit()
		call SimpleSnippets#jump()
endfunction

