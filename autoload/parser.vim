
function! s:ParseAndInit()
	let s:active = 1
	let s:snippet.jump_cnt = 0
	let s:snippet.curr_file = @%
	let l:cursor_pos = getpos(".")
	let s:snippet.ph_amount = s:CountPlaceholders('\v\$\{[0-9]+(:|!|\|)')
	if s:snippet.ph_amount != 0
		call s:InitSnippet(s:snippet.ph_amount)
		call cursor(s:snippet.start, 1)
	endif
	let s:snippet.ts_amount = s:CountPlaceholders('\v\$\{[0-9]+\}')
	if s:snippet.ts_amount != 0
		call s:InitSnippet(s:snippet.ts_amount)
		call cursor(s:snippet.start, 1)
	else
		let s:active = 0
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	endif
	if s:active != 0
		if s:snippet.line_count != 1
			let l:indent_lines = s:snippet.line_count - 1
			call cursor(s:snippet.start, 1)
			silent exec 'normal! V'
			silent exec 'normal!'. l:indent_lines .'j='
		else
			normal! ==
		endif
	endif
endfunction

function! s:InitSnippet(amount)
	let l:i = 0
	while l:i < a:amount
		call cursor(s:snippet.start, 1)
		if search('\v\$(\{)?[0-9]+(:|!|\|)?', 'c', s:snippet.end) != 0
			call s:InitPlaceholder()
		endif
		let l:i += 1
	endwhile
	call s:InitVisual()
endfunction

function! s:CountPlaceholders(pattern)
	let l:gn = &gdefault ? 'ggn' : 'gn'
	let l:cnt = SimpleSnippets#execute(s:snippet.start.','.s:snippet.end.'s/'.a:pattern.'//'.l:gn, "silent!")
	call histdel("/", -1)
	if match(l:cnt, 'not found') >= 0
		return 0
	endif
	let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
	return substitute(l:count, '\v%^\_s+|\_s+%$', '', &gdefault ? 'gg' : 'g')
endfunction

function! s:InitPlaceholder()
	let l:type = s:GetPlaceholderType()
	if l:type == 'normal'
		call s:InitNormal()
	elseif l:type == 'command'
		call s:InitCommand()
	elseif l:type == 'choice'
		call s:InitChoice()
	elseif l:type == 'tabstop'
		call s:InitTabstop()
	endif
endfunction

function! s:GetPlaceholderType()
	let l:ph = matchstr(getline('.'), '\v%'.col('.').'c\$(\{)?[0-9]+(:|!|\|)?')
	if match(l:ph, '\v\$\{[0-9]+:') == 0
		return 'normal'
	elseif match(l:ph, '\v\$\{[0-9]+!') == 0
		return 'command'
	elseif match(l:ph, '\v\$\{[0-9]+\|') == 0
		return 'choice'
	elseif match(l:ph, '\v\$[0-9]+') == 0
		return 'tabstop'
	endif
endfunction

function! s:InitNormal()
	let l:save_quote = @"
	let l:save_s = @s
	let l:placeholder = matchstr(getline('.'), '\v%'.col('.').'c\$\{[0-9]+:')
	let l:current = matchstr(l:placeholder, '\v(\$\{)@<=[0-9]+(:)@=')
	let save_q_mark = getpos("'q")
	let save_e_mark = getpos("'e")
	silent exe "normal! mqf{%mei\<Del>\<Esc>vg`qf:/\\v\\S\<Cr>\"syg`qdf:"
	call histdel("/", -1)
	let l:repeater_count = s:CountPlaceholders('\v\$\{'.l:current.':\}')
	let l:ph_data = s:ConstructPhInfo(l:current, getpos("'q"), getpos("'e"), l:repeater_count)
	let s:snippet.ph_data[l:ph_data.index] = l:ph_data
	let l:result = @s
	call setpos("'q", save_q_mark)
	call setpos("'e", save_e_mark)
	let @" = l:save_quote
	let @s = l:save_s
	if l:repeater_count != 0
		call s:InitRepeaters(l:current, l:result, l:repeater_count)
	endif
endfunction

function! s:ConstructPhInfo(index, start, end, repeater_amount)
	let l:ph = {}
	let l:ph['index'] = a:index
	let l:ph['startcol'] = a:start[2]
	let l:ph['endcol'] = a:end[2]
	let l:ph['line'] = a:start[1]
	if a:repeater_amount > 0
		let l:ph['has_repeaters'] = 1
		let l:ph['repeater_count'] = a:repeater_amount
	else
		let l:ph['has_repeaters'] = 0
		let l:ph['repeater_count'] = 0
	endif
	return l:ph
endfunction

function! s:InitCommand()
	let save_q_mark = getpos("'q")
	let l:save_quote = @"
	let l:save_s = @s
	let l:placeholder = matchstr(getline('.'), '\v%'.col('.').'c\$\{[0-9]+!')
	let l:current = matchstr(l:placeholder, '\v(\$\{)@<=[0-9]+(!)@=')
	silent exe "normal! mqf{%i\<Del>\<Esc>vg`qf!/\\v\\S\<Cr>\"sdg`qcf! "
	noh
	call histdel("/", -1)
	let l:command = @s
	if executable(substitute(l:command, '\v(^\w+).*', '\1', &gdefault ? 'gg' : 'g')) == 1
		let l:result = system(l:command)
	else
		let l:result = SimpleSnippets#execute("echo " . l:command, "silent!")
		if l:result == ''
			let l:result = l:command
		endif
	endif
	let l:result = s:RemoveTrailings(l:result)
	let @s = l:result
	let l:result_line_count = len(substitute(l:result, '[^\n]', '', &gdefault ? 'gg' : 'g')) + 1
	if l:result_line_count > 1
		let s:snippet.end += l:result_line_count
	endif
	exe "normal! g`qvr"
	normal! "sp
	normal! g`q
	call setpos("'q", save_q_mark)
	let @s = l:save_s
	let @" = l:save_quote
	let l:repeater_count = s:CountPlaceholders('\v\$\{'.l:current.':\}')
	if l:repeater_count != 0
		call s:InitRepeaters(l:current, l:result, l:repeater_count)
	endif
	noh
endfunction

function! s:InitChoice()
	let l:placeholder = matchstr(getline('.'), '\v%'.col('.').'c\$\{[0-9]+\|')
	let l:current = matchstr(l:placeholder, '\v(\$\{)@<=[0-9]+(\|)@=')
	let l:save_s = @s
	let l:save_quote = @"
	let save_q_mark = getpos("'q")
	silent exe "normal! mqf|/\\v\\S\<Cr>vf,h\"syf,df|xg`qdf|"
	noh
	call histdel("/", -1)
	let l:result = @s
	call setpos("'q", save_q_mark)
	let @" = l:save_quote
	let @s = l:save_s
	let l:repeater_count = s:CountPlaceholders('\v\$\{'.l:current.':\}')
	if l:repeater_count != 0
		call s:InitRepeaters(l:current, l:result, l:repeater_count)
	endif
endfunction

function! s:RemoveTrailings(text)
	let l:result = substitute(a:text, '\n\+$', '', '')
	let l:result = substitute(l:result, '\s\+$', '', '')
	let l:result = substitute(l:result, '^\s\+', '', '')
	let l:result = substitute(l:result, '^\n\+', '', '')
	return l:result
endfunction

function! s:InitRepeaters(index, content, count)
	let l:save_s = @s
	let l:save_quote = @"
	let @s = a:content
	let l:repeater_count = a:count
	let l:amount_of_lines = len(split(a:content, "\\n"))
	let l:i = 0
	let save_q_mark = getpos("'q")
	let save_p_mark = getpos("'p")
	while l:i < l:repeater_count
		call cursor(s:snippet.start, 1)
		call search('\v\$\{'.a:index.':\}', 'c', s:snippet.end)
		normal! mq
		call search('\v\$\{'.a:index.':\}', 'ce', s:snippet.end)
		normal! mp
		exe "normal! g`qvg`pr"
		if l:amount_of_lines > 1
			let s:snippet.end += l:amount_of_lines - 1
		endif
		normal! "sp
		let l:i += 1
	endwhile
	call setpos("'q", save_q_mark)
	call setpos("'p", save_p_mark)
	let @s = l:save_s
	let @" = l:save_quote
	call cursor(s:snippet.start, 1)
	if l:amount_of_lines != 1
		let s:snippet.end -= 1
	endif
endfunction

function! s:InitVisual()
	let l:visual_amount = s:CountPlaceholders('\v\$\{VISUAL\}')
	let l:save_s = @s
	let i = 0
	while i < l:visual_amount
		call cursor(s:snippet.start, 1)
		call search('\v\$\{VISUAL\}', 'c', s:snippet.end)
		exe "normal! f{%vF$c"
		let l:result = s:RemoveTrailings(s:snippet.visual)
		let @s = l:result
		normal! "sp
		let l:result_line_count = len(substitute(l:result, '[^\n]', '', &gdefault ? 'gg' : 'g'))
		if l:result_line_count > 1
			silent exec 'normal! V'
			silent exec 'normal!'. l:result_line_count .'j='
			let s:snippet.end += l:result_line_count
		endif
		let i += 1
	endwhile
	let @s = l:save_s
	let s:snippet.visual = ''
endfunction

function! s:PrepareSnippetBodyForParser(snippet)
	let l:body = copy(a:snippet)
	let i = 0
	while i < len(l:body)
		if l:body[i] =~ '\v\$\d+'
			let l:body[i] = substitute(l:body[i], '\v\$([0-9]+)', '${\1:}', &gdefault ? 'gg' : 'g')
		endif
		if l:body[i] =~ '\v\$\{\d+\}'
			let l:body[i] = substitute(l:body[i], '\v\$\{([0-9]+)\}', '${\1:}', &gdefault ? 'gg' : 'g')
		endif
		let i += 1
	endwhile
	return l:body
endfunction

function! GetPlaceholderPositions(index, type, snippet)
	let l:lines = []
	if a:type == 'normal' || a:type == 'tabstop'
		let l:ph = '${'.a:index.':'
	elseif a:type == 'choice'
		let l:ph = '${'.a:index.'|'
	elseif a:type == 'command'
		let l:ph = '${'.a:index.'!'
	else
		echo "[ERROR] Unknown placeholder type"
		return -1
	endif
	for line in a:snippet
		if match(line, l:ph) != -1
			call add(l:positions, GetSinglePlaceholderPosition(line, l:ph))
		endif
	endfor
endfunction

"${1234:vadfadfasf{${1:vadfasf}}}
function! GetSinglePlaceholderPosition(line, ph)
	let l:start = 0
	let l:end = 0
	let l:trigger = 0
	let l:inside = 0
	let l:opened_braces = 0
	let l:position = 0
	let l:ph = split(a:ph, '\zs')
	let l:ph_len = len(l:ph)
	let l:match = 0
	let l:inside_matched = 0
	let l:inside_another = 0
	for letter in split(a:line, '\zs')
		if l:match != l:ph_len
			if letter == l:ph[l:match]
				let l:match += 1
				if l:match == l:ph_len
					let l:inside_matched = 1
					let l:start = l:position
				endif
			else
				let l:match = 0
			endif
		endif
		if letter == '$'
			let l:trigger += 1
		elseif letter == '{'
			let l:opened_braces += 1
			let l:trigger += 1
		elseif l:trigger != 0 && letter =~ '\d'
			let l:trigger += 1
		elseif l:trigger != 0 && letter =~ '\(:\|!\||\)'
			if l:inside_matched == 0
				let l:inside_another += 1
			endif
			let l:trigger += 1
		elseif letter == '}'
			let l:trigger += 1
			if l:opened_braces != 0
				let l:opened_braces -= 1
			endif
			if l:opened_braces == 0
				if l:inside_another != 0
					let l:inside_another -= 1
				endif
			endif
			if l:inside_matched && l:opened_braces == l:inside_another
				let l:opened_braces -= 1
				let l:end = l:position
				break
			endif
		endif
		let l:position += 1
	endfor
	return [l:start, l:end]
endfunction
