" Globals
let s:flash_snippets = {}
let s:active = 0
let s:snip_start = 0
let s:snip_end = 0
let s:snip_line_count = 0
let s:current_file = ''
let s:snip_edit_buf = 0
let s:snip_edit_win = 0
let s:trigger = ''

let s:jump_stack = []
let s:type_stack = []
let s:current_jump = 0

"Functions
function! SimpleSnippets#expandOrJump()
	if SimpleSnippets#isExpandable()
		call SimpleSnippets#expand()
	elseif SimpleSnippets#isJumpable()
		call SimpleSnippets#jump()
	endif
endfunction

function! SimpleSnippets#isExpandableOrJumpable()
	if SimpleSnippets#isExpandable()
		return 1
	elseif SimpleSnippets#isJumpable()
		return 1
	else
		let s:trigger = ''
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

function! SimpleSnippets#expand()
	let l:snip = s:trigger
	let s:trigger = ''
	let l:filetype = SimpleSnippets#getSnipFileType(l:snip)
	if l:filetype == 'flash'
		call SimpleSnippets#expandFlashSnippet(l:snip)
	else
		let l:path = SimpleSnippets#getSnipPath(l:snip, l:filetype)
		let l:snippet = readfile(l:path)
		while l:snippet[0] == ''
			call remove(l:snippet, 0)
		endwhile
		while l:snippet[-1] == ''
			call remove(l:snippet, -1)
		endwhile
		let s:snip_line_count = len(l:snippet)
		if s:snip_line_count != 0
			let l:snippet = join(l:snippet, "\n")
			let l:save_s = @s
			let @s = l:snippet
			let l:save_quote = @"
			if l:snip =~ "\\W"
				normal! ciW
			else
				normal! ciw
			endif
			normal! "sp
			let @" = l:save_quote
			let @s = l:save_s
			silent call SimpleSnippets#parseAndInit()
		else
			echo '[ERROR] Snippet body is empty'
		endif
	endif
endfunction

function! SimpleSnippets#expandFlashSnippet(snip)
	let l:save_quote = @"
	if a:snip =~ "\\W"
		normal! ciW
	else
		normal! ciw
	endif
	let l:save_s = @s
	let @s = s:flash_snippets[a:snip]
	let s:snip_line_count = len(substitute(s:flash_snippets[a:snip], '[^\n]', '', 'g')) + 1
	normal! "sp
	let @s = l:save_s
	if s:snip_line_count != 1
		let l:indent_lines = s:snip_line_count - 1
		silent exec 'normal! V' . l:indent_lines . 'j='
	else
		normal! ==
	endif
	silent call SimpleSnippets#parseAndInit()
endfunction

function! SimpleSnippets#parseAndInit()
	let s:jump_stack = []
	let s:type_stack = []
	let s:current_jump = 0
	let s:active = 1
	let s:current_file = @%

	let l:cursor_pos = getpos(".")
	let l:ph_amount = SimpleSnippets#countPlaceholders('\v\$\{[0-9]+(:|!|\|)')
	if l:ph_amount != 0
		call SimpleSnippets#parseSnippet(l:ph_amount)
		if s:snip_line_count != 1
			let l:indent_lines = s:snip_line_count - 1
			call cursor(s:snip_start, 1)
			silent exec 'normal! V'
			silent exec 'normal!'. l:indent_lines .'j='
		else
			normal! ==
		endif
		call cursor(s:snip_start, 1)
		if s:jump_stack != []
			call SimpleSnippets#jump()
		endif
	else
		let s:active = 0
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	endif
endfunction

function! SimpleSnippets#jump()
	if SimpleSnippets#isInside()
		let l:cursor_pos = getpos(".")
		let l:current_ph = get(s:jump_stack, s:current_jump)
		let l:current_type = get(s:type_stack, s:current_jump)
		let s:current_jump += 1
		if s:current_jump == len(s:jump_stack) + 1
			call cursor(s:snip_end, 1)
			let s:active = 0
			startinsert!
			return
		endif
		if s:current_jump - 2 >= 0
			if s:type_stack[s:current_jump - 2] != 3
				let l:prev_ph = s:jump_stack[s:current_jump - 2]
				if l:prev_ph !~ "\\W"
					let l:prev_ph = '\<' . l:prev_ph . '\>'
				else
					let l:prev_ph = escape(l:prev_ph, '/\*~')
				endif
				call cursor(s:snip_start, 1)
				if search(l:prev_ph, "c", s:snip_end) == 0
					let s:jump_stack[s:current_jump - 2] = SimpleSnippets#getLastInput()
				endif
				call cursor(l:cursor_pos[1], l:cursor_pos[2])
			endif
		endif
		let l:current_ph = escape(l:current_ph, '/\*~')
		if match(l:current_type, '1') == 0
			call SimpleSnippets#jumpNormal(l:current_ph)
		elseif match(l:current_type, '3') == 0
			call SimpleSnippets#jumpMirror(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpBackwards()
	if SimpleSnippets#isInside()
		let l:cursor_pos = getpos(".")
		if s:current_jump -1 != 0
			let s:current_jump -= 1
		else
			let l:prev_ph = s:jump_stack[0]
			if l:prev_ph !~ "\\W"
				let l:prev_ph = '\<' . l:prev_ph . '\>'
			else
				let l:prev_ph = escape(l:prev_ph, '/\*~')
			endif
			call cursor(s:snip_start, 1)
			if search(l:prev_ph, "c", s:snip_end) == 0
				let s:jump_stack[0] = SimpleSnippets#getLastInput()
			endif
		endif
		let l:current_ph = get(s:jump_stack, s:current_jump - 1)
		if s:current_jump - 1 >= 0
			let l:current_type = get(s:type_stack, s:current_jump - 1)
			if s:type_stack[s:current_jump - 1] != 3
				let l:prev_ph = s:jump_stack[s:current_jump - 1]
				if l:prev_ph !~ "\\W"
					let l:prev_ph = '\<' . l:prev_ph . '\>'
				else
					let l:prev_ph = escape(l:prev_ph, '/\*~')
				endif
				call cursor(s:snip_start, 1)
				if search(l:prev_ph, "c", s:snip_end) == 0
					let s:jump_stack[s:current_jump] = SimpleSnippets#getLastInput()
				endif
				call cursor(l:cursor_pos[1], l:cursor_pos[2])
			endif
		endif
		let l:current_ph = escape(l:current_ph, '/\*~')
		if match(l:current_type, '1') == 0
			call SimpleSnippets#jumpNormal(l:current_ph)
		elseif match(l:current_type, '3') == 0
			call SimpleSnippets#jumpMirror(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpToLastPlaceholder()
	if SimpleSnippets#isInside()
		let l:cursor_pos = getpos(".")
		let l:current_ph = escape(s:jump_stack[-1], '/\*~')
		let s:prev_jump = s:current_jump - 1
		if s:prev_jump >= len(s:jump_stack)
			let s:prev_jump = len(s:jump_stack) - 1
		endif
		let s:current_jump = len(s:jump_stack)
		let l:current_type = s:type_stack[-1]
		if s:type_stack[s:prev_jump] != 3
			let s:prev_ph = get(s:jump_stack, s:prev_jump)
			if s:prev_ph !~ "\\W"
				let s:prev_ph = '\<' . s:prev_ph . '\>'
			else
				let s:prev_ph = escape(s:prev_ph, '/\*~')
			endif
			call cursor(s:snip_start, 1)
			if search(s:prev_ph, "c", s:snip_end) == 0
				let s:jump_stack[s:prev_jump] = SimpleSnippets#getLastInput()
			endif
			call cursor(l:cursor_pos[1], l:cursor_pos[2])
		endif
		if match(l:current_type, '1') == 0
			call SimpleSnippets#jumpNormal(l:current_ph)
		elseif match(l:current_type, '3') == 0
			call SimpleSnippets#jumpMirror(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

" debug function
function! SimpleSnippets#printJumpStackState()
	let l:i = 0
	for item in s:jump_stack
		if l:i != s:current_jump - 1
			echon string(item)
		else
			echon "[".string(item)."]"
		endif
		if l:i != len(s:jump_stack) - 1
			echon ", "
		endif
		let l:i += 1
	endfor
	echon " | current_jump = ". s:current_jump
endfunction

function! SimpleSnippets#jumpNormal(placeholder)
	let l:ph = a:placeholder
	call cursor(s:snip_start, 1)
	if l:ph =~ "\\n"
		let l:ph = join(split(l:ph), "\\n")
		let l:echo = l:ph
	elseif l:ph !~ "\\W"
		let l:echo = a:placeholder
		let l:ph = '\<' . l:ph . '\>'
	endif
	call search(split(l:ph, '\\n')[0], 'c', s:snip_end)
	normal! mq
	call search(split(l:ph, '\\n')[-1], 'ce', s:snip_end)
	normal! mp
	exec "normal! g`qvg`p\<c-g>"
endfunction

function! SimpleSnippets#getLastInput()
	let l:save_quote = @"
	normal! g`qvg`.y
	let l:user_input = @"
	let @" = l:save_quote
	return l:user_input
endfunction

function! SimpleSnippets#jumpMirror(placeholder)
	if s:current_jump + 1 <= len(s:jump_stack)
		if s:type_stack[s:current_jump] != 3
			let l:cursor_pos = getpos(".")
			let s:prev_ph = get(s:jump_stack, s:current_jump)
			if s:prev_ph !~ "\\W"
				let s:prev_ph = '\<' . s:prev_ph . '\>'
			else
				let s:prev_ph = escape(s:prev_ph, '/\*~')
			endif
			call cursor(s:snip_start, 1)
			if search(s:prev_ph, "c", s:snip_end) == 0
				let s:jump_stack[s:current_jump] = SimpleSnippets#getLastInput()
			endif
			call cursor(l:cursor_pos[1], l:cursor_pos[2])
		endif
	endif

	let l:ph = a:placeholder
	let l:echo = a:placeholder
	if l:ph =~ "\\n"
		let s:placeholder_line_count = len(split(l:ph, "\\n"))
		let l:list = split(l:ph)
		let l:ph = join(l:list, "\\n")
		let l:echo = l:list[0].' ... '.l:list[-1]
	elseif l:ph !~ "\\W"
		let s:placeholder_line_count = 1
		let l:echo = a:placeholder
		let l:ph = '\<' . l:ph . '\>'
	endif
	let l:matchpositions = SimpleSnippets#colorMatches(l:ph)
	call cursor(s:snip_start, 1)
	call search(l:ph, 'c', s:snip_end)
	normal! mq
	let l:cursor_pos = getpos(".")
	let l:reenable_cursorline = 0
	if &cursorline == 1
		set nocursorline
		let l:reenable_cursorline = 1
	endif

	exec "cnoremap <silent>".g:SimpleSnippetsExpandOrJumpTrigger.' <Cr><Esc>:call SimpleSnippets#jump()<Cr>'
	exec "cnoremap <silent>".g:SimpleSnippetsJumpBackwardTrigger.' <Esc><Esc>:execute("cunmap '.g:SimpleSnippetsJumpBackwardTrigger.'")<Cr>:call SimpleSnippets#jumpBackwards()<Cr>'
	exec "cnoremap <silent>".g:SimpleSnippetsJumpToLastTrigger.' <Esc><Esc>:execute("cunmap '.g:SimpleSnippetsJumpToLastTrigger.'")<Cr>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>'
	redraw
	let l:rename = input('Replace placeholder "'.l:echo.'" with: ')
	exec "cunmap ".g:SimpleSnippetsExpandOrJumpTrigger
	normal! :
	let s:result_line_count = len(split(l:rename, '\\r'))
	if l:rename != ''
		redir => l:cnt
		execute s:snip_start . ',' . s:snip_end . 's/' . l:ph . '/' . l:rename . '/g'
		redir END
		call histdel("/", -1)
		let l:subst_amount = strpart(l:cnt, 0, stridx(l:cnt, " "))
		let l:subst_amount = substitute(l:subst_amount, '\v%^\_s+|\_s+%$', '', 'g')
		let s:snip_end = s:snip_end + (s:result_line_count * l:subst_amount) - (s:placeholder_line_count * l:subst_amount)
		let s:jump_stack[s:current_jump - 1] = l:rename
		noh
	endif
	for matchpos in l:matchpositions
		call matchdelete(matchpos)
	endfor
	call cursor(l:cursor_pos[1], l:cursor_pos[2])
	if l:reenable_cursorline == 1
		set cursorline
	endif
	redraw
endfunction

function! SimpleSnippets#isInside()
	if s:current_file == @%
		let l:current_line = line(".")
		if l:current_line >= s:snip_start && l:current_line <= s:snip_end
			return 1
		else
			return 0
		endif
	endif
	let s:active = 0
	return 0
endfunction

function! SimpleSnippets#isExpandable()
	call SimpleSnippets#obtainTrigger()
	if SimpleSnippets#getSnipFileType(s:trigger) != -1
		return 1
	endif
	call SimpleSnippets#obtainAlternateTrigger()
	if SimpleSnippets#getSnipFileType(s:trigger) != -1
		return 1
	endif
	let s:trigger = ''
	return 0
endfunction

function! SimpleSnippets#obtainTrigger()
	if s:trigger == ''
		if mode() == 'i'
			let l:cursor_pos = getpos(".")
			call cursor(line('.'), col('.') - 1)
			let s:trigger = expand("<cWORD>")
			call cursor(l:cursor_pos[1], l:cursor_pos[2])
		else
			let s:trigger = expand("<cWORD>")
		endif
	endif
endfunction

function! SimpleSnippets#obtainAlternateTrigger()
	if mode() == 'i'
		let l:cursor_pos = getpos(".")
		call cursor(line('.'), col('.') - 1)
		let s:trigger = expand("<cword>")
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	else
		let s:trigger = expand("<cword>")
	endif
endfunction

function! SimpleSnippets#isActive()
	if s:active == 1
		return 1
	else
		return 0
	endif
endfunction

function! SimpleSnippets#getSnipFileType(snip)
	call SimpleSnippets#checkExternalSnippets()
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	if filereadable(g:SimpleSnippets_search_path . l:filetype . '/' . a:snip)
		return l:filetype
	endif
	if SimpleSnippets#checkFlashSnippets(a:snip)
		return 'flash'
	endif
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plugin_filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_snippets_similar_filetypes)
		if filereadable(g:SimpleSnippets_snippets_plugin_path . l:plugin_filetype . '/' . a:snip)
			return l:plugin_filetype
		endif
	endif
	if filereadable(g:SimpleSnippets_search_path . 'all/' . a:snip)
		return 'all'
	endif
	if s:SimpleSnippets_snippets_plugin_installed == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . 'all/' . a:snip)
			return 'all'
		endif
	endif
	return -1
endfunction

function! SimpleSnippets#listSnippets()
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	call SimpleSnippets#checkExternalSnippets()
	let l:user_snips = g:SimpleSnippets_search_path
	call SimpleSnippets#printSnippets("User snippets:", l:user_snips, l:filetype)
	if s:flash_snippets != {}
		let l:string = ''
		echo 'Flash snippets:'
		for snippet in s:flash_snippets
			let l:item = join(snippet, ": ")
			let l:string .= l:item .'\n'
		endfor
		echo system('echo ' . shellescape(l:string) . '| nl')
	endif
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:plugin_filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_snippets_similar_filetypes)
		call SimpleSnippets#printSnippets("Plugin snippets:", l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		call SimpleSnippets#printSnippets('User \"all\" snippets:', l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			call SimpleSnippets#printSnippets('Plugin \"all\" snippets:', l:plug_snips, 'all')
		endif
	endif
endfunction

function! SimpleSnippets#availableSnippets()
	call SimpleSnippets#checkExternalSnippets()
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	let l:snippets = {}
	let l:user_snips = g:SimpleSnippets_search_path
	let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:user_snips, l:filetype)
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plugin_filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_snippets_similar_filetypes)
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, l:plug_snips, 'all')
		endif
	endif
	if s:flash_snippets != {}
		for trigger in keys(s:flash_snippets)
			let l:snippets[trigger] = substitute(s:flash_snippets[trigger], '\v\$\{[0-9]+(:|!)(.{-})\}', '\2', 'g')
		endfor
	endif
	return l:snippets
endfunction

function! SimpleSnippets#checkExternalSnippets()
	if !exists('s:plugin_checked')
		let s:plugin_checked = 1
		if exists('g:SimpleSnippets_snippets_plugin_path')
			let s:SimpleSnippets_snippets_plugin_installed = 1
		else
			let s:SimpleSnippets_snippets_plugin_installed = 0
		endif
	endif
endfunction

function! SimpleSnippets#getSnipPath(snip, filetype)
	if filereadable(g:SimpleSnippets_search_path . a:filetype . '/' . a:snip)
		return g:SimpleSnippets_search_path . a:filetype . '/' . a:snip
	elseif s:SimpleSnippets_snippets_plugin_installed == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip)
			return g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip
		endif
	endif
endfunction

function! SimpleSnippets#edit()
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	let l:path = g:SimpleSnippets_search_path . l:filetype
	let s:snip_edit_buf = 0
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	let l:trigger = input('Select a trigger: ')
	if l:trigger != ''
		if win_gotoid(s:snip_edit_win)
			try
				exec "buffer " . s:snip_edit_buf
			catch
				let l:trigger = SimpleSnippets#triggerEscape(l:trigger)
				exec "edit " . l:path . '/' . l:trigger
				exec "setf " . l:filetype
			endtry
		else
			vertical new
			try
				exec "buffer " . s:snip_edit_buf
			catch
				let l:trigger = SimpleSnippets#triggerEscape(l:trigger)
				execute "edit " . l:path . '/' . l:trigger
				execute "setf " . l:filetype
				let s:snip_edit_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	endif
endfunction

function! SimpleSnippets#triggerEscape(trigger)
	let l:trigg = SimpleSnippets#removeTrailings(a:trigger)
	if l:trigg =~ "\\s"
		return -1
	elseif l:trigg =~ "\\W"
		return escape(l:trigg, '/\*#|{}()"'."'")
	else
		return l:trigg
	endif
endfunction

function! SimpleSnippets#checkFlashSnippets(snip)
	if has_key(s:flash_snippets, a:snip)
		return 1
	endif
	return 0
endfunction

function! SimpleSnippets#filetypeWrapper(similar_filetypes)
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

function! SimpleSnippets#initNormal(current)
	let l:placeholder = '\v(\$\{'. a:current . ':)@<=.{-}(\})@='
	let l:result = matchstr(getline('.'), l:placeholder)
	call add(s:jump_stack, l:result)
	let l:save_quote = @"
	exe "normal! df:f}i\<Del>\<Esc>"
	let @" = l:save_quote
	let l:repeater_count = SimpleSnippets#countPlaceholders('\v\$' . a:current)
	if l:repeater_count != 0
		call add(s:type_stack, 3)
		call SimpleSnippets#initRepeaters(a:current, l:result, l:repeater_count)
	else
		call add(s:type_stack, 1)
	endif
endfunction

function! SimpleSnippets#initCommand(current)
	let l:save_quote = @"
	let l:placeholder = '\v(\$\{'. a:current . '!)@<=.{-}(\})@='
	let l:command = matchstr(getline('.'), l:placeholder)
	if executable(substitute(l:command, '\v(^\w+).*', '\1', 'g')) == 1
		let l:result = system(l:command)
	else
		let l:result = execute("echo " . l:command, "silent!")
		if l:result == ''
			let l:result = l:command
		endif
	endif
	let l:result = SimpleSnippets#removeTrailings(l:result)
	let l:save_s = @s
	let @s = l:result
	let l:result_line_count = len(substitute(l:result, '[^\n]', '', 'g')) + 1
	if l:result_line_count > 1
		let s:snip_end += l:result_line_count
	endif
	normal! mq
	call search('\v\$\{'.a:current.'!.{-}\}', 'ce', s:snip_end)
	normal! mp
	exe "normal! g`qvg`pr"
	normal! "sp
	let @s = l:save_s
	let @" = l:save_quote
	let l:repeater_count = SimpleSnippets#countPlaceholders('\v\$' . a:current)
	call add(s:jump_stack, l:result)
	if l:repeater_count != 0
		call add(s:type_stack, 3)
		call SimpleSnippets#initRepeaters(a:current, l:result, l:repeater_count)
	else
		call add(s:type_stack, 1)
	endif
	noh
endfunction

function! SimpleSnippets#countPlaceholders(pattern)
	redir => l:cnt
	silent! exe '%s/' . a:pattern . '//gn'
	redir END
	call histdel("/", -1)
	if match(l:cnt, 'not found') >= 0
		return 0
	endif
	let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
	let l:count = substitute(l:count, '\v%^\_s+|\_s+%$', '', 'g')
	return l:count
endfunction

function! SimpleSnippets#parseSnippet(amount)
	let l:type = 0
	let l:i = 1
	let l:max = a:amount + 1
	let l:current = l:i
	let s:snip_start = line(".")
	let s:snip_end = s:snip_start + s:snip_line_count - 1
	while l:i <= l:max
		call cursor(s:snip_start, 1)
		if l:i == l:max
			let l:current = 0
		endif
		if search('\v\$\{' . l:current, 'c') != 0
			let l:type = SimpleSnippets#getPlaceholderType()
			call SimpleSnippets#initPlaceholder(l:current, l:type)
		endif
		let l:i += 1
		let l:current = l:i
	endwhile
endfunction

function! SimpleSnippets#addFlashSnippet(trigger, snippet_defenition)
	let s:flash_snippets[a:trigger] = a:snippet_defenition
endfunction

function! SimpleSnippets#removeFlashSnippet(trigger)
	let l:i = 0
	if has_key(s:flash_snippets, a:trigger)
		unlet![a:trigger]
	endif
endfunction

function! SimpleSnippets#getPlaceholderType()
	let l:col = col('.')
	let l:ph = matchstr(getline('.'), '\v%'.l:col.'c\$\{[0-9]+.{-}\}')
	if match(l:ph, '\v\$\{[0-9]+:.{-}\}') == 0
		return 1
	elseif match(l:ph, '\v\$\{[0-9]+!.{-}\}') == 0
		return 2
	endif
endfunction

function! SimpleSnippets#initPlaceholder(current, type)
	if a:type == 1
		call SimpleSnippets#initNormal(a:current)
	elseif a:type == 2
		call SimpleSnippets#initCommand(a:current)
	endif
endfunction

function! SimpleSnippets#removeTrailings(text)
	let l:result = substitute(a:text, '\n\+$', '', '')
	let l:result = substitute(l:result, '\s\+$', '', '')
	let l:result = substitute(l:result, '^\s\+', '', '')
	let l:result = substitute(l:result, '^\n\+', '', '')
	return l:result
endfunction

function! SimpleSnippets#initRepeaters(current, content, count)
	let l:save_s = @s
	let l:save_quote = @"
	let @s = a:content
	let l:repeater_count = a:count
	let l:amount_of_lines = len(split(a:content, "\\n"))
	let l:i = 0
	while l:i < l:repeater_count
		call cursor(s:snip_start, 1)
		call search('\v\$'.a:current, 'c', s:snip_end)
		normal! mq
		call search('\v\$'.a:current, 'ce', s:snip_end)
		normal! mp
		exe "normal! g`qvg`pr"
		if l:amount_of_lines > 1
			let s:snip_end += l:amount_of_lines - 1
		endif
		normal! "sp
		let l:i += 1
	endwhile
	let @s = l:save_s
	let @" = l:save_quote
	call cursor(s:snip_start, 1)
	if l:amount_of_lines != 1
		let s:snip_end -= 1
	endif
endfunction

function! SimpleSnippets#colorMatches(text)
	let l:ph = a:text
	if l:ph =~ "\\n"
		let l:ph = join(split(l:ph), "\\n")
		let l:echo = l:ph
	elseif a:text !~ "\\W"
		let l:echo = a:text
		let l:ph = '\<' . l:ph . '\>'
	endif
	redir => l:cnt
	silent! exe s:snip_start.','.s:snip_end.'s/' . a:text . '//gn'
	redir END
	call histdel("/", -1)
	noh
	let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
	let l:count = substitute(l:count, '\v%^\_s+|\_s+%$', '', 'g')
	let l:i = 0
	let l:matchpositions = []
	call cursor(s:snip_start, 1)
	while l:i < l:count
		for l:lin in split(a:text, '\\n')
			call search(l:lin, 'cW', s:snip_end)
			let l:line = line('.')
			let l:start = col('.')
			call search(l:lin, 'ceW', s:snip_end)
			let l:length = col('.') - l:start + 1
			call add(l:matchpositions, matchaddpos('Visual', [[l:line, l:start, l:length]]))
			call cursor(line('.'), col('.') + 1)
		endfor
		call add(l:matchpositions, matchaddpos('Cursor', [[l:line, l:start + l:length - 1]]))
		let l:i += 1
	endwhile
	return l:matchpositions
endfunction

function! SimpleSnippets#edit(trigg)
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	let l:path = g:SimpleSnippets_search_path . l:filetype
	let s:snip_edit_buf = 0
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	if a:trigg != ''
		let l:trigger = a:trigg
	else
		let l:trigger = input('Select a trigger: ')
	endif
	let l:trigger = SimpleSnippets#triggerEscape(l:trigger)
	if l:trigger == -1
		redraw
		echo "Whitespace characters can't be used in trigger definition"
		return -1
	endif
	if l:trigger != ''
		if win_gotoid(s:snip_edit_win)
			try
				exec "buffer " . s:snip_edit_buf
			catch
				exec "edit " . l:path . '/' . l:trigger
				exec "setf " . l:filetype
			endtry
		else
			vertical new
			try
				exec "buffer " . s:snip_edit_buf
			catch
				execute "edit " . l:path . '/' . l:trigger
				execute "setf " . l:filetype
				let s:snip_edit_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	else
		redraw
		echo "Empty trigger"
	endif
endfunction

function! SimpleSnippets#listSnippets()
	let l:filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_similar_filetypes)
	call SimpleSnippets#checkExternalSnippets()
	let l:user_snips = g:SimpleSnippets_search_path
	call SimpleSnippets#printSnippets("User snippets:", l:user_snips, l:filetype)
	if s:flash_snippets != {}
		let l:string = ''
		echo 'Flash snippets:'
		for snippet in s:flash_snippets
			let l:item = join(snippet, ": ")
			let l:string .= l:item .'\n'
		endfor
		echo system('echo ' . shellescape(l:string) . '| nl')
	endif
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:plugin_filetype = SimpleSnippets#filetypeWrapper(g:SimpleSnippets_snippets_similar_filetypes)
		call SimpleSnippets#printSnippets("Plugin snippets:", l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		call SimpleSnippets#printSnippets('User \"all\" snippets:', l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			call SimpleSnippets#printSnippets('Plugin \"all\" snippets:', l:plug_snips, 'all')
		endif
	endif
endfunction

function! SimpleSnippets#printSnippets(message, path, filetype)
	let l:snippets = {}
	let l:snippets = SimpleSnippets#getSnippetDict(l:snippets, a:path, a:filetype)
	if !empty(l:snippets)
		let l:max = 0
		for key in keys(l:snippets)
			let l:len = len(key) + 2
			if l:len > l:max
				let l:max = l:len
			endif
		endfor
		echo system('echo -n '.a:message)
		let l:string = string(l:snippets)
		let l:string = substitute(l:string, "',", '\n', 'g')
		let l:string = substitute(l:string, " '", '', 'g')
		let l:string = substitute(l:string, "{'", '', 'g')
		let l:string = substitute(l:string, "'}", '', 'g')
		let l:list = split(l:string, '\n')
		let i = 0
		for l:str in l:list
			let l:trigger_len = len(matchstr(l:list[i], ".*':"))
			let l:amount_of_spaces = l:max - l:trigger_len + 3
			let j = 0
			let l:delimeter = ':'
			while j <= l:amount_of_spaces
				let l:delimeter .= ' '
				let j += 1
			endwhile
			let l:list[i] = substitute(l:str, "':", l:delimeter, 'g')
			let i += 1
		endfor
		let l:string = join(l:list, "\n")
		let l:string = substitute(l:string, "':", ': ', 'g')
		let l:string = substitute(l:string, '\\n', '\\\n', 'g')
		let l:string = substitute(l:string, '\\r', '\\\\r', 'g')
		let l:string = substitute(l:string, '\n', '\\n', 'g')
		echo system('echo -n ' . shellescape(l:string) . '| nl')
		echo system('echo ')
	endif
endfunction

function! SimpleSnippets#getSnippetDict(dict, path, filetype)
	if isdirectory(a:path . a:filetype . '/')
		let l:dir = system('ls '. a:path . a:filetype . '/')
		let l:dir = substitute(l:dir, '\n\+$', '', '')
		let l:dir = split(l:dir)
		for i in l:dir
			let l:descr = ''
			for line in readfile(a:path.a:filetype.'/'.i)
				let l:descr .= substitute(line, '\v\$\{[0-9]+(:|!)(.{-})\}', '\2', 'g')
				break
			endfor
			let l:descr = substitute(l:descr, '\v(\S+)(\})', '\1 \2', 'g')
			let l:descr = substitute(l:descr, '\v\{(\s+)?$', '', 'g')
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
	if has_key(a:dict, a:filetype.'.snippets.descriptions.txt')
		unlet! a:dict[a:filetype.'.snippets.descriptions.txt']
	endif
	if a:filetype != 'all'
		if has_key(a:dict, 'all.snippets.descriptions.txt')
			unlet! a:dict['all.snippets.descriptions.txt']
		endif
	endif
	return a:dict
endfunction

