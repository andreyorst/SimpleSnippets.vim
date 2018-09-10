function! SimpleSnippets#parser#init(snippet)
	call s:PrepareSnippetBodyForParser(a:snippet)
endfunction

function! CountRegexMatches(expr, regex)
	let l:submatches = []
	let l:type = type(a:expr)
	if l:type == 1
		call substitute(a:expr, a:regex, '\=add(l:submatches, submatch(0))', &gd ? 'gg' : 'g')
	elseif l:type == 3
		for l:string in a:expr
			call substitute(l:string, a:regex, '\=add(l:submatches, submatch(0))', &gd ? 'gg' : 'g')
		endfor
	else
		echo "[Error] wrong arguments"
		return -1
	endif
	return len(l:submatches)
endfunction

function! s:RemoveTrailings(text)
	let l:result = substitute(a:text, '\n\+$', '', '')
	let l:result = substitute(l:result, '\s\+$', '', '')
	let l:result = substitute(l:result, '^\s\+', '', '')
	let l:result = substitute(l:result, '^\n\+', '', '')
	return l:result
endfunction

function! s:PrepareSnippetBodyForParser(snippet)
	let i = 0
	while i < len(a:snippet.body)
		if a:snippet.body[i] =~ '\v\$\d+'
			let a:snippet.body[i] = substitute(a:snippet.body[i], '\v\$([0-9]+)', '${\1:}', &gd ? 'gg' : 'g')
		endif
		if a:snippet.body[i] =~ '\v\$\{\d+\}'
			let a:snippet.body[i] = substitute(a:snippet.body[i], '\v\$\{([0-9]+)\}', '${\1:}', &gd ? 'gg' : 'g')
		endif
		let i += 1
	endwhile
endfunction

function! GetSinglePlaceholderPosition(line, ph)
	let l:start = 0
	let l:end = 0
	let l:trigger = 0
	let l:inside = 0
	let l:opened_braces = 0
	let l:position = 0
	let l:ph = split(a:ph, '\zs')
	let l:ph_len = len(l:ph)
	let l:match = 0
	let l:inside_matched = 0
	let l:inside_another = 0
	for letter in split(a:line, '\zs')
		if l:match != l:ph_len
			if letter == l:ph[l:match]
				let l:match += 1
				if l:match == l:ph_len
					let l:inside_matched = 1
					let l:start = l:position
				endif
			else
				let l:match = 0
			endif
		endif
		if letter == '$'
			let l:trigger += 1
		elseif letter == '{'
			let l:opened_braces += 1
			let l:trigger += 1
		elseif l:trigger != 0 && letter =~ '\d'
			let l:trigger += 1
		elseif l:trigger != 0 && letter =~ '\(:\|!\||\)'
			if l:inside_matched == 0
				let l:inside_another += 1
			endif
			let l:trigger += 1
		elseif letter == '}'
			let l:trigger += 1
			if l:opened_braces != 0
				let l:opened_braces -= 1
			endif
			if l:opened_braces == 0
				if l:inside_another != 0
					let l:inside_another -= 1
				endif
			endif
			if l:inside_matched && l:opened_braces == l:inside_another
				let l:opened_braces -= 1
				let l:end = l:position
				break
			endif
		endif
		let l:position += 1
	endfor
	return [l:start, l:end]
endfunction
