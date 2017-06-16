autocmd BufWritePost * call s:OnBufWritePost()

" When the user writes the file we'll execute the runner program
function! s:OnBufWritePost()
    let src_root = resolve(expand('<sfile>:p:h'))
    let invocation = src_root . "/runner.sh"
    let result = system(invocation)
    let line_num = 0
    let doc = ""
    for line in split(result, "\n")
        " Logs come in looking like [1:__range__] $bultinMESSAGE
        let target_str = split(split(line, "[")[0], ":")[0]
        let target = str2nr(target_str)
        while target >= line_num
            let doc = doc . "\n"
            let line_num = line_num + 1
        endwhile
        let split_value = split(line, "$builtin_log")
        if len(split_value) < 2
            continue
        endif
        let line_value = split_value[1]
        let doc = doc . line_value . "\n"
    endfor

    " This is kind of hacky.
    " - switch to the playground buffer
    " - clear it
    " - write out the new document
    let cur_bufnr = bufnr('%')
    let scr_bufnr = bufnr('__Playground__')
    silent! execute scr_bufnr . " wincmd w"

    let n_lines = line('$')
    let i = 0
    while i < n_lines
        silent! execute 'd' 
        let i = i + 1
    endwhile
    call append(0, split(doc, '\v\n'))

    silent! execute cur_bufnr . " wincmd w"
endfunction

" Initialize the playground
let scr_bufnr = bufnr('__Playground__')
let scr_winnr = bufwinnr(scr_bufnr)
if scr_winnr == -1
  let scr_winnr = bufwinnr(scr_bufnr)
  silent! execute "botright vnew" . "__Playground__"
else
  if winnr() != scr_winnr
    execute scr_winnr . 'wincmd w'
  endif
endif

