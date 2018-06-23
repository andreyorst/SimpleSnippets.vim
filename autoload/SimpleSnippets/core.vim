function! SimpleSnippets#core#obtainTrigger()
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

