" File: dubs_appearance.vim
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Last Modified: 2017.12.19
" Project Page: https://github.com/landonb/dubs_appearance
" Summary: Basic Vim configuration (no functions; just settings and mappings)
" License: GPLv3
" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" ----------------------------------------------------------------------------
" Copyright © 2009, 2015-2017 Landon Bouma.
"
" This file is part of Dubs Vim.
"
" Dubs Vim is free software: you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation, either version
" 3 of the License, or (at your option) any later version.
"
" Dubs Vim is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty
" of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
" the GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with Dubs Vim. If not, see <http://www.gnu.org/licenses/>
" or write Free Software Foundation, Inc., 51 Franklin Street,
"                     Fifth Floor, Boston, MA 02110-1301, USA.
" ===================================================================

if exists("g:plugin_dubs_mescaline") || &cp
  finish
endif
let g:plugin_dubs_mescaline = 1

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

function! SetStatusLineHighlights()
  " NOTE: To make the best use of the Powerline glyphs, alternate
  " foregrounds and backgrounds between adjacent colors, which has
  " the trick of making if look like we specially drew the status
  " line and didn't just use font and color magic.

  " The User1, User2, and User3 colors and shared between the active
  " and inactive windows and are used for the mode, git branch, and
  " cursor/line/column metrics. For the metrics, the colors are reversed
  " for the inactive windows, to help the user easily tell which window
  " is active
  hi User1 guifg=#dfff00 guibg=#005f00 gui=BOLD ctermfg=190 ctermbg=22 cterm=BOLD
  hi User2 guifg=#005f00 guibg=#dfff00 gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD
  hi User3 guifg=#005f00 guibg=#00dfff gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD

  " The User4 and User6 color are used to style the
  " file name and extra empty space in inactive windows.
  hi User4 guifg=#00dfff guibg=#001f00 ctermfg=241 ctermbg=234
  hi User6 guifg=#001f00 guibg=#005f00 ctermfg=241 ctermbg=234

  " The active window's file name and filler is styled with User5 and User7.
  hi User5 guifg=#00dfff guibg=#005f00 ctermfg=239 ctermbg=255
  hi User7 guifg=#005f00 guibg=#dfff00 ctermfg=239 ctermbg=255

  " 2017-12-06: The original code that I copied changed the highlight
  "   of the mode text depending on the mode, but that's really distracting,
  "   and seeing the mode name is not a big deal, as you can infer the mode
  "   by looking at the cursor. It was a cute trick, though.
endfunction

" FIXME: Make the g: functions use the plugin#syntax, or make name with project prefix.
function! SetStatusLineMode()
  let l:cmode = mode()
  let l:mode0 = s:omode
  let s:omode = l:cmode
  " NOTE: ==# forces case sensitive match, in case ignorecase is enabled.
  if l:mode0 ==# 'i' && l:cmode ==# 'n'
    " In Insert mode, if you arrow up or arrow down, the mode toggles
    "   to Normal mode and then back to Insert. (I have no idea way.)
    " As such, set a timer and wait to check if user really did switch modes.
    "   https://github.com/vim/vim/blob/master/runtime/doc/version8.txt#L66
    " Note that using s:/<SID> doesn't work here:
    "   call timer_start(125, 's:TickleStatusLineMode')     " no 'script context'
    "   call timer_start(125, <SID>.'TickleStatusLineMode') " 'unrecognized'
    " And note that with 'let', you don't use 'call', or hell breaks loose.
    if has("timers")
      call timer_start(125, 'TickleStatusLineMode')
      let l:timer_id = timer_start(125, 'TickleStatusLineMode')
    else
      " Not +timers.
      " So... there doesn't seem to be an issue without +timers.
      "   2018-01-29 21:24: Or perhaps it's the machine I'm on.
      call TickleStatusLineMode(0)
    end
    "echom 'Skipping Statusline to avoid flashing.'
    return s:ModeFriendlyString(l:mode0)
  else
    return s:ModeFriendlyString(l:cmode)
  endif
endfunction

function! TickleStatusLineMode(timer_id)
  " Set statusline= again, which'll trigger a refresh.
  call s:SetStatusLine(0)
endfunction

" NOTE: You canNOT use, e.g., "^V" or "\^V", to match control characters.
" For more on this list, see :help mode()
let s:vim_mode_lookup = {
  \ "n":      "NORMAL",
  \ "no":     "N·OPER",
  \ "v":      "VISUAL",
  \ "V":      "V·LINE",
  \ "\<C-V>": "V·BLCK",
  \ "s":      "SELECT",
  \ "S":      "S·LINE",
  \ "\<C-S>": "S·BLCK",
  \ "i":      "INSERT",
  \ "ic":     "I·COMP",
  \ "ix":     "I·C-X ",
  \ "R":      "RPLACE",
  \ "Rc":     "R·COMP",
  \ "Rv":     "V·RPLC",
  \ "Rx":     "R·C-X ",
  \ "c":      "COMMND",
  \ "cv":     "VIM·EX",
  \ "ce":     "NRM·EX",
  \ "r":      "PROMPT",
  \ "rm":     "-MORE-",
  \ "r?":     "CNFIRM",
  \ "!":      "!SHELL",
  \ "t":      "TRMNAL"
\ }

function! s:ModeFriendlyString(mode)
  return get(s:vim_mode_lookup, a:mode, "NOTFND")
endfunction

" MAYBE/2017-12-05: This function is called often.
"   Can we cache lookup of { winnr => active? }
"   and return immediately if no change needed?
function! s:FetchStatusLineMain(active_window)
  " Start with an empty statusline. We build a string, rather than
  " calling `set statusline+=`, so that we can build the statusline
  " differently based on the window width.
  let l:statline=''

  " NOTE: There are two ways to set color, e.g.,
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
    let l:statline .= "%2*"
    let l:statline .= "%2*%{SetStatusLineMode()}"
    let l:statline .= "%1*"
  else
    let l:statline .= "%1*"
  endif

  " Add the Git branch.
  let l:statline .= "%{strlen(fugitive#statusline())>0?'\\ \\ ':''}"
  " We can get the statusline, but I cannot figure out how to parse it.
  " E.g., this works:
  "   let l:statline .= "%{fugitive#statusline()}"
  " And this works if you run it:
  "   echo matchstr(fugitive#statusline(),'(\zs.*\ze)')
  " But adding the matchstr(...) to statusline, even trying different
  "   escaping for the glob, fails.
  " Fortunately, we can just make is a callback.
  let l:statline .= '%{FetchStatusLineGitBranch()}'

  let l:statline .= "\\ %3*\\ "

" FIXME/2017-12-06 00:24: Make s:bool's for each option, and
" then do this automatically based on if bool is enabled
" (and only add to statusline if bool enabled, 'natch).
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
  " Account for spaces are filename and for transition highlight.
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
  let l:statline .= "%{SyntasticStatuslineFlag()}"

  if a:active_window
    let l:statline .= "%5*"
  else
    let l:statline .= "%4*"
  endif
  let l:statline .= ""

  " Meh. I thought about honoring StatusLine, but since we use the
  " Powerline glyphs, we need to make sure adjacent highlights match.
  "if a:active_window
  "  let l:statline .= "%#StatusLine#"
  "else
  "  let l:statline .= "%#StatusLineNC#"
  "endif
  " %=      split left-alighed and right-aligned
  let l:statline .= "%="

  if a:active_window
    let l:statline .= "%7*"
  else
    let l:statline .= "%6*"
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

  let l:statline .= "%2*█"

  return l:statline
endfunction

function! s:SetStatusLine(nr)
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

function! FetchStatusLineGitBranch()
  return matchstr(fugitive#statusline(),'(\zs.*\ze)')
endfunction

let s:oldnr = -1
let s:omode = ''
function! s:on_window_changed(event_name)
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

function! s:MescalineStandUpStatusline()
  call SetStatusLineHighlights()

  augroup <SID>DubsMescaLine
    autocmd!

    autocmd CmdwinEnter * call <sid>on_window_changed('CmdwinEnter')
    autocmd WinEnter * call <sid>on_window_changed('WinEnter')
    autocmd BufWinEnter * call <sid>on_window_changed('BufWinEnter')
    autocmd FileType * call <sid>on_window_changed('FileType')
    autocmd BufUnload * call <sid>on_window_changed('BufUnload')
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
    "     ~/.vim/pack/landonb/start/dubs_appearance/after/plugin/dubs_appearance.vim
    autocmd VimResized * call <sid>on_window_changed('VimResized')

    " Reset the highlights after a :colorscheme change.
    autocmd ColorScheme * call SetStatusLineHighlights()
  augroup END

  let s:ready_to_roll = 1
endfunction

"call s:MescalineStandUpStatusline()
if exists("v:vim_did_enter") && v:vim_did_enter
  call <sid>MescalineStandUpStatusline()
else
  " Weird. I don't think the original author really wanted to hook VimEnter...
  "autocmd VimEnter * call <sid>on_window_changed('VimEnter')
  autocmd VimEnter * call <sid>MescalineStandUpStatusline()
endif

