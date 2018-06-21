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
		let s:trigger = ''
		return 0
	endif
endfunction

function! SimpleSnippets#isJumpable()
	if SimpleSnippets#core#isInside()
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

function! SimpleSnippets#addFlashSnippet(trigger, snippet_defenition)
	let s:flash_snippets[a:trigger] = a:snippet_defenition
endfunction

function! SimpleSnippets#removeFlashSnippet(trigger)
	let l:i = 0
	if has_key(s:flash_snippets, a:trigger)
		unlet![a:trigger]
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

