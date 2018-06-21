function! SimpleSnippets#edit#snippet(trigg)
	let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	let l:path = g:SimpleSnippets_search_path . l:filetype
	let s:snip_edit_buf = 0
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	if a:trigg != ''
		let l:trigger = a:trigg
	else
		let l:trigger = input('Select a trigger: ')
	endif
	let l:trigger = s:TriggerEscape(l:trigger)
	if l:trigger == -1
		redraw
		echo "Whitespace characters can't be used in trigger definition"
		return -1
	endif
	if l:trigger != ''
		call s:CreateSplit(l:path, l:trigger)
		setf l:filetype
	else
		redraw
		echo "Empty trigger"
	endif
endfunction

function! SimpleSnippets#edit#descriptions(ft)
	if a:ft != ''
		let l:filetype = a:ft
	else
		let l:filetype = s:GetMainFiletype(g:SimpleSnippets_similar_filetypes)
	endif
	let l:path = g:SimpleSnippets_search_path . l:filetype
	let s:snip_edit_buf = 0
	if !isdirectory(l:path)
		call mkdir(l:path, "p")
	endif
	let l:descriptions = l:filetype.'.snippets.descriptions.txt'
	call s:CreateSplit(l:path, l:descriptions)
endfunction


function! s:CreateSplit(path, trigger)
	if exists("*win_gotoid")
		if win_gotoid(s:snip_edit_win)
			try
				exec "buffer " . s:snip_edit_buf
			catch
				exec "edit " . a:path . '/' . a:trigger
			endtry
		else
			if exists('g:SimpleSnippets_split_horizontal')
				if g:SimpleSnippets_split_horizontal != 0
					new
				else
					vertical new
				endif
			else
				vertical new
			endif
			try
				exec "buffer " . s:snip_edit_buf
			catch
				execute "edit " . a:path . '/' . a:trigger
				let s:snip_edit_buf = bufnr("")
			endtry
			let s:snip_edit_win = win_getid()
		endif
	else
		if exists('g:SimpleSnippets_split_horizontal')
			if g:SimpleSnippets_split_horizontal != 0
				new
			else
				vertical new
			endif
		else
			vertical new
		endif
		exec "edit " . a:path . '/' . a:trigger
	endif
endfunction

