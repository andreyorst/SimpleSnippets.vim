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

