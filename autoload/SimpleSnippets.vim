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
let s:search_sequence = 0
let s:escape_pattern = '/\*~.$^!#'
let s:visual_contents = ''

let s:jump_stack = []
let s:type_stack = []
let s:current_jump = 0
let s:ph_start = []
let s:ph_end = []
let s:choicelist = []

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
	if s:IsInside()
		if s:IsActive()
			return 1
		endif
	endif
	let s:active = 0
	return 0
endfunction

function! SimpleSnippets#getVisual()
	let l:save_v = @v
	normal! g`<vg`>"vc
	let s:visual_contents = @v
	let @v = l:save_v
	startinsert!
endfunction

function! SimpleSnippets#jump()
	if s:IsInside()
		let l:cursor_pos = getpos(".")
		let l:current_ph = get(s:jump_stack, s:current_jump)
		let l:current_type = get(s:type_stack, s:current_jump)
		let s:current_jump += 1
		if s:current_jump == len(s:jump_stack) + 1
			if &lazyredraw != 1
				set lazyredraw
				let l:disable_lazyredraw = 1
			else
				let l:disable_lazyredraw = 0
			endif
			call cursor(s:snip_end, 1)
			let s:active = 0
			startinsert!
			if l:disable_lazyredraw == 1
				set nolazyredraw
			endif
			return
		endif
		if s:current_jump - 2 >= 0
			call s:CheckIfChangesWerwMade(s:current_jump - 2)
		endif
		if l:current_type != 'choice' && l:current_type != 'mirror_choice'
			let l:current_ph = escape(l:current_ph, s:escape_pattern)
		endif
		if match(l:current_type, 'normal') == 0
			call s:JumpNormal(l:current_ph)
		elseif match(l:current_type, 'mirror') == 0
			call s:JumpMirror(l:current_ph)
		elseif match(l:current_type, 'choice') == 0
			call s:JumpChoice(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpBackwards()
	if s:IsInside()
		let l:cursor_pos = getpos(".")
		if s:current_jump - 1 != 0
			let s:current_jump -= 1
		else
			call s:CheckIfChangesWerwMade(0)
		endif
		let l:current_ph = get(s:jump_stack, s:current_jump - 1)
		let l:current_type = get(s:type_stack, s:current_jump - 1)
		if s:current_jump - 1 >= 0
			call s:CheckIfChangesWerwMade(s:current_jump)
		endif
		if l:current_type != 'choice' && l:current_type != 'mirror_choice'
			let l:current_ph = escape(l:current_ph, s:escape_pattern)
		endif
		if match(l:current_type, 'normal') == 0
			call s:JumpNormal(l:current_ph)
		elseif match(l:current_type, 'mirror') == 0
			call s:JumpMirror(l:current_ph)
		elseif match(l:current_type, 'choice') == 0
			call s:JumpChoice(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! SimpleSnippets#jumpToLastPlaceholder()
	if s:IsInside()
		let l:cursor_pos = getpos(".")
		let s:prev_jump = s:current_jump - 1
		if s:prev_jump >= len(s:jump_stack)
			let s:prev_jump = len(s:jump_stack) - 1
		endif
		let s:current_jump = len(s:jump_stack)
		let l:current_type = s:type_stack[-1]
		call s:CheckIfChangesWerwMade(s:prev_jump)
		if l:current_type != 'choice' && l:current_type != 'mirror_choice'
			let l:current_ph = escape(s:jump_stack[-1], s:escape_pattern)
		endif
		if match(l:current_type, 'normal') == 0
			call s:JumpNormal(l:current_ph)
		elseif match(l:current_type, 'mirror') == 0
			call s:JumpMirror(l:current_ph)
		elseif match(l:current_type, 'choice') == 0
			call s:JumpChoice(l:current_ph)
		endif
	else
		echo "[WARN]: Can't jump outside of snippet's body"
	endif
endfunction

function! s:JumpNormal(placeholder)
	let l:ph = a:placeholder
	let save_q_mark = getpos("'q")
	let save_p_mark = getpos("'p")
	call cursor(s:snip_start, 1)
	if l:ph =~ "\\n"
		let l:ph = join(split(l:ph), "\\n")
		let l:echo = l:ph
		call search(split(l:ph, '\\n')[0], 'c', s:snip_end)
		normal! mq
		call search(split(l:ph, '\\n')[-1], 'ce', s:snip_end)
		normal! mp
	else
		let l:echo = a:placeholder
		if search('\<'.l:ph.'\>', 'c', s:snip_end) == 0
			let s:search_sequence = 1
			call search(l:ph, 'c', s:snip_end)
		else
			let s:search_sequence = 0
		endif
		normal! mq
		if search('\<'.l:ph.'\>', 'ce', s:snip_end) == 0
			let s:search_sequence = 1
			call search(l:ph, 'ce', s:snip_end)
		else
			let s:search_sequence = 0
		endif
		normal! mp
	endif
	let s:ph_start = getpos("'q")
	let s:ph_end = getpos("'p")
	if &lazyredraw != 1
		set lazyredraw
		let l:disable_lazyredraw = 1
	else
		let l:disable_lazyredraw = 0
	endif
	exec "normal! g`qvg`p\<c-g>"
	if l:disable_lazyredraw == 1
		set nolazyredraw
	endif
	call setpos("'q", save_q_mark)
	call setpos("'p", save_p_mark)
endfunction

function! s:JumpMirror(placeholder)
	if s:current_jump + 1 <= len(s:jump_stack)
		call s:CheckIfChangesWerwMade(s:current_jump)
	endif
	if s:type_stack[s:current_jump - 1] == 'mirror_choice'
		let l:ph = a:placeholder[0]
		let l:echo = a:placeholder[0]
	else
		let l:ph = a:placeholder
		let l:echo = a:placeholder
	endif
	if l:ph =~ "\\n"
		let s:placeholder_line_count = len(split(l:ph, "\\n"))
		let l:list = split(l:ph)
		let l:ph = join(l:list, "\\n")
		let l:echo = l:list[0].' ... '.l:list[-1]
	elseif l:ph !~ "\\W"
		let s:placeholder_line_count = 1
		let l:ph = '\<' . l:ph . '\>'
	endif
	let l:matchpositions = s:ColorMatches(l:ph)
	call cursor(s:snip_start, 1)
	call search(l:ph, 'c', s:snip_end)
	let save_q_mark = getpos("'q")
	normal! mq
	let s:ph_start = getpos("'q")
	call setpos("'q", save_q_mark)
	let l:cursor_pos = getpos(".")
	let l:reenable_cursorline = 0
	if &cursorline == 1
		set nocursorline
		let l:reenable_cursorline = 1
	endif
	if s:type_stack[s:current_jump - 1] == 'mirror_choice'
		let s:choicelist = a:placeholder
	endif
	call s:SaveUserCommandMappings()
	if s:type_stack[s:current_jump - 1] != 'mirror_choice'
		exec "cnoremap <silent>".g:SimpleSnippetsExpandOrJumpTrigger.' <Cr><Esc>:call SimpleSnippets#jump()<Cr>'
		exec "cnoremap <silent>".g:SimpleSnippetsJumpBackwardTrigger.' <Cr><Esc>:call SimpleSnippets#jumpBackwards()<Cr>'
		exec "cnoremap <silent>".g:SimpleSnippetsJumpToLastTrigger.' <Cr><Esc>:call SimpleSnippets#jumpToLastPlaceholder()<Cr>'
	endif
	exec "cnoremap <silent><Cr> <Cr><Esc>:call SimpleSnippets#jump()<Cr>"
	redraw
	if s:type_stack[s:current_jump - 1] != 'mirror_choice'
		let l:rename = input('Replace placeholder "'.l:echo.'" with: ')
	else
		let l:rename = input('Replaice choice placeholder "'.l:echo.'" with (press tab to select): ', "", "customlist,s:GetChoiceList")
	endif
	normal! :
	call s:RestoreCommandMappings()
	let s:result_line_count = len(split(l:rename, '\\r'))
	if l:rename != ''
		let l:cnt = s:Execute(s:snip_start . ',' . s:snip_end . 's/' . l:ph . '/' . escape(l:rename, s:escape_pattern) . '/g')
		call histdel("/", -1)
		let l:subst_amount = strpart(l:cnt, 0, stridx(l:cnt, " "))
		let l:subst_amount = substitute(l:subst_amount, '\v%^\_s+|\_s+%$', '', 'g')
		let s:snip_end = s:snip_end + (s:result_line_count * l:subst_amount) - (s:placeholder_line_count * l:subst_amount)
		if s:type_stack[s:current_jump - 1] == 'mirror_choice'
			if index(s:jump_stack[s:current_jump - 1], l:rename) == -1
				call insert(s:jump_stack[s:current_jump - 1], l:rename)
			endif
		else
			let s:jump_stack[s:current_jump - 1] = l:rename
		endif
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

function! s:GetChoiceList(a,b,c)
	return s:choicelist
endfunction

function! s:JumpChoice(placeholder)
	let l:ph = a:placeholder[0]
	let save_q_mark = getpos("'q")
	let save_p_mark = getpos("'p")
	call cursor(s:snip_start, 1)
	let l:echo = a:placeholder
	if search('\<'.l:ph.'\>', 'c', s:snip_end) == 0
		let s:search_sequence = 1
		call search(l:ph, 'c', s:snip_end)
	else
		let s:search_sequence = 0
	endif
	normal! mq
	if search('\<'.l:ph.'\>', 'ce', s:snip_end) == 0
		let s:search_sequence = 1
		call search(l:ph, 'ce', s:snip_end)
	else
		let s:search_sequence = 0
	endif
	normal! mp
	let s:ph_start = getpos("'q")
	let s:ph_end = getpos("'p")
	if &lazyredraw != 1
		set lazyredraw
		let l:disable_lazyredraw = 1
	else
		let l:disable_lazyredraw = 0
	endif
	exec "normal! g`qvg`pc "
	let l:string = string(a:placeholder)
	call feedkeys("i\<Del>\<C-R>=s:ListChoice(".l:string.")\<CR>\<c-p>", "n")
	if l:disable_lazyredraw == 1
		set nolazyredraw
	endif
	call setpos("'q", save_q_mark)
	call setpos("'p", save_p_mark)
endfunction

function! s:ListChoice(list)
	call complete(col('.'), a:list)
	return ''
endfunction

function! s:CheckIfChangesWerwMade(jump)
	let l:type = s:type_stack[a:jump]
	if l:type == 'normal'
		let l:cursor_pos = getpos(".")
		let l:prev_ph = get(s:jump_stack, a:jump)
		if l:prev_ph !~ "\\W"
			call cursor(s:snip_start, 1)
			if s:search_sequence == 1
				if search(l:prev_ph, "c", s:snip_end) == 0
					let s:jump_stack[a:jump] = s:GetLastInput()
				endif
			else
				if search('\<'.l:prev_ph.'\>', "c", s:snip_end) == 0
					let s:jump_stack[a:jump] = s:GetLastInput()
				endif
			endif
		else
			let l:prev_ph = escape(l:prev_ph, s:escape_pattern)
			call cursor(s:snip_start, 1)
			if search(l:prev_ph, "c", s:snip_end) == 0
				let s:jump_stack[a:jump] = s:GetLastInput()
			endif
		endif
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	elseif l:type == 'choice'
		let l:prev_ph = get(s:jump_stack, a:jump)
		call cursor(s:snip_start, 1)
		let l:found = 0
		for item in l:prev_ph
			if search(item, "c", s:snip_end) != 0
				let l:found = 1
				if index(s:jump_stack[a:jump], item) >= 0
					call remove(s:jump_stack[a:jump], index(s:jump_stack[a:jump], item))
				endif
				call insert(s:jump_stack[a:jump], item)
				break
			endif
		endfor
		if l:found == 0
			let l:input = s:GetLastInput()
			if index(s:jump_stack[a:jump], l:input) >= 0
				call remove(s:jump_stack[a:jump], index(s:jump_stack[a:jump], l:input))
			endif
			call insert(s:jump_stack[a:jump], l:input)
		endif
	endif
endfunction

function! s:GetLastInput()
	let l:save_quote = @"
	let save_q_mark = getpos("'q")
	call setpos("'q", s:ph_start)
	normal! g`qvg`.y
	call setpos("'q", save_q_mark)
	let l:user_input = @"
	let @" = l:save_quote
	return l:user_input
endfunction

function! s:SaveUserCommandMappings()
	if mapcheck(g:SimpleSnippetsExpandOrJumpTrigger, "c") != ""
		let s:save_user_cmap_forward = maparg(g:SimpleSnippetsExpandOrJumpTrigger, "c", 0, 1)
		if get(s:save_user_cmap_forward, "buffer") == 1
			exec "cunmap <buffer> ". g:SimpleSnippetsExpandOrJumpTrigger
		else
			exec "cunmap ". g:SimpleSnippetsExpandOrJumpTrigger
		endif
	endif
	if mapcheck(g:SimpleSnippetsJumpBackwardTrigger, "c") != ""
		let s:save_user_cmap_backward = maparg(g:SimpleSnippetsJumpBackwardTrigger, "c", 0, 1)
		if get(s:save_user_cmap_backward, "buffer") == 1
			exec "cunmap <buffer> ". g:SimpleSnippetsJumpBackwardTrigger
		else
			exec "cunmap ". g:SimpleSnippetsJumpBackwardTrigger
		endif
	endif
	if mapcheck(g:SimpleSnippetsJumpToLastTrigger, "c") != ""
		let s:save_user_cmap_last = maparg(g:SimpleSnippetsJumpToLastTrigger, "c", 0, 1)
		if get(s:save_user_cmap_last, "buffer") == 1
			exec "cunmap <buffer> ". g:SimpleSnippetsJumpToLastTrigger
		else
			exec "cunmap ". g:SimpleSnippetsJumpToLastTrigger
		endif
	endif
	if mapcheck("\<Cr>", "c") != ""
		let s:save_user_cmap_cr = maparg("<\Cr>", "c", 0, 1)
		if get(s:save_user_cmap_cr, "buffer") == 1
			exec "cunmap <buffer> <Cr>"
		else
			exec "cunmap <Cr>"
		endif
	endif
endfunction

function! s:RestoreCommandMappings()
	if exists('s:save_user_cmap_forward')
		exec "cunmap ".g:SimpleSnippetsExpandOrJumpTrigger
		call s:RestoreUserMapping(s:save_user_cmap_forward)
		unlet s:save_user_cmap_forward
	else
		if mapcheck(g:SimpleSnippetsExpandOrJumpTrigger, "c") != ""
			exec "cunmap ".g:SimpleSnippetsExpandOrJumpTrigger
		endif
	endif
	if exists('s:save_user_cmap_backward')
		exec "cunmap ".g:SimpleSnippetsJumpBackwardTrigger
		call s:RestoreUserMapping(s:save_user_cmap_backward)
		unlet s:save_user_cmap_backward
	else
		if mapcheck(g:SimpleSnippetsJumpBackwardTrigger, "c") != ""
			exec "cunmap ".g:SimpleSnippetsJumpBackwardTrigger
		endif
	endif
	if exists('s:save_user_cmap_last')
		exec "cunmap ".g:SimpleSnippetsJumpToLastTrigger
		call s:RestoreUserMapping(s:save_user_cmap_last)
		unlet s:save_user_cmap_last
	else
		if mapcheck(g:SimpleSnippetsJumpToLastTrigger, "c") != ""
			exec "cunmap ".g:SimpleSnippetsJumpToLastTrigger
		endif
	endif
	if exists('s:save_user_cmap_cr')
		exec "cunmap <Cr>"
		call s:RestoreUserMapping(s:save_user_cmap_last)
		unlet s:save_user_cmap_last
	else
		if mapcheck("\<Cr>", "c") != ""
			exec "cunmap <Cr>"
		endif
	endif
endfunction

function! s:RestoreUserMapping(mapping)
	let l:mode = get(a:mapping, "mode")
	if get(a:mapping, "noremap") == 1
		let l:mode .= 'noremap'
	else
		let l:mode .= 'map'
	endif
	let l:params = ''
	if get(a:mapping, "silent") == 1
		let l:params .= '<silent>'
	endif
	if get(a:mapping, "nowait") == 1
		let l:params .= '<nowait>'
	endif
	if get(a:mapping, "buffer") == 1
		let l:params .= '<buffer>'
	endif
	if get(a:mapping, "expr") == 1
		let l:params .= '<expr>'
	endif
	let l:lhs = get(a:mapping, "lhs")
	let l:rhs = get(a:mapping, "rhs")
	execute ''.l:mode.' '.l:params.' '.l:lhs.' '.l:rhs
endfunction

function! s:IsInside()
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
	call s:ObtainTrigger()
	if s:GetSnippetFiletype(s:trigger) != -1
		return 1
	endif
	call s:ObtainAlternateTrigger()
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
			let s:trigger = expand("<cWORD>")
			call cursor(l:cursor_pos[1], l:cursor_pos[2])
		else
			let s:trigger = expand("<cWORD>")
		endif
	endif
endfunction

function! s:ObtainAlternateTrigger()
	if mode() == 'i'
		let l:cursor_pos = getpos(".")
		call cursor(line('.'), col('.') - 1)
		let s:trigger = expand("<cword>")
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	else
		let s:trigger = expand("<cword>")
	endif
endfunction

function! s:IsActive()
	if s:active == 1
		return 1
	else
		return 0
	endif
endfunction

function! SimpleSnippets#listSnippets()
	let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	call s:CheckExternalSnippetPlugin()
	let l:user_snips = g:SimpleSnippets_search_path
	call s:PrintSnippets("User snippets:", l:user_snips, l:filetype)
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
		let l:plugin_filetype = s:GetMainFiletype(g:SimpleSnippets_snippets_similar_filetypes)
		call s:PrintSnippets("Plugin snippets:", l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		call s:PrintSnippets('User \"all\" snippets:', l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			call s:PrintSnippets('Plugin \"all\" snippets:', l:plug_snips, 'all')
		endif
	endif
endfunction

function! SimpleSnippets#availableSnippets()
	call s:CheckExternalSnippetPlugin()
	let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	let l:snippets = {}
	let l:user_snips = g:SimpleSnippets_search_path
	let l:snippets = s:GetSnippetDictonary(l:snippets, l:user_snips, l:filetype)
	if s:SimpleSnippets_snippets_plugin_installed == 1
		let l:plugin_filetype = s:GetMainFiletype(g:SimpleSnippets_snippets_similar_filetypes)
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:snippets = s:GetSnippetDictonary(l:snippets, l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		let l:snippets = s:GetSnippetDictonary(l:snippets, l:user_snips, 'all')
		if s:SimpleSnippets_snippets_plugin_installed == 1
			let l:snippets = s:GetSnippetDictonary(l:snippets, l:plug_snips, 'all')
		endif
	endif
	if s:flash_snippets != {}
		for trigger in keys(s:flash_snippets)
			let l:snippets[trigger] = substitute(s:flash_snippets[trigger], '\v\$\{[0-9]+(:|!)(.{-})\}', '\2', 'g')
		endfor
	endif
	return l:snippets
endfunction

function! s:CheckExternalSnippetPlugin()
	if !exists('s:plugin_checked')
		let s:plugin_checked = 1
		if exists('g:SimpleSnippets_snippets_plugin_path')
			let s:SimpleSnippets_snippets_plugin_installed = 1
		else
			let s:SimpleSnippets_snippets_plugin_installed = 0
		endif
	endif
endfunction

function! s:GetSnippetPath(snip, filetype)
	if filereadable(g:SimpleSnippets_search_path . a:filetype . '/' . a:snip)
		return g:SimpleSnippets_search_path . a:filetype . '/' . a:snip
	elseif s:SimpleSnippets_snippets_plugin_installed == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip)
			return g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip
		endif
	endif
endfunction

function! s:TriggerEscape(trigger)
	let l:trigg = s:RemoveTrailings(a:trigger)
	if l:trigg =~ "\\s"
		return -1
	elseif l:trigg =~ "\\W"
		return escape(l:trigg, '/\*#|{}()"'."'")
	else
		return l:trigg
	endif
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

function! SimpleSnippets#edit(trigg)
	let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
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
	let l:trigger = s:TriggerEscape(l:trigger)
	if l:trigger == -1
		redraw
		echo "Whitespace characters can't be used in trigger definition"
		return -1
	endif
	if l:trigger != ''
		call s:CreateSplit(l:path, l:trigger)
		setf l:filetype
	else
		redraw
		echo "Empty trigger"
	endif
endfunction

function! SimpleSnippets#editDescriptions(ft)
	if a:ft != ''
		let l:filetype = a:ft
	else
		let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	endif
	let l:path = g:SimpleSnippets_search_path . l:filetype
	let s:snip_edit_buf = 0
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	let l:descriptions = l:filetype.'.snippets.descriptions.txt'
	call s:CreateSplit(l:path, l:descriptions)
endfunction

function! s:PrintSnippets(message, path, filetype)
	let l:snippets = {}
	let l:snippets = s:GetSnippetDictonary(l:snippets, a:path, a:filetype)
	if !empty(l:snippets)
		let l:max = 0
		for key in keys(l:snippets)
			let l:len = len(key) + 2
			if l:len > l:max
				let l:max = l:len
			endif
		endfor
		echo a:message
		echo "\n"
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
		echon l:string
		echo "\n"
	endif
endfunction

function! s:GetSnippetDictonary(dict, path, filetype)
	if isdirectory(a:path . a:filetype . '/')
		let l:dir = system('ls '. a:path . a:filetype . '/')
		let l:dir = substitute(l:dir, '\n\+$', '', '')
		let l:dir_list = split(l:dir)
		for i in l:dir_list
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


" 7.4 compability layer
function! s:Execute(command, ...)
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

function! s:CreateSplit(path, trigger)
	if exists("*win_gotoid")
		if win_gotoid(s:snip_edit_win)
			try
				exec "buffer " . s:snip_edit_buf
			catch
				exec "edit " . a:path . '/' . a:trigger
			endtry
		else
			if exists('g:SimpleSnippets_split_horizontal')
				if g:SimpleSnippets_split_horizontal != 0
					new
				else
					vertical new
				endif
			else
				vertical new
			endif
			try
				exec "buffer " . s:snip_edit_buf
			catch
				execute "edit " . a:path . '/' . a:trigger
				let s:snip_edit_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	else
		if exists('g:SimpleSnippets_split_horizontal')
			if g:SimpleSnippets_split_horizontal != 0
				new
			else
				vertical new
			endif
		else
			vertical new
		endif
		exec "edit " . a:path . '/' . a:trigger
	endif
endfunction

