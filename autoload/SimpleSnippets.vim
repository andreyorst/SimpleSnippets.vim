if exists('b:did_autoload_simplesnippets')
	" finish
endif

let b:did_autoload_simplesnippets = 1

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
		return 0
	endif
endfunction

function! SimpleSnippets#isJumpable()
	if SimpleSnippets#core#IsInside()
		return SimpleSnippets#core#IsActive()
	endif
	return 0
endfunction

function! SimpleSnippets#isExpandable()
	let l:trigger = SimpleSnippets#input#getText()
	if s:GetSnippetFiletype(l:trigger) != -1
		return 1
	endif
	let l:trigger =  SimpleSnippets#input#obtainTrigger()
	if s:GetSnippetFiletype(l:trigger) != -1
		return 1
	endif
	let l:trigger = SimpleSnippets#input#obtainTRIGGER()
	if s:GetSnippetFiletype(l:trigger) != -1
		return 1
	endif
	return 0
endfunction

