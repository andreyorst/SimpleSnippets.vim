" Globals
let s:flash_snippets = []
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
let s:trigger = ''

"Functions
function! SimpleSnippets#getTrigger()
	if s:trigger == ''
		let l:mode = mode()
		if l:mode == 'i'
			let l:col = col('.') - 1
			let s:trigger = matchstr(getline('.'), '\v(\w+|(\s+)@!\W+(\s)@<!(\w+)?)%' . l:col . 'c.')
		else
			let s:trigger = expand("<cWORD>")
		endif
	endif
endfunction

function! SimpleSnippets#isExpandable()
	call SimpleSnippets#getTrigger()
	if SimpleSnippets#getSnipFileType(s:trigger) != -1
		return 1
	else
		let s:trigger = ''
		return 0
	endif
endfunction

function! SimpleSnippets#isExpandableOrJumpable()
	call SimpleSnippets#getTrigger()
	if SimpleSnippets#isExpandable()
		return 1
	elseif SimpleSnippets#isJumpable()
		return 1
	else
		let s:trigger = ''
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
	let l:snip = s:trigger
	let s:trigger = ''
	let l:filetype = SimpleSnippets#getSnipFileType(l:snip)
	if l:filetype == 'flash snippet'
		call SimpleSnippets#expandFlashSnippet(l:snip)
	else
		let a:path = SimpleSnippets#getSnipPath(l:snip, l:filetype)
		if s:snip_line_count != 0
			if l:snip =~ "\\W"
				normal! diW
			else
				normal! diw
			endif
			silent exec ':read' . a:path
			silent exec "normal! i\<Bs>"
			silent call SimpleSnippets#parseAndInit()
		else
			echo '[ERROR] Snippet body is empty'
		endif
	endif
endfunction

function! SimpleSnippets#expandFlashSnippet(snip)
	normal! diw
	let l:len = len(s:flash_snippets)
	let l:i = 0
	while l:i < l:len
		if match(a:snip, s:flash_snippets[l:i][0]) == 0
			let @s = s:flash_snippets[l:i][1]
			let s:snip_line_count = len(substitute(s:flash_snippets[l:i][1], '[^\n]', '', 'g')) + 1
			break
		endif
		let l:i += 1
	endwhile
	normal! "sp
	if s:snip_line_count != 1
		let l:indent_lines = s:snip_line_count - 1
		silent exec 'normal! V' . l:indent_lines . 'j='
	else
		normal! ==
	endif
	silent call SimpleSnippets#parseAndInit()
endfunction

function! SimpleSnippets#checkSnippetsPlugin()
	if !exists('s:plugin_checked')
		let s:plugin_checked = 1
		if exists('g:SimpleSnippets_snippets_plugin_path')
			let s:SimpleSnippets_snippets_plugin_installed = 1
		else
			let s:SimpleSnippets_snippets_plugin_installed = 0
		endif
	endif
endfunction

function! SimpleSnippets#getSnipFileType(snip)
	call SimpleSnippets#checkSnippetsPlugin()
	let l:filetype = SimpleSnippets#filetypeWrapper()
	if filereadable(g:SimpleSnippets_search_path . l:filetype . '/' . a:snip)
		return l:filetype
	elseif SimpleSnippets#checkFlashSnippets(a:snip)
		return 'flash snippet'
	elseif s:SimpleSnippets_snippets_plugin_installed == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . l:filetype . '/' . a:snip)
			return l:filetype
		elseif filereadable(g:SimpleSnippets_snippets_plugin_path . 'all/' . a:snip)
			return 'all'
		else
			return -1
		endif
	elseif filereadable(g:SimpleSnippets_search_path . 'all/' . a:snip)
		return 'all'
	else
		return -1
	endif
endfunction

function! SimpleSnippets#getSnipPath(snip, filetype)
	if filereadable(g:SimpleSnippets_search_path . a:filetype . '/' . a:snip)
		let s:snip_line_count = 0
		for i in readfile(g:SimpleSnippets_search_path . a:filetype . '/' . a:snip)
			let s:snip_line_count +=1
		endfor
		if a:snip =~ "\\W"
			let l:snip = escape(a:snip, '/\*#|{}()"'."'")
		else
			let l:snip = a:snip
		endif
		return g:SimpleSnippets_search_path . a:filetype . '/' . l:snip
	elseif s:SimpleSnippets_snippets_plugin_installed == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip)
			let s:snip_line_count = 0
			for i in readfile(g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip)
				let s:snip_line_count +=1
			endfor
			if a:snip =~ "\\W"
				let l:snip = escape(a:snip, '/\*#|{}()"'."'")
			else
				let l:snip = a:snip
			endif
			return g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . l:snip
		endif
	endif
endfunction

function! SimpleSnippets#checkFlashSnippets(snip)
	let l:len = len(s:flash_snippets)
	let l:i = 0
	while l:i < l:len
		if match(s:flash_snippets[l:i][0], a:snip) == 0
			return 1
		endif
		let l:i += 1
	endwhile
	return 0
endfunction

function! SimpleSnippets#filetypeWrapper()
	let l:ft = &ft
	if l:ft == ''
		return 'all'
	endif
	let l:i = 0
	let l:len = len(g:SimpleSnippets_similar_filetypes)
	while l:i < l:len
		let l:sublen = len(g:SimpleSnippets_similar_filetypes[l:i])
		let l:j = 0
		while l:j < l:sublen
			if l:ft == g:SimpleSnippets_similar_filetypes[l:i][l:j]
				return g:SimpleSnippets_similar_filetypes[l:i][0]
			endif
			let l:j += 1
		endwhile
		let l:i +=1
	endwhile
	return l:ft
endfunction

function! SimpleSnippets#parseAndInit()
	let a:cursor_pos = getpos(".")
	let s:ph_contents = []
	let s:ph_types = []
	let s:active = 1
	let s:jumped_ph = 0
	let s:current_file = @%
	let s:ph_amount = SimpleSnippets#countPlaceholders('\v\$(\{)?[0-9]+(:|!|\|)?')
	if s:ph_amount != 0
		call SimpleSnippets#parseSnippet(s:ph_amount)
		if s:snip_line_count != 1
			let l:indent_lines = s:snip_line_count - 1
			call cursor(s:snip_start, 1)
			silent exec 'normal! V'
			silent exec 'normal!'. l:indent_lines .'j='
		else
			normal! ==
		endif
		call cursor(s:snip_start, 1)
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
		call search('\v\$(\{)?' . l:current, 'c')
		let l:type = SimpleSnippets#getPlaceholderType()
		call SimpleSnippets#initPlaceholder(l:current, l:type)
		let l:i += 1
		let l:current = l:i
	endwhile
endfunction

function! SimpleSnippets#addFlashSnippet(trigger, snippet_defenition)
	call add(s:flash_snippets, [a:trigger, a:snippet_defenition])
endfunction

function! SimpleSnippets#removeFlashSnippet(trigger)
	let l:i = 0
	let l:len = len(s:flash_snippets)
	while l:i < l:len
		if match(a:trigger, s:flash_snippets[l:i][0]) == 0
			call remove(s:flash_snippets, l:i)
			break
		endif
		let l:i += 1
	endwhile
endfunction

function! SimpleSnippets#getPlaceholderType()
	let l:col = col('.')
	let l:ph = matchstr(getline('.'), '\v%'.l:col.'c\$\{[0-9]+.{-}\}')
	if match(l:ph, '\v\$\{[0-9]+:.{-}\}') == 0
		return 1
	elseif match(l:ph, '\v\$\{[0-9]+\|.{-}\}') == 0
		return 2
	elseif match(l:ph, '\v\$\{[0-9]+!.{-}\}') == 0
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
	let l:result_line_count = len(substitute(l:result, '[^\n]', '', 'g')) + 1
	if l:result_line_count > 1
		let s:snip_end += l:result_line_count - 1
	endif
	exe "normal! df}"
	normal! "sp
	call add(s:ph_contents, l:result)
endfunction

function! SimpleSnippets#jump()
	if SimpleSnippets#isInside()
		let l:current_ph = escape(s:ph_contents[s:jumped_ph], '/\*~')
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
		let l:current_ph = escape(s:ph_contents[-1], '/\*~')
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
	normal! mq
	call search(ph, 'ce', s:snip_end)
	normal! mp
	exec "normal! `qv`p\<c-g>"
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
		call cursor(s:snip_start, 1)
		while l:i < l:count
			call search('\<' .ph .'\>', '', s:snip_end)
			let l:line = line('.')
			let l:start = col('.')
			call search('\<' .ph .'\>', 'ce', s:snip_end)
			let l:length = col('.') - l:start + 1
			call add(l:matchpositions, matchaddpos('Visual', [[l:line, l:start, l:length]]))
			call add(l:matchpositions, matchaddpos('Cursor', [[l:line, l:start + l:length - 1]]))
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
		cnoremap <Tab> <Cr>
		cnoremap <S-Tab> <Esc><Esc>:execute("cunmap <S-Tab>")<Cr>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>
		redraw
		let l:rename = input('Replace placeholder "'.ph.'" with: ')
		cunmap <Tab>
		if l:rename != ''
			execute s:snip_start . "," . s:snip_end . "s/\\<" . ph ."\\>/" . l:rename . "/g"
			noh
		endif
		let l:i = 0
		while l:i < l:count * 2
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

function! SimpleSnippets#edit()
	let l:filetype = SimpleSnippets#filetypeWrapper()
	let l:path = g:SimpleSnippets_search_path . l:filetype
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	let l:trigger = input('Select a trigger: ')
	if l:trigger != ''
		if win_gotoid(s:snip_edit_win)
			execute "edit " . l:path . '/' . l:trigger
			execute "setf " . l:filetype
		else
			vertical new
			try
				exec "buffer " . s:snip_edit_buf
			catch
				if l:trigger =~ "\\W"
					let l:trigger = escape(l:trigger, '/\*#|{}()"'."'")
				endif
				execute "edit " . l:path . '/' . l:trigger
				execute "setf " . l:filetype
				let g:term_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	endif
endfunction

function! SimpleSnippets#listSnippets()
	let l:filetype = SimpleSnippets#filetypeWrapper()
	call SimpleSnippets#checkSnippetsPlugin()
	let l:user_snips = g:SimpleSnippets_search_path
	call SimpleSnippets#printSnippets("User snippets:", l:user_snips, l:filetype)
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		call SimpleSnippets#printSnippets("Plugin snippets:", l:plug_snips, l:filetype)
	endif
	if s:flash_snippets != []
		let l:string = ''
		echo 'Flash snippets:'
		for snippet in s:flash_snippets
			let l:item = join(snippet, ": ")
			let l:string .= l:item .'\n'
		endfor
		echo system('echo ' . shellescape(l:string) . '| nl')
	endif
	if l:filetype != 'all'
		call SimpleSnippets#printSnippets('User \"all\" snippets:', l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			call SimpleSnippets#printSnippets('Plugin \"all\" snippets:', l:plug_snips, 'all')
		endif
	endif
endfunction

function! SimpleSnippets#printSnippets(message, path, filetype)
	if filereadable(a:path . a:filetype . '/' . a:filetype .'.snippets.descriptions.txt')
		echo system('echo -n '.a:message)
		echo system('cat --number '. a:path . a:filetype . '/' . a:filetype .'.snippets.descriptions.txt')
		echo system('echo ""')
	else
		if isdirectory(a:path . a:filetype . '/')
			echo system('echo -n '.a:message)
			echo system('ls '. a:path . a:filetype . '/ | nl')
			echo system('echo ""')
		endif
	endif
endfunction

function! SimpleSnippets#availableSnippets()
	call SimpleSnippets#checkSnippetsPlugin()
	let l:filetype = SimpleSnippets#filetypeWrapper()
	let l:snippets = {}
	let l:user_snips = g:SimpleSnippets_search_path
	let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:user_snips, l:filetype)
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:plug_snips, l:filetype)
	endif
	if l:filetype != 'all'
		let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:plug_snips, 'all')
		endif
	endif
	if s:flash_snippets != []
		for snippet in s:flash_snippets
			let l:snippets[snippet[0]] = snippet[1]
		endfor
	endif
	return l:snippets
endfunction

function! SimpleSnippets#getSnippetDict(dict, path, filetype)
	if isdirectory(a:path . a:filetype . '/')
		let l:dir = system('ls '. a:path . a:filetype . '/')
		let l:dir = substitute(l:dir, '\n\+$', '', '')
		let l:dir = split(l:dir)
		for i in l:dir
			let l:descr = ''
			for line in readfile(a:path.a:filetype.'/'.i)
				let l:descr .= line
			endfor
			let a:dict[i] = l:descr
		endfor
	endif
	if filereadable(a:path . a:filetype . '/' . a:filetype .'.snippets.descriptions.txt')
		for i in readfile(a:path . a:filetype. '/' . a:filetype . '.snippets.descriptions.txt')
			let l:trigger = matchstr(i, '\v^.{-}(:)@=')
			let l:descr = substitute(matchstr(i, '\v(^.{-}:)@<=.*'), '^\s*\(.\{-}\)\s*$', '\1', '')
			let a:dict[l:trigger] = l:descr
		endfor
	endif
	return a:dict
endfunction

