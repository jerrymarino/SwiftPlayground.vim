let s:path = fnamemodify(expand('<sfile>:p:h'), ':h')

autocmd BufWritePost *.playground/Contents.swift call s:OnBufWritePost()
" Bind to all: we close on entering different file types
autocmd BufEnter * call s:OnBufEnter()

autocmd CursorMoved *.playground/Contents.swift call s:OnCursorMoved()
autocmd CursorMovedI *.playground/Contents.swift call s:OnCursorMovedI()

command! SwiftPlaygroundPreviewImage call s:PreviewImage()

let s:LastSwiftTopline = 0
let s:BuildDirectory = ""

" When the user writes the file we'll execute the runner program
function! s:OnBufWritePost()
    call SwiftPlaygroundExecute()
endfunction

" Init the UI when we enter a playground
function! s:OnBufEnter()
    " Workaround for weird completion plugins
    if pumvisible()
        return
    endif

    let cur_file = expand('%:p')
    " Check if the current buffer is in swift
    if match(cur_file, ".playground/Contents.swift") != -1
        let cur_bufnr = bufnr('%')
        call s:InitPlaygroundUI()
        let play_winnr = bufwinnr(cur_bufnr)
        if play_winnr != -1
            execute play_winnr . ' wincmd w'

            " On the first time, we'll execute it. Perhaps this is slow or not
            " ideal in some cases, and is cool for simple playgrounds.
            " Fix with async execution
        endif
    else
        call SwiftPlaygroundCloseIfNeeded()
    endif
endfunction

function! s:SyncBuffers()
    let topline = line("w0")

    if topline != s:LastSwiftTopline
        let s:LastSwiftTopline = topline
        let cur_bufnr = bufnr('%')
        let play_bufnr = bufnr('__Playground__')
        let play_bufwinnr = bufwinnr(play_bufnr)

        if play_bufwinnr == -1
            return
        endif

        let winview = winsaveview()
        silent! execute play_bufwinnr . " wincmd w"
        call winrestview(winview)
        silent! execute bufwinnr(cur_bufnr ) . " wincmd w"
    endif
endfunction

function! s:OnCursorMovedI()
    call s:SyncBuffers()
endfunction

function! s:OnCursorMoved()
    call s:SyncBuffers()
endfunction

function! SwiftPlaygroundExecute()
    let cur_file = expand('%:p')

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
    let split_lines = split(result, "\n")
    let s:BuildDirectory = split_lines[0]
    for line in split_lines
        if has_key(set_lines, line)
            continue
        endif
        " Logs come in looking like [__range__] $builtin LogMessage
        let split_value = split(line, "$builtin_log ")
        if len(split_value) < 2
            continue
        endif

        let range = s:ParseLogPrefix(line, " ")
        let target = range[0][0] + 1
        while line_num < target - 1
            let doc = doc . " \n"
            let line_num = line_num + 1
        endwhile

        let line_value = split_value[1]
        let set_lines[line] = 1
        let doc = doc . line_value . "\n"
        let line_num = line_num + 1
    endfor

    " If there is no doc parsed from StdLib, logging, then it is likely an
    " error. FIXME: use errors from the runner ( QuickFix or something )
    if len(doc) == 0
        let doc = doc . result
        let winview = {}
    else
        let winview = winsaveview()
    endif
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

    " Sync buffers. FIXME: This should really be an autocmd on scroll.
    if winview != {}
        call winrestview(winview)
    else
        call cursor(1, 0)
    endif

    silent! execute bufwinnr(cur_bufnr ) . " wincmd w"
endfunction

function! s:ParseLogPrefix(record, separator)
    let prefix = substitute(a:record,
                            \ '\[\([0-9\-:]*\)\]' .  a:separator . '.*',
                            \ '\1',
                            \ "g")
    let range = split(prefix, '-')
    if len(range) != 2
        return []
    endif
    let [start, end] = range
    let [start_line, start_col] = map(split(start, ":"), 'str2nr(v:val)')
    let [end_line, end_col] = map(split(end, ":"), 'str2nr(v:val)')
    return [[start_line, start_col], [end_line, end_col]]
endfunction

function! s:InitPlaygroundUI()
    " Initialize the playground
    let play_bufnr = bufnr('__Playground__')
    let play_winnr = bufwinnr(play_bufnr)
    if play_winnr == -1
        let play_winnr = bufwinnr(play_bufnr)
        " Assume 40 is good
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
        let msg = "Loaded Swift Playground..\n:w the playground to update" 
        call append(0, split(msg, '\v\n'))
    else
      if winnr() != play_winnr
        execute play_winnr . 'wincmd w'
      endif
    endif
endfunction

function! SwiftPlaygroundCloseIfNeeded()
    " Close the buffer if needed
    let play_bufnr = bufnr('__Playground__')
    let play_winnr = bufwinnr(play_bufnr)

    if play_winnr != -1 && play_winnr != bufnr('%')
        silent! execute play_bufnr . " wincmd w"
        silent! execute " q!"
        silent! execute cur_bufnr . " wincmd w"
    endif
endfunction

function! s:PreviewImage()
    if empty(s:BuildDirectory)
        call SwiftPlaygroundExecute()
    endif

    let current_line = line('.')
    let current_col = col('.')
    let cur_dir = expand('%:p:h')
    let asset_dir = simplify(s:BuildDirectory . "/Assets")
    let matched_fname = ""
    let matched_col = -1
    for name in globpath(asset_dir, "*.png", 0, 1)
        " Names are in format [_range_]_$builtin_repr@2x.png.
        if len(split(name, "_$builtin_log_")) < 2
            continue
        endif

        let range = s:ParseLogPrefix(fnamemodify(name, ":t"), "_")
        if empty(range)
            continue
        endif

        " Check if entry is within range of current cursor position.
        let [start, end] = range
        if start[0] <= current_line && end[0] >= current_line &&
          \ start[1] <= current_col && end[1] >= current_col
            let matched_fname = name
            break
        endif

        " Otherwise default to an entry matching the end line with the
        " greatest column.
        if end[0] == current_line && matched_col < end[1]
            let matched_fname = name
            let matched_col = end[1]
        end
    endfor

    if empty(matched_fname)
        echo "No image can be rendered at the current position."
    else
        call system("qlmanage -p " .
                    \ shellescape(matched_fname) .
                    \ ">/dev/null 2>&1 &")
    endif
endfunction
