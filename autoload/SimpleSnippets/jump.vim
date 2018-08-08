let s:escape_pattern = '/\*~.$^!#'

function! SimpleSnippets#jump#forward()
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

function! SimpleSnippets#jump#backwards()
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

function! SimpleSnippets#jump#toLast()
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
		exec "cnoremap <silent>".g:SimpleSnippetsExpandOrJumpTrigger.' <Cr><Esc>:call SimpleSnippets#jump#forward()<Cr>'
		exec "cnoremap <silent>".g:SimpleSnippetsJumpBackwardTrigger.' <Cr><Esc>:call SimpleSnippets#jump#backwards()<Cr>'
		exec "cnoremap <silent>".g:SimpleSnippetsJumpToLastTrigger.' <Cr><Esc>:call SimpleSnippets#jump#toLast()<Cr>'
	endif
	exec "cnoremap <silent><Cr> <Cr><Esc>:call SimpleSnippets#jump#forward()<Cr>"
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

