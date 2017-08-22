set ft=markdown

set completefunc=CompleteField
fun! CompleteField(findstart, base)
    if a:findstart
        return col('.')
    else
        if col('.') > 7
            let space = col('.') == 8 ? ' @' : '@'
            return [
                \ space . 'break ',
                \ space . 'drift ',
                \ space . 'personal ',
                \ space . 'work ',
                \ space . 'emergence ',
            \]
        else
            return ['- ' . strftime('%H:%M')]
        endif
    endif
endfun

map <Leader>d :call Duration()<CR>
fun! Duration()
    try
        " Yank current timestamp
        call cursor('.', len(getline('.')))
        call search('\d\d:\d\d', 'b')
        let items = split(expand('<cWORD>'), ':')
        let end = items[0] * 60 + items[1]

        " Yank previous timestamp
        call cursor('.', 1)
        call search('\d\d:\d\d', 'b', search('^#', 'bn'))
        let items = split(expand('<cWORD>'), ':')
        let begin = items[0] * 60 + items[1]

        " Go back to original line
        call search('\d\d:\d\d')

        " Try to find next entry
        if search('\d\d:\d\d', '', search('^#', 'n')) > 0
            " normal k doesn't work for some reason
            call cursor(line('.') - 1, 1)
        else
            call cursor('$', 0)
        endif

        " Write difference
        let line = substitute(getline('.'), ' *$', '', '')
        call setline('.', line . " (" . (end - begin) . " minutes)")
    catch /E684:/ " list index out of range:
    endtry
endfun

fun! HumanTime(minutes)
    let hours = a:minutes / 60
    let minutes = a:minutes % 60

    if hours
        let hours = printf('%d hour%s ', hours, hours > 1 ? 's' : ' ')
    else
        let hours = ''
    endif

    return printf('%s%02d minute%s', hours, minutes, minutes > 1 ? 's' : '')
endfun

map <Leader>t :call Totals()<CR>
fun! Totals()
    " Go to the top of the section
    call search('^#', 'b')

    " Search all activity tags
    let counts = {}
    while search('@\w\+', '', search('^#', 'n'))
        let acttag = expand('<cword>')

        call search('(\d\+ minutes)')
        call cursor('.', col('.') + 1)
        let duration = expand('<cword>')
        try
            let counts[acttag] += duration
        catch /E734:/
            let counts[acttag] = duration
        endtry
    endwhile

    " Move cursor to the end of the section
    if search('^#')
        call cursor(line('.') - 2, 1)
    else
        call cursor('$', 1)
    endif

    " Report
    call append('.', '`````')
    call append('.', '')
    call cursor(line('.') + 1, 1)
    let total = 0
    for acttag in keys(counts)
        let total += counts[acttag]
        call append('.', printf('%-10s %s',
                              \ '@' . acttag,
                              \ HumanTime(counts[acttag])))
    endfor
    call append('.', printf('%-10s %s', '@total', HumanTime(total)))
    call append('.', '`````')

endfun

syn match Constant '(\d\+ minutes)'
syn match Comment '@\(work\|break\|drift\|personal\|emergence\)' 
syn match Identifier '\d\d:\d\d'
