" Globals
let s:active = 0

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
	\'jump_cnt': 0,
\}

"Functions
function! SimpleSnippets#getSnippetItem()
	return s:snippet
endfunction

function! SimpleSnippets#expandOrJump()
	if SimpleSnippets#core#isExpandable()
		call SimpleSnippets#expand()
	elseif SimpleSnippets#isJumpable()
		call SimpleSnippets#jump#forward()
	endif
endfunction

function! SimpleSnippets#isExpandableOrJumpable()
	if SimpleSnippets#core#isExpandable()
		return 1
	elseif SimpleSnippets#isJumpable()
		return 1
	else
		let s:snippet.trigger = ''
		return 0
	endif
endfunction

function! SimpleSnippets#isJumpable()
	if SimpleSnippets#core#isInside(s:snippet)
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

function! SimpleSnippets#isExpandable()
	call s:ObtainTrigger()
	if s:GetSnippetFiletype(s:snippet.trigger) != -1
		return 1
	endif
	call s:ObtainAlternateTrigger()
	if s:GetSnippetFiletype(s:snippet.trigger) != -1
		return 1
	endif
	let s:snippet.trigger = ''
	return 0
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
