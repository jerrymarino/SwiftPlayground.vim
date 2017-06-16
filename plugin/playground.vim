let s:path = fnamemodify(expand('<sfile>:p:h'), ':h')

" Hook in to the write command
autocmd BufWritePost * call s:OnBufWritePost()
autocmd BufEnter * call s:OnBufEnter()

" When the user writes the file we'll execute the runner program
function! s:OnBufWritePost()
    call ExecutePlayground()
endfunction

" Init the UI when we enter a playground
function! s:OnBufEnter()
    " Workaround for weird completion plugins
    if pumvisible()
        return
    endif

    let cur_file = expand('%:p')
    echom cur_file
    " Check if the current buffer is in swift
    if match(cur_file, ".playground/Contents.swift") != -1
        let cur_bufnr = bufnr('%')
        call InitPlaygroundUI()
        let play_winnr = bufwinnr(cur_bufnr)
        if play_winnr != -1
            execute play_winnr . ' wincmd w'

            " On the first time, we'll execute it. Perhaps this is slow or not
            " ideal in some cases, and is cool for simple playgrounds.
            " Fix with async execution
            call ExecutePlayground()
        endif
    else
        call CloseIfNeeded()
    endif
endfunction

function! ExecutePlayground()
    let cur_file = expand('%:p')
    " Check if the current buffer is in swift
    if match(cur_file, ".playground/Contents.swift") == -1
        return
    endif

    let src_root = s:path
    let cur_file = expand('%:p')
    let invocation = src_root . "/runner.sh " . cur_file
    let result = system(invocation)

    " Build up a UI from the result
    let line_num = 1
    let doc = ""

    " Track the line values, for they may be recorded
    " multiple times by the runtime
    let set_lines = {}
    for line in split(result, "\n")
        if has_key(set_lines, line)
            continue
        endif
        " Logs come in looking like [1:__range__] $bultin LogMessage
        "
        let split_value = split(line, "$builtin_log ")
        if len(split_value) < 2
            continue
        endif
        
        let target_str = split(split(line, "[")[0], ":")[0]
        let target = str2nr(target_str)
        while line_num < target
            let doc = doc . "\n"
            let line_num = line_num + 1
        endwhile

        let line_value = split_value[1]
        let set_lines[line] = 1
        let doc = doc . line_value . "\n"
        let line_num = line_num + 1
    endfor

    " This is kind of hacky.
    " - switch to the playground buffer
    " - clear it
    " - write out the new document
    let cur_bufnr = bufnr('%')
    let play_bufnr = bufnr('__Playground__')
    silent! execute bufwinnr(play_bufnr) . " wincmd w"

    let n_lines = line('$')
    let i = 0
    while i < n_lines
        silent! execute 'd' 
        let i = i + 1
    endwhile
    call append(0, split(doc, '\v\n'))

    silent! execute bufwinnr(cur_bufnr ) . " wincmd w"
endfunction

function! InitPlaygroundUI()
    " Initialize the playground
    let play_bufnr = bufnr('__Playground__')
    let play_winnr = bufwinnr(play_bufnr)
    if play_winnr == -1
        let play_winnr = bufwinnr(play_bufnr)
        silent! execute "botright 40 vnew" . "__Playground__"
        setlocal bufhidden=hide
        setlocal nobuflisted
        setlocal buftype=nofile
        setlocal foldcolumn=0
        setlocal nofoldenable
        setlocal nonumber
        setlocal noswapfile
        setlocal winfixheight
        setlocal winfixwidth
    else
      if winnr() != play_winnr
        execute play_winnr . 'wincmd w'
      endif
    endif
endfunction

function! CloseIfNeeded()
    " Close the buffer if needed
    let play_bufnr = bufnr('__Playground__')
    let play_winnr = bufwinnr(play_bufnr)
    if play_winnr != -1
        silent! execute play_bufnr . " wincmd w"
        silent! execute " q!"
        silent! execute cur_bufnr . " wincmd w"
    endif
endfunction

