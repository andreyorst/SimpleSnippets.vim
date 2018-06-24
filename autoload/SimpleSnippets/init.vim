" Globals
let s:snippet = {
	\'start': 0,
	\'end': 0,
	\'line_count': 0,
	\'file': '',
	\'ft': '',
	\'trigger': '',
	\'visual': '',
	\'body': [],
	\'ph_amount': 0,
	\'ts_amount': 0,
	\'jump': 0,
\}

let s:flash_snippets = {}
let s:active = 0

"Functions
function! SimpleSnippets#init#getSnippetItem()
	return s:snippet
endfunction

function! SimpleSnippets#init#expand()
	let s:snippet.trigger = SimpleSnippets#core#obtainTrigger()
	let s:snippet.ft = s:GetSnippetFiletype(s:snippet.trigger)
	if s:snippet.ft == 'flash'
		call s:ExpandFlash(s:snippet.trigger)
	else
		let s:snippet.body = s:ObtainSnippet()
		let s:snippet.line_count = len(s:snippet.body)
		call s:StoreSnippetToMemory(s:snippet.body)
		call s:ExpandNormal()
	endif
	let s:snippet.trigger = ''
endfunction

function! s:ExpandNormal()
	if s:snippet.line_count != 0
		let l:save_s = @s
		let @s = join(s:snippet.body, "\n")
		let l:save_quote = @"
		if s:snippe.trigger =~ "\\W"
			normal! ciW
		else
			normal! ciw
		endif
		normal! "sp
		let @" = l:save_quote
		let @s = l:save_s
		call s:ParseAndInit()
	else
		echohl ErrorMsg
		echo '[ERROR] Snippet body is empty'
		echohl None
	endif
endfunction

function! s:ObtainSnippet()
	let l:path = s:GetSnippetPath(s:snippet.trigger, s:snippet.filetype)
	let l:snippet = readfile(l:path)
	while l:snippet[0] == ''
		call remove(l:snippet, 0)
	endwhile
	while l:snippet[-1] == ''
		call remove(l:snippet, -1)
	endwhile
	return l:snippet
endfunction

function! s:ExpandFlash()
	let l:save_quote = @"
	if s:snippe.trigger =~ "\\W"
		normal! ciW
	else
		normal! ciw
	endif
	let l:save_s = @s
	let s:snippet.body = s:flash_snippets[s:snippe.trigger]
	let @s = s:snippet.body
	call s:StoreSnippetToMemory(s:snippet.body)
	let s:snippet.line_count = len(substitute(s:flash_snippets[a:trigger], '[^\n]', '', 'g')) + 1
	normal! "sp
	let @s = l:save_s
	if s:snippet.line_count != 1
		let l:indent_lines = s:snippet.line_count - 1
		silent exec 'normal! V' . l:indent_lines . 'j='
	else
		normal! ==
	endif
	silent call s:ParseAndInit()
endfunction

function! s:StoreSnippetToMemory(snippet)
	let s:snippet = copy(a:snippet)
endfunction

function! s:ParseAndInit()
	let s:active = 1
	let s:snippet.jump = 0
	let s:snippet.file = @%

	let l:cursor_pos = getpos(".")
	let s:snippet.ph_amount = s:CountPlaceholders('\v\$\{[0-9]+(:|!|\|)')
	let s:snippe.ts_amount = s:CountPlaceholders('\v\$[0-9]+')
	if s:snippet.ph_amount != 0
		call s:InitSnippet(s:snippet.ph_amount)
		call cursor(s:snippet.start, 1)
	elseif s:snippe.ts_amount != 0
		call s:InitSnippet(s:snippe.ts_amount)
		call cursor(s:snippet.start, 1)
	else
		let s:active = 0
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	endif
	if s:active != 0
		if s:snippet.line_count != 1
			let l:indent_lines = s:snippet.line_count - 1
			call cursor(s:snip_start, 1)
			silent exec 'normal! V'
			silent exec 'normal!'. l:indent_lines .'j='
		else
			normal! ==
		endif
	endif
endfunction

function! s:InitSnippet(amount)
	let l:type = 0
	let s:snip_start = line(".")
	let s:snip_end = s:snip_start + s:snip_line_count - 1
	let l:i = 0
	while l:i < a:amount
		call cursor(s:snip_start, 1)
		if search('\v\$(\{)?[0-9]+(:|!|\|)?', 'c') != 0
			call s:InitPlaceholder()
		endif
		let l:i += 1
	endwhile
	call s:InitVisuals()
endfunction

function! s:InitVisuals()
	let l:visual_amount = s:CountPlaceholders('\v\$\{VISUAL\}')
	let i = 0
	while i < l:visual_amount
		call cursor(s:snip_start, 1)
		call search('\v\$\{VISUAL\}', 'c', s:snip_end)
		exe "normal! f{%vF$c"
		let l:result = s:InitVisual('', '')
		let l:result_line_count = len(substitute(l:result, '[^\n]', '', 'g'))
		if l:result_line_count > 1
			silent exec 'normal! V'
			silent exec 'normal!'. l:result_line_count .'j='
			let s:snip_end += l:result_line_count
		endif
		let i += 1
	endwhile
	let s:visual_contents = ''
endfunction

function! s:InitVisual(before, after)
	if s:visual_contents != ''
		let l:visual = s:visual_contents
	else
		let l:visual = ''
	endif
	let l:save_s = @s
	let l:visual = s:RemoveTrailings(l:visual)
	let l:visual = a:before . l:visual . a:after
	let @s = l:visual
	normal! "sp
	let @s = l:save_s
	return l:visual
endfunction

function! s:CountPlaceholders(pattern)
	let l:cnt = s:Execute('%s/' . a:pattern . '//gn', "silent!")
	call histdel("/", -1)
	if match(l:cnt, 'not found') >= 0
		return 0
	endif
	let l:count = strpart(l:cnt, 0, stridx(l:cnt, " "))
	return substitute(l:count, '\v%^\_s+|\_s+%$', '', 'g')
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
	elseif match(l:ph, '\v\$\{[0-9]+\|.{-}\|\}') == 0
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
	exe "normal! mqf{%i\<Del>\<Esc>vg`qf:w\"syg`qdf:"
	let l:result = @s
	call setpos("'q", save_q_mark)
	let @" = l:save_quote
	let @s = l:save_s
	let l:repeater_count = s:CountPlaceholders('\v\$' . l:current)
	if l:repeater_count != 0
		call s:InitRepeaters(l:current, l:result, l:repeater_count)
	endif
endfunction

function! s:InitCommand()
	let save_q_mark = getpos("'q")
	let l:save_quote = @"
	let l:save_s = @s
	let l:placeholder = matchstr(getline('.'), '\v%'.col('.').'c\$\{[0-9]+!')
	let l:current = matchstr(l:placeholder, '\v(\$\{)@<=[0-9]+(!)@=')
	execute "normal! mqf{%i\<Del>\<Esc>vg`qf!w\"sdg`qcf! "
	let l:command = @s
	if executable(substitute(l:command, '\v(^\w+).*', '\1', 'g')) == 1
		let l:result = system(l:command)
	else
		let l:result = s:Execute("echo " . l:command, "silent!")
		if l:result == ''
			let l:result = l:command
		endif
	endif
	let l:result = s:RemoveTrailings(l:result)
	let @s = l:result
	let l:result_line_count = len(substitute(l:result, '[^\n]', '', 'g')) + 1
	if l:result_line_count > 1
		let s:snip_end += l:result_line_count
	endif
	exe "normal! g`qvr"
	normal! "sp
	normal! g`q
	call setpos("'q", save_q_mark)
	let @s = l:save_s
	let @" = l:save_quote
	let l:repeater_count = s:CountPlaceholders('\v\$' . l:current)
	if l:repeater_count != 0
		call s:InitRepeaters(l:current, l:result, l:repeater_count)
	endif
	noh
endfunction

function! s:InitChoice()
	let l:placeholder = matchstr(getline('.'), '\v%'.col('.').'c\$\{[0-9]+!')
	let l:current = matchstr(l:placeholder, '\v(\$\{)@<=[0-9]+(!)@=')
	let l:save_quote = @"
	let save_q_mark = getpos("'q")
	exec "normal! mqf|wvf,h\"syf,df}udf|xg`qdf|"
	let l:result = @s
	call setpos("'q", save_q_mark)
	let @" = l:save_quote
	let l:repeater_count = s:CountPlaceholders('\v\$' . l:current)
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
		call cursor(s:snip_start, 1)
		call search('\v\$'.a:index, 'c', s:snip_end)
		normal! mq
		call search('\v\$'.a:index, 'ce', s:snip_end)
		normal! mp
		exe "normal! g`qvg`pr"
		if l:amount_of_lines > 1
			let s:snip_end += l:amount_of_lines - 1
		endif
		normal! "sp
		let l:i += 1
	endwhile
	call setpos("'q", save_q_mark)
	call setpos("'p", save_p_mark)
	let @s = l:save_s
	let @" = l:save_quote
	call cursor(s:snip_start, 1)
	if l:amount_of_lines != 1
		let s:snip_end -= 1
	endif
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

