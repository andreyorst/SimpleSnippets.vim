" User input detection variables
let s:shift = 0
let s:text = ''
let s:line = 1
let s:start = 1
let s:len = 0
let s:popup_len = 0
let s:col = 1
let s:col_pre = 1
let s:input_active = 0

" Snippet in memory data
let s:mirrors = []
let s:current_snip = []

function! SimpleSnippets#input#handleUserInput()
	call s:ObtainInput()
	call s:UpdateSnippetInMemory()
	call s:UpdateMirrors()
	return ''
endfunction

function! SimpleSnippets#input#fixUserInput()
	call s:DeactivateInputDetection()
	call s:UpdateSnippetInMemory()
	call s:UpdateMirrors()
	return ''
endfunction

function! SimpleSnippets#input#Update()
	call s:UpdateSnippetInMemory()
	call s:UpdateMirrors()
	return ''
endfunction

function! SimpleSnippets#input#handleUserPreInput()
	let s:col_pre = getcurpos()[2]
	return ''
endfunction

function! SimpleSnippets#input#getText()
	return s:text
endfunction

function! s:DeactivateInputDetection()
	let s:input_active = 0
	let s:line = 1
	let s:col_pre = 1
	let s:len = 0
	let s:shift = 0
	let s:start = 1
	let s:popup_len = 0
	let s:col = 1
	return ''
endfunction

function! s:ObtainInput()
	let s:col = getcurpos()[2]
	if s:input_active == 0
		let s:text = ''
		let s:col_pre = s:col
		let s:shift = 0
		let s:popup_len = 0
		let s:input_active = 1
		let s:line = line('.')
		let s:start = s:col + s:shift
		let s:len = 0
	endif
	if s:line == line('.')
		if s:col >= s:start
			if !pumvisible()
				if s:popup_len > 0
					let s:len = s:popup_len
					let s:popup_len = 0
				endif
				if s:col == s:col_pre + 1
					let s:len += 1
					let s:col_pre = s:col
					let s:text = strpart(getline('.'), s:start - 1, s:len)
					return ''
				elseif s:col == s:col_pre - 1
					let s:len -= 1
					let s:col_pre = s:col
					let s:text = strpart(getline('.'), s:start - 1, s:len)
					return ''
				elseif s:col == s:col_pre
					if s:col < s:start + s:len
						let s:len -= 1
						let s:col_pre = s:col
						let s:text = strpart(getline('.'), s:start - 1, s:len)
						return ''
					endif
					return ''
				else
					if s:col > s:start + s:len
						let s:popup_len = s:col - s:start
						let s:text = strpart(getline('.'), s:start - 1, s:popup_len)
						return ''
					else
						if s:col >= s:col_pre
							let s:popup_len = s:len + s:col - s:col_pre
							let s:col_pre = s:col
							let s:text = strpart(getline('.'), s:start - 1, s:popup_len)
							return ''
						elseif s:col < s:col_pre
							let s:popup_len = s:len - (s:col_pre - s:col)
							let s:col_pre = s:col
							let s:text = strpart(getline('.'), s:start - 1, s:popup_len)
							return ''
						endif
					endif
				endif
			else
				if s:col >= s:start + s:len
					let s:popup_len = s:col - s:start
				else
					let s:popup_len = s:len + s:col - s:col_pre
				endif
				let s:text = strpart(getline('.'), s:start - 1, s:popup_len)
				return ''
			endif
		endif
	else
		let s:line = line('.')
		let s:start = s:col - 1 + s:shift
		let s:len = 1
		let s:text = ''
		let s:col_pre = s:col
		let s:text = strpart(getline('.'), s:start - 1, s:len)
		return ''
	endif
	return ''
endfunction

function! s:UpdateMirrors()
	return ''
endfunction

function! s:UpdateSnippetInMemory()
	return ''
endfunction

