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
	if SimpleSnippets#core#IsInside()
		return SimpleSnippets#core#IsActive()
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

function! s:CheckExternalSnippetPlugin()
	if exists('g:SimpleSnippets_snippets_plugin_path')
		let s:snippetPluginInstalled = 1
	endif
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

