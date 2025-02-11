" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_mescaline#🍄
" Summary: Wonderful Vim statusline interpretation.
" Requires: Relies on tpope/fugitive and scrooloose/syntastic.
" License: GPLv3 | Copyright © 2009, 2015-2017, 2025 Landon Bouma.

" -------------------------------------------------------------------

" The default statusline is ''.
"
" This implores Vim to show:
"
"   - First the filepath,
"     then [+] if dirty,
"     followed by row,column and
"     finally % through file,
"     in a plain, unstylized manner.
"
" Dubs Mescaline improves the status line:
"
"   - Adds a splash of color,
"     uses modern Unicode characters,
"     shows the mode (somewhat useless, but helps indicate active window),
"     shows the Git branch,
"     and restyles the cursor metrics to be easier to read.

" Note that this plugin does not use the built-in statusline highlights:
"
"   StatusLine, StatusLineNC, StatusLineTerm, and StatusLineTermNC
"
" Instead, it uses the User* (User1, User2, etc.) highlights so that
" it can use the Powerline glyphs and make a good looking status line.

" Wait until ready to do anything, in case Session.vim
" contains hooks to any style functions.
let s:ready_to_roll = 0

function! g:embrace#mescaline#MescalineSetStatusLineHighlights() abort
  " NOTE: To make the best use of the Powerline glyphs, alternate
  " foregrounds and backgrounds between adjacent colors, which has
  " the trick of making if look like we specially drew the status
  " line and didn't just use font and color magic.

  " The highlight colors are shared between the active and inactive
  " windows, and are used for the mode, git branch, and cursor/line/column
  " metrics. For the metrics, the colors are reversed for the inactive
  " windows, to help the user easily tell which window is active.
  " - HSTRY: This plugin used to use User1, User2, ... User9 and the
  "   corresponding statusline codes %1* %2* ... #9* but we'll use
  "   custom names instead to not conflict with however else user
  "   might use the user colors.
  hi MescalineF2Branch guifg=#dfff00 guibg=#005f00 gui=BOLD ctermfg=190 ctermbg=22 cterm=BOLD
  hi MescalineF1Mode guifg=#005f00 guibg=#dfff00 gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD
  hi MescalineF3Buffer guifg=#005f00 guibg=#00dfff gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD

  " MescalineF4NCEmpty fills the space after the path in not-current
  " window. The fg is the > color, and bg is the filler color that follows.
  if !s:clock_enable
    hi MescalineF4NCEmpty guifg=#00dfff guibg=#001f00 ctermfg=241 ctermbg=234
  else
    hi MescalineF4NCEmpty guifg=#333138 guibg=#001f00
  endif

  hi MescalineF5NCMetrics guifg=#001f00 guibg=#005f00 ctermfg=241 ctermbg=234

  hi MescalineNarrow guifg=#001f00 guibg=#001f00

  " MescalineF4Empty fills the space after the path in the current window:
  " the fg is the > color, and the bg is the filler color that follows.
  " (It's the 4th field if no clock, of fifth field if clock showing.)
  if !s:clock_enable
    hi MescalineF4Empty guifg=#00dfff guibg=#005f00 ctermfg=239 ctermbg=255
  else
    hi MescalineF4Empty guifg=#333138 guibg=#005f00 ctermfg=239 ctermbg=255
  endif

  " Metrics for current window (5th field, or 6th field if clock showing).
  hi MescalineF5Metrics guifg=#005f00 guibg=#dfff00 ctermfg=239 ctermbg=255

  if s:clock_enable
    hi MescalineF3Clock guifg=#005f00 guibg=#52B788
    hi MescalineF4Buffer guifg=#52B788 guibg=#333138
  endif

  " 2017-12-06: The original code that I copied changed the highlight
  "   of the mode text depending on the mode, but I find that distracting.
  "   And seeing the mode name is not a big deal, as you can usually infer
  "   the mode by looking at the cursor. It's a nifty trick, though.
endfunction

function! g:embrace#mescaline#MescalineSetStatusLineMode() abort
  let l:cmode = mode(1)
  let l:mode0 = s:omode
  let s:omode = l:cmode
  " NOTE: ==# forces case sensitive match, in case ignorecase is enabled.
  if l:mode0 ==# 'i' && l:cmode ==# 'n'
    " In Insert mode, if you arrow up or arrow down, the mode toggles
    "   to Normal mode and then back to Insert. (I have no idea way.)
    " As such, set a timer and wait to check if user really did switch modes.
    "   https://github.com/vim/vim/blob/master/runtime/doc/version8.txt#L66
    if has("timers")
      call timer_start(125, 'g:embrace#mescaline#TickleStatusLineMode')
      let l:timer_id = timer_start(125, 'g:embrace#mescaline#TickleStatusLineMode')
    else
      " Not +timers.
      " So... there doesn't seem to be an issue without +timers.
      "   2018-01-29 21:24: Or perhaps it's the machine I'm on.
      call g:embrace#mescaline#TickleStatusLineMode(0)
    end
    "echom 'Skipping Statusline to avoid flashing.'
    return s:ModeFriendlyString(l:mode0)
  else
    return s:ModeFriendlyString(l:cmode)
  endif
endfunction

function! g:embrace#mescaline#TickleStatusLineMode(timer_id) abort
  " Set statusline= again, which'll trigger a refresh.
  call s:SetStatusLine(0)
endfunction

" NOTE: You canNOT use, e.g., "^V" or "\^V", to match control characters.
" For more on this list, see :help mode()
let s:vim_mode_lookup = {
  \ "n":       "NORMAL",
  \ "no":      "O·PEND",
  \ "nov":     "O·PEND",
  \ "noV":     "O·PEND",
  \ "no<C-V>": "V·BLCK",
  \ "niI":     "I·NORM",
  \ "niR":     "R·NORM",
  \ "niV":     "V·NORM",
  \ "nt":      "T·NORM",
  \ "v":       "V·CHAR",
  \ "vs":      "S·VC·O",
  \ "V":       "V·LINE",
  \ "Vs":      "S·VL·O",
  \ "\<C-V>":  "V·BLCK",
  \ "\<C-V>s": "S·VBLK",
  \ "s":       "S·CHAR",
  \ "S":       "S·LINE",
  \ "\<C-S>":  "S·BLCK",
  \ "i":       "INSERT",
  \ "ic":      "I·COMP",
  \ "ix":      "I·C-X ",
  \ "R":       "RPLACE",
  \ "Rc":      "R·COMP",
  \ "Rx":      "R·C-X ",
  \ "Rv":      "V·RPLC",
  \ "Rvc":     "VCOM·G",
  \ "Rvx":     "VCOM·X",
  \ "c":       "CMD·LN",
  \ "ct":      "CMDL·T",
  \ "cr":      "CMDL·I",
  \ "cv":      "VIM·EX",
  \ "cvr":     "VIMEXO",
  \ "ce":      "NRM·EX",
  \ "r":       "PROMPT",
  \ "rm":      "-MORE-",
  \ "r?":      "CNFIRM",
  \ "!":       "!SHELL",
  \ "t":       "TRMNAL",
\ }

function! s:ModeFriendlyString(mode) abort
  return get(s:vim_mode_lookup, a:mode, "NOTFND")
endfunction

" MAYBE/2017-12-05: This function is called often.
"   Can we cache lookup of { winnr => active? }
"   and return immediately if no change needed?
function! s:FetchStatusLineMain(active_window) abort
  " Start with an empty statusline. We build a string, rather than
  " calling `set statusline+=`, so that we can build the statusline
  " differently based on the window width.
  let l:statline=''

  " REFER: There are two ways to set color, e.g.,
  "   Using User1 .. User9:
  "     set statusline+=%2*       " Switch to color `User2`.
  "   Using any named highlight:
  "     set statusline+=%#todo#   " Switch to `todo` highlight.

  " You can insert a unicode character easily from Insert mode, e.g.,:
  "   <C-q> u21D2
  " Note that Hack font includes 7 of 36 Powerline glyphs.
  "   https://github.com/ryanoasis/powerline-extra-symbols#glyphs
  " Hack includes this Powerline glyphs:
  "   e0a0       " a branch symbol
  "   e0a1       " an L/N symbol
  "   e0a2       " a lock symbol
  "   e0b0       " a solid right-half of a diamond
  "   e0b1       " an outline of a right-half of a diamond
  "   e0b2       " a solid left-half of a diamond
  "   e0b3       " an outline of a left-half of a diamond
  " Note that there's an aggregate font, Nerd Fonts, which seems awesome
  " -- it includes all of the Powerline glyphs, for one -- but there's a
  " 1-pixel space at the edge of each Powerline glyph. Bah.
  " Note also that the Powerline glyphs are not actual Unicode.
  "   http://www.fileformat.info/info/unicode/char/e0b0/index.htm
  " The 'Symbol, Other' category has good unicode.
  "   http://www.fileformat.info/info/unicode/category/So/list.htm

  if a:active_window
    let l:statline .= "%#MescalineF1Mode#"
    let l:statline .= "%#MescalineF1Mode#%{g:embrace#mescaline#MescalineSetStatusLineMode()}"
    let l:statline .= "%#MescalineF2Branch#"
  else
    let l:statline .= "%#MescalineF2Branch#"
  endif

  " Add the Git branch.
  let l:statline .= "%{strlen(fugitive#statusline())>0?'\\ " .. s:git_icon .. "\\ ':''}"
  " We can get the statusline, but I cannot figure out how to parse it.
  " E.g., this works:
  "   let l:statline .= "%{fugitive#statusline()}"
  " And this works if you run it:
  "   echo matchstr(fugitive#statusline(),'(\zs.*\ze)')
  " But adding the matchstr(...) to statusline, even trying different
  "   escaping for the glob, fails.
  " Fortunately, we can just make is a callback.
  let l:statline .= '%{g:embrace#mescaline#MescalineFetchStatusLineGitBranch()}'

  if !s:clock_enable
    let l:statline .= "\\ %#MescalineF3Buffer#\\ "
  else
    let l:statline .= "\\ %#MescalineF3Clock#\\ "
    let l:statline .= "%#MescalineF3Clock#"
    let l:statline .= '%{g:embrace#mescaline#MescalinePrintClockTime()}'
    let l:statline .= "\\ %#MescalineF4Buffer#\\ "
  endif

  let l:avail_width = winwidth(0)
  if a:active_window
    " Remove 8 characters for the mode status.
    let l:avail_width -= 8
  endif
  " If you add %b/%B, below:
  "let l:avail_width -= 16
  " Remove ' 61% ☰ 1234/1234 : 123 '
  let l:avail_width -= 23
  if strlen(fugitive#statusline()) > 0
    " tpope's fugitive returns, e.g., [Git(master)]
    let l:avail_width -= (strlen(fugitive#statusline()) - 7)
    " For the '>  ... '
    let l:avail_width -= 5
  endif

  " Account for the clock "hh:mm"
  if s:clock_enable
    let l:avail_width -= 5
  endif

  " Account for spaces for filename and for transition highlight.
  if a:active_window
    let l:avail_width -= 4
  else
    let l:avail_width -= 3
  endif

  " h F   Help buffer flag, text is "[help]".
  " H F   Help buffer flag, text is ",HLP".
  let l:help_status = ''
  if &ft ==# 'help'
    let l:help_status = '\ [help]'
    let l:avail_width -= strlen(l:help_status)
  endif

  if &ro == 1
    " Trim ' '
    let l:avail_width -= 2
  endif

  if &mod == 1
    " Trim ' 🚩'
    let l:avail_width -= 2
  endif

  if l:avail_width > 0
    " f S   Path to the file in the buffer, as typed or relative to current
    "       directory.
    " F S   Full path to the file in the buffer.
    " t S   File name (tail) of file in the buffer.
    " m F   Modified flag, text is "[+]"; "[-]" if 'modifiable' is off.
    " M F   Modified flag, text is ",+" or ",-".
    " r F   Readonly flag, text is "[RO]".
    " R F   Readonly flag, text is ",RO".
    let l:statline .= "%." . l:avail_width . "f%{&ro?'\\ ':''}%{&mod?'\\ 🚩':''}%<"
  endif
  " We should not use &ft because it's not set to 'help' when the help is
  " first opened, so it's not display until user, say, reenters window.
  "   let l:statline .= l:help_status
  " We use minwidth of 7 to ensure a leading space.
  let l:statline .= '%7h' . '\ '

  " MAYBE/2017-12-05: Does this ever return non-empty string?
  let l:statline .= "%#warningmsg#"
  if exists("*SyntasticStatuslineFlag")
    " ISOFF/2024-12-10: Syntastic (and dubs_syntastic_wrap) is (are) deprecated.
    " - MAYBE: Replace with CoC or other disagnostic status.
    let l:statline .= "%{SyntasticStatuslineFlag()}"
  endif

  if a:active_window
    let l:statline .= "%#MescalineF4Empty#"
  else
    let l:statline .= "%#MescalineF4NCEmpty#"
  endif
  let l:statline .= ""

  if l:avail_width <= 0
    let l:statline = ''
    let l:statline .= "\\ %#MescalineNarrow#\\ "
  endif
  " %=  split left-aligned and right-aligned
  let l:statline .= "%="

  if a:active_window
    let l:statline .= "%#MescalineF5Metrics#"
  else
    let l:statline .= "%#MescalineF5NCMetrics#"
  endif
  let l:statline .= ""

  " Skip: fileformat, e.g., 'unix'.
  "  let l:statline .= "\\ %{strlen(&fileformat)>0?&fileformat.'\\ ⮃\\ ':''}"

  " Skip: fileencoding, e.g., 'utf-8'.
  "  let l:statline .= "%{strlen(&fileencoding)>0?&fileencoding.'\\ ⮃\\ ':''}"

  " Skip: filetype, e.g., 'vim'. Doesn't seem particularly useful...
  "  let l:statline .= "%{strlen(&filetype)>0?&filetype:''}"

  " p N   Percentage through file in lines as in |CTRL-G|.
  let l:statline .= "\\ %p%%"

  " DEV: Uncomment if you want to see the decimal and the
  "   hexadecimal value of the character under the cursor.
  " b N   Value of character under cursor.
  " B N   As above, in hexadecimal.
  ""let l:statline .= "\\ \\ 🔠\\ %b/u%B"
  "let l:statline .= "\\ \\ 🔠\\ %5b/u%4B"

  " l N   Line number.
  " c N   Column number.
  " L N   Number of lines in buffer.
  "let l:statline .= "\\ \\ \\ %l:%c"
  "let l:statline .= "\\ ☰\\ %3l/%3L\\ \\ :%3c"
  "let l:statline .= "\\ ☰\\ %3l/%3L\\ :%3c"
  " Maybe if %l is 4 digits, add extra space after ☰?
  let l:statline .= "\\ ☰\\ %4l/%4L\\ :%3c"

  let l:statline .= "%#MescalineF1Mode#█"

  return l:statline
endfunction

function! s:SetStatusLine(nr) abort
  " If not the active window, switch to it, so we can call setlocal.
  let l:orig_nr = winnr()
  if a:nr > 0 && a:nr != l:orig_nr
    try
      execute a:nr . 'wincmd w'
    catch
      " Happens when searching and results scroll by.
      " E788: Not allowed to edit another buffer now
      " MAYBE/2017-12-05: You'd think you could detect this
      "   and not just have to blindly try.
      "echom "Skip winnr: " . winnr()
      return
    endtry
  endif

  let l:active_window = (a:nr == 0)

  let l:statline = s:FetchStatusLineMain(l:active_window)

  " WEIRD: If only one window open, calling setlocal doesn't do the trick.
  if winnr('$') == 1
    exe 'set statusline=' . l:statline
  else
    exe 'setlocal statusline=' . l:statline
  end

  if winnr() != l:orig_nr
    execute l:orig_nr . "wincmd w"
  endif
endfunction

function! g:embrace#mescaline#MescalineFetchStatusLineGitBranch() abort
  return matchstr(fugitive#statusline(),'(\zs.*\ze)')
endfunction

function! g:embrace#mescaline#MescalinePrintClockTime() abort
  return strftime('%H:%M')
endfunction

let s:oldnr = -1
let s:omode = ''
function! s:on_window_changed(event_name) abort
  "echom 'on_window_changed: on ' . a:event_name
  if s:ready_to_roll == 0
    return
  endif

  let l:restore_mru = 1
  let l:mrunr = -1

  let l:curnr = winnr()
  if l:restore_mru == 1
    " NOTE: Core Vim will "lock" a buffer when it's doing something
    " synchronous and doesn't want you changing the current buffer
    " (which includes switching windows). If you try, you'll see the
    " error message:
    "
    "   E788: Not allowed to edit another buffer now
    "
    " However, you won't see the error message if you try-catch.
    " And note that you don't need "silent!" to suppress the error;
    " rather, using silent will both suppress the error and the exception.
    if winnr('$') > 1
      try
        " Determine previous window, so we can restore
        " same gesture for other plugins. (I.e., don't
        " ruin the MRU window list for other code.)
        wincmd p
        let l:mrunr = winnr()
        wincmd p
      catch
        "echom "Buffer is locked! Cannot switch windows."
        return
      endtry
    endif
  endif

  "echom 'In on_window_changed: curnr: ' . l:curnr . ' / mrunr: ' l:mrunr . ' / oldnr: ' s:oldnr

  if l:curnr == s:oldnr
    "echom 'Skipping Statusline for same window again.'
    return
  endif
  let s:oldnr = l:curnr

  for nr in filter(range(1, winnr('$')), 'v:val != winnr()')
    "echom 'On inactive window: ' . nr . ' / ' . winbufnr(nr)
    call s:SetStatusLine(nr)
  endfor

  "echom 'On active window: ' . winnr() . ' / ' . winbufnr(0)
  call s:SetStatusLine(0)

  if l:mrunr != -1
    execute 'silent ' . l:mrunr . 'wincmd w'
    execute 'silent ' . l:curnr . 'wincmd w'
  endif

  "echom 'Done on_window_changed: curnr: ' . l:curnr . ' / mrunr: ' l:mrunr
endfunction

function! s:MescalineStandUpStatusline() abort
  call g:embrace#mescaline#MescalineSetStatusLineHighlights()

  " You won't need to see the mode twice, veritically adjacent one another.
  " - We put the mode in our MescaLine, so omit from the Vim status line.
  "   Note that this makes some interactions nicer, e.g., in insert mode,
  "   Vim normally shows the test "-- INSERT --", but this hides/obscures
  "   any messages your plugins might try to write, e.g., to :echomsg.
  set noshowmode

  augroup <SID>DubsMescaLine
    autocmd!

    autocmd CmdwinEnter * call <SID>on_window_changed('CmdwinEnter')
    autocmd WinEnter * call <SID>on_window_changed('WinEnter')
    autocmd BufWinEnter * call <SID>on_window_changed('BufWinEnter')
    autocmd FileType * call <SID>on_window_changed('FileType')
    autocmd BufUnload * call <SID>on_window_changed('BufUnload')
    " MAYBE/2017-12-10: I was having problems with close-all, but I think
    " I fixed them. Otherwise, I was considering maybe needing to hook
    " some exit events, but none of them seemed very useful.
    "   BufDelete, BufHidden, BufFilePre, BufFilePost (before/after renaming cur buf)
    "   BufLeave, BufUnload, BufWinLeave, WinLeave, VimLeave

    " NOTE: There does not seem to be an event for resizing splits,
    " just for resizing the entire Vim window. I even wrote to the
    " log and did not see any activity when dragging a split and
    " resizing two windows.
    "   gvim -V9myVim.log \
    "     ~/.kit/nvim/landonb/start/dubs_appearance/after/plugin/dubs_appearance.vim
    autocmd VimResized * call <SID>on_window_changed('VimResized')

    " Reset the highlights after a :colorscheme change.
    autocmd ColorScheme * call g:embrace#mescaline#MescalineSetStatusLineHighlights()
  augroup END

  if get(s:, 'timer', 0)
    call timer_stop(s:timer)

    unlet! s:timer
  endif

  if s:clock_enable
    let s:timer = timer_start(s:clock_rate, 'g:embrace#mescaline#MescalineUpdateStatusline', { 'repeat': -1 })
  endif

  let s:ready_to_roll = 1
endfunction

function! g:embrace#mescaline#MescalineUpdateStatusline(timer_id) abort
  " BWARE: This causes status line and window title to blip every second:
  "   call s:on_window_changed('timer')
  " WORKS: And somehow updates *all* windows' status lines.
  call s:SetStatusLine(0)
endfunction

function! s:SetupOpts(opts = {}) abort
  let s:clock_enable = get(a:opts, 'clock_enable', 0)
  let s:clock_rate = get(a:opts, 'clock_rate', 1000)
  " DPEND: Nerd Font:   󰊢            󰽜    󰃸 󱓠 󰘭  
  " - HSTRY: Some icons this plugin has tried:  ⛬ 
  let s:git_icon = get(a:opts, 'git_icon', '')
endfunction

" USAGE: E.g.,
"   call g:embrace#mescaline#Setup({'clock_enable': 1})
" Defaults:
"   call g:embrace#mescaline#Setup({'clock_enable': 0, 'clock_rate': 1000, 'git_icon': ''})
function! g:embrace#mescaline#Setup(opts = {}) abort
  call s:SetupOpts(a:opts)

  if exists("v:vim_did_enter") && v:vim_did_enter
    call s:MescalineStandUpStatusline()
  else
    augroup s:DubsMescaLineVimEnter
      autocmd!

      autocmd VimEnter * call <SID>MescalineStandUpStatusline()
    augroup END
  endif
endfunction

