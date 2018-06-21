function! SimpleSnippets#core#isExpandable()
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


function! SimpleSnippets#core#isInside()
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