" Globals
let s:active = 0
let s:flash_snippets = {}
let s:snippetPluginInstalled = 0
let s:trigger = ''
let s:snippet = {}
let s:escape_pattern = '/\*~.$^!#'

"Functions
function! SimpleSnippets#expandOrJump()
	if SimpleSnippets#isExpandable()
		call SimpleSnippets#expand()
	elseif SimpleSnippets#isJumpable()
		call SimpleSnippets#jump#forward()
	endif
endfunction

function! SimpleSnippets#isExpandableOrJumpable()
	if SimpleSnippets#isExpandable()
		return 1
	elseif SimpleSnippets#isJumpable()
		return 1
	else
		let s:snippet.trigger = ''
		return 0
	endif
endfunction

function! SimpleSnippets#isJumpable()
	if s:IsInside(s:snippet)
		if s:active == 1
			return 1
		endif
	endif
	let s:active = 0
	return 0
endfunction

function! SimpleSnippets#getVisual()
	let l:save_v = @v
	normal! g`<vg`>"vc
	let s:snippet.visual = @v
	let @v = l:save_v
	startinsert!
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

function! SimpleSnippets#isExpandable()
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
	return 0
endfunction

function! s:ObtainTrigger()
	if mode() == 'i'
		let l:cursor_pos = getpos(".")
		call cursor(line('.'), col('.') - 1)
		let l:trigger = expand("<cWORD>")
		call cursor(l:cursor_pos[1], l:cursor_pos[2])
	else
		let l:trigger = expand("<cWORD>")
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
		let l:string = substitute(l:string, "',", '\n', &gdefault ? 'gg' : 'g')
		let l:string = substitute(l:string, " '", '', &gdefault ? 'gg' : 'g')
		let l:string = substitute(l:string, "{'", '', &gdefault ? 'gg' : 'g')
		let l:string = substitute(l:string, "'}", '', &gdefault ? 'gg' : 'g')
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
			let l:list[i] = substitute(l:str, "':", l:delimeter, &gdefault ? 'gg' : 'g')
			let i += 1
		endfor
		let l:string = join(l:list, "\n")
		let l:string = substitute(l:string, "':", ': ', &gdefault ? 'gg' : 'g')
		let l:string = substitute(l:string, '\\n', '\\\n', &gdefault ? 'gg' : 'g')
		let l:string = substitute(l:string, '\\r', '\\\\r', &gdefault ? 'gg' : 'g')
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
				let l:descr .= substitute(line, '\v\$\{[0-9]+(:|!)(.{-})\}', '\2', &gdefault ? 'gg' : 'g')
				break
			endfor
			let l:descr = substitute(l:descr, '\v(\S+)(\})', '\1 \2', &gdefault ? 'gg' : 'g')
			let l:descr = substitute(l:descr, '\v\{(\s+)?$', '', &gdefault ? 'gg' : 'g')
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
	for key in keys(a:dict)
		if key =~ '\v'.escape(&bex, s:escape_pattern).'$'
			unlet! a:dict[key]
		endif
	endfor
	return a:dict
endfunction

function! s:ListSnippets()
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
	if s:snippetPluginInstalled == 1
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:plugin_filetype = s:GetMainFiletype(g:SimpleSnippets_snippets_similar_filetypes)
		call s:PrintSnippets("Plugin snippets:", l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		call s:PrintSnippets('User \"all\" snippets:', l:user_snips, 'all')
		if s:snippetPluginInstalled == 1
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
	if s:snippetPluginInstalled == 1
		let l:plugin_filetype = s:GetMainFiletype(g:SimpleSnippets_snippets_similar_filetypes)
		let l:plug_snips = g:SimpleSnippets_snippets_plugin_path
		let l:snippets = s:GetSnippetDictonary(l:snippets, l:plug_snips, l:plugin_filetype)
	endif
	if l:filetype != 'all'
		let l:snippets = s:GetSnippetDictonary(l:snippets, l:user_snips, 'all')
		if s:snippetPluginInstalled == 1
			let l:snippets = s:GetSnippetDictonary(l:snippets, l:plug_snips, 'all')
		endif
	endif
	if s:flash_snippets != {}
		for trigger in keys(s:flash_snippets)
			let l:snippets[trigger] = substitute(s:flash_snippets[trigger], '\v\$\{[0-9]+(:|!)(.{-})\}', '\2', &gdefault ? 'gg' : 'g')
		endfor
	endif
	return l:snippets
endfunction


" 7.4 compability layer
function! SimpleSnippets#execute(command, ...)
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

function! SimpleSnippets#addFlashSnippet(trigger, snippet_defenition)
	let s:flash_snippets[a:trigger] = a:snippet_defenition
endfunction

function! SimpleSnippets#removeFlashSnippet(trigger)
	let l:i = 0
	if has_key(s:flash_snippets, a:trigger)
		unlet![a:trigger]
	endif
endfunction

function! s:IsInside(snippet)
	if a:snippet.curr_file == @%
		let l:current_line = line(".")
		if l:current_line >= s:snippet.start && l:current_line <= s:snippet.end
			return 1
		else
			return 0
		endif
	endif
	return 0
endfunction

function! SimpleSnippets#expand()
	let s:snippet = {
		\'start': 0,
		\'end': 0,
		\'line_count': 0,
		\'curr_file': '',
		\'ft': '',
		\'trigger': '',
		\'visual': '',
		\'body': [],
		\'ph_amount': 0,
		\'ts_amount': 0,
		\'ph_data': {},
		\'jump_cnt': 0,
	\}
	let s:snippet.trigger = s:trigger
	let s:snippet.ft = s:GetSnippetFiletype(s:snippet.trigger)
	if s:snippet.ft == 'flash'
		let s:snippet.body = split(s:flash_snippets[s:snippet.trigger], '\n')
		let s:snippet.body = s:PrepareSnippetBodyForParser(s:snippet.body)
		let s:snippet.line_count = len(s:snippet.body)
		call s:ExpandFlash()
	else
		let s:snippet.body = s:ObtainSnippet()
		let s:snippet.body = s:PrepareSnippetBodyForParser(s:snippet.body)
		let s:snippet.line_count = len(s:snippet.body)
		call s:ExpandNormal()
	endif
	let s:snippet = {}
endfunction

function! s:ObtainSnippet()
	let l:path = s:GetSnippetPath(s:snippet.trigger, s:snippet.ft)
	let l:snippet = readfile(l:path)
	while l:snippet[0] == ''
		call remove(l:snippet, 0)
	endwhile
	while l:snippet[-1] == ''
		call remove(l:snippet, -1)
	endwhile
	return l:snippet
endfunction

function! s:GetSnippetPath(snip, filetype)
	if filereadable(g:SimpleSnippets_search_path . a:filetype . '/' . a:snip)
		return g:SimpleSnippets_search_path . a:filetype . '/' . a:snip
	elseif s:snippetPluginInstalled == 1
		if filereadable(g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip)
			return g:SimpleSnippets_snippets_plugin_path . a:filetype . '/' . a:snip
		endif
	endif
endfunction

function! s:ExpandNormal()
	if s:snippet.line_count != 0
		let l:save_s = @s
		let @s = join(s:snippet.body, "\n")
		let l:save_quote = @"
		if s:snippet.trigger =~ "\\W"
			normal! ciW
		else
			normal! ciw
		endif
		normal! "sp
		let s:snippet.start = line(".")
		let s:snippet.end = s:snippet.start + s:snippet.line_count - 1
		let @" = l:save_quote
		let @s = l:save_s
		call s:ParseAndInit()
	else
		echohl ErrorMsg
		echo '[ERROR] Snippet body is empty'
		echohl None
	endif
endfunction

function! s:ExpandFlash()
	let l:save_quote = @"
	if s:snippet.trigger =~ "\\W"
		normal! ciW
	else
		normal! ciw
	endif
	let l:save_s = @s
	let @s = s:snippet.body
	normal! "sp
	let s:snippet.start = line(".")
	let s:snippet.end = s:snippet.start + s:snippet.line_count - 1
	let @s = l:save_s
	if s:snippet.line_count != 1
		let l:indent_lines = s:snippet.line_count - 1
		silent exec 'normal! V' . l:indent_lines . 'j='
	else
		normal! ==
	endif
	silent call s:ParseAndInit()
endfunction

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
	echo s:snippet.ph_data
	echo "\n"
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
