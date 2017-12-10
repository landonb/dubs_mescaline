" File: dubs_appearance.vim
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Last Modified: 2017.12.10
" Project Page: https://github.com/landonb/dubs_appearance
" Summary: Basic Vim configuration (no functions; just settings and mappings)
" License: GPLv3
" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" ----------------------------------------------------------------------------
" Copyright © 2009, 2015-2017 Landon Bouma.
"
" This file is part of Dubsacks.
"
" Dubsacks is free software: you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation, either version
" 3 of the License, or (at your option) any later version.
"
" Dubsacks is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty
" of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
" the GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with Dubsacks. If not, see <http://www.gnu.org/licenses/>
" or write Free Software Foundation, Inc., 51 Franklin Street,
"                     Fifth Floor, Boston, MA 02110-1301, USA.
" ===================================================================

" FIXME/2017-12-06: Should this be part of a colorscheme?
"   At least it shouldn't be part of after/.
" I wonder if it's its own plugin... dubsacks_after_dark!!!!
"   no wait that'd be the colors/ name, instead of blacklist...
" or maybe the 2 get packaged together...

if exists("g:plugin_dubs_mescaline") || &cp
  finish
endif
let g:plugin_dubs_mescaline = 1

" Default statusline is empty string. Vim shows filepath, then [+] if dirty,
" followed by row,column and finally % through file.
"
" We make it more colorful; add the mode; and show Git branch.

" We ignore the build-in statusline highlights so that we can use
" Powerline glyphs and make a prettier status line. These will do
" nothing:
"   highlight StatusLine
"   highlight StatusLineNC
"   highlight StatusLineTerm
"   highlight StatusLineTermNC

" Only bother setting highlights if mode changed.
let g:last_mode = ''

function! SetStatusLineHighlights(mode)
  hi User1 guifg=#dfff00 guibg=#005f00 gui=BOLD ctermfg=190 ctermbg=22 cterm=BOLD
  hi User2 guifg=#005f00 guibg=#dfff00 gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD
  hi User3 guifg=#005f00 guibg=#00dfff gui=BOLD ctermfg=22 ctermbg=190 cterm=BOLD

  hi User4 guifg=#00dfff guibg=#001f00 ctermfg=241 ctermbg=234
  hi User6 guifg=#001f00 guibg=#005f00 ctermfg=241 ctermbg=234

  hi User5 guifg=#00dfff guibg=#005f00 ctermfg=239 ctermbg=255
  hi User7 guifg=#005f00 guibg=#dfff00 ctermfg=239 ctermbg=255

  " 2017-12-06: The original code that I copied changed the highlight
  "   of the mode text depending on the mode, but that's really distracting,
  "   and seeing the mode name is not a big deal, as you can infer the mode
  "   by looking at the cursor.
  " I should probably just delete this comment, but I still might change
  "   my mind, I suppose...
  "if a:mode ==# 'n'
  "  hi User1 guifg=#dfff00 ctermfg=190
  "  hi User2 guifg=#dfff00 ctermfg=190
  "elseif a:mode ==# "i"
  "  hi User1 guifg=#005fff guibg=#FFFFFF ctermfg=27 ctermbg=255
  "  hi User2 guifg=#FFFFFF ctermfg=255
  "elseif a:mode ==# "R"
  "  hi User1 guifg=#FFFFFF guibg=#df0000 ctermfg=255 ctermbg=160
  "  hi User2 guifg=#df0000 ctermfg=160
  "elseif a:mode ==? "v" || a:mode ==# ""
  "  hi User1 guifg=#4e4e4e guibg=#ffaf00 ctermfg=239 ctermbg=214
  "  hi User2 guifg=#ffaf00 ctermfg=214
  "endif
endfunction

" FIXME: Make the g: functions use the plugin#syntax, or make name with project prefix.
function! SetStatusLineMode()
  let l:mode = mode()
  if l:mode !=# g:last_mode
    " 2017-12-09: There's no need to change User* highlights
    " since we no longer change color depending on the mode.
    " At least not except the first time.
    if g:last_mode ==# ''
      call SetStatusLineHighlights(l:mode)
    endif
    let g:last_mode = l:mode
  endif

  let l:cmode = mode()
  let l:mode0 = s:omode
  let s:omode = l:cmode
  " NOTE: ==# forces case sensitive match, in case ignorecase is enabled.
  if l:mode0 ==# 'i' && l:cmode == 'n'
    " In Insert mode, if you arrow up or arrow down, the mode toggles
    " to Normal mode and then back to Insert. (Possible because... I
    " dunno.)
    " Set a timer to correct this issue if user really did switch modes.
    "   https://github.com/vim/vim/blob/master/runtime/doc/version8.txt#L66
    " 2017-12-05: Whatever: The docs say setting a variable to the return
    " value should work, but this raises "E121: Undefined variable: call".
    "   let s:mode_timer = call timer_start(500, 's:TickleStatusLineMode')
    " I also tried = exe "call ..." but then 'exe' is said undefined.
    " I also tried using redir:
    "   redir => s:mode_timer
    "   ...
    "   redir END
    " but the variable remains unset.
    " So I'm really not sure what's up with that.
    " Also, without the 'call', timer_start raises:
    "   E492: Not an editor command: timer_start...
    " Whatever; we don't need the timer_id, I suppose; if we
    " don't cancel the timer (stop_timer), it's not a big deal.
    " Oh, and I could not get <SID> to work: 's:TickleStatusLineMode'
    " complains of not having script context, and <SID> unrecognized:
    "   call timer_start(125, 's:TickleStatusLineMode')
    "   call timer_start(125, <SID>.'TickleStatusLineMode')
    call timer_start(125, 'TickleStatusLineMode')
    "echom 'Skipping Statusline to avoid flashing.'
    return s:ModeFriendlyString(l:mode0)
  else
    return s:ModeFriendlyString(l:mode)
  endif
endfunction

function! TickleStatusLineMode(timer_id)
  " Set statusline= again, which'll trigger a refresh.
  call s:SetStatusLineMain(0)
endfunction

" NOTE: You canNOT use, e.g., "^V" or "\^V", to match control characters.
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
  " See :help mode()
  "echom 'ModeFriendlyString: mode: ' . a:mode
  return get(s:vim_mode_lookup, a:mode, "NOTFND")
endfunction

" MAYBE/2017-12-05: This function is called a lot.
"   Can we cache lookup of { winnr => active? }
"   and return immediately if no change needed?
function! s:SetStatusLineMain(nr)
  " If not the active window, switch to it, so we can call setlocal.
  let l:orig_nr = winnr()
  if a:nr > 0
    try
      execute a:nr . 'wincmd w'
    catch
      " Happens when searching and results scroll by.
      " E788: Not allowed to edit another buffer now
      " FIXME/2017-12-05: Isn't there a way to detect this??
      echom "Skip winnr: " . winnr()
      return
    endtry
  endif

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
  "   e0a0 
  "   e0a1 
  "   e0a2 
  "   e0b0 
  "   e0b1 
  "   e0b2 
  "   e0b3 
  " Note that there's an aggregate font, Nerd Fonts, which seems awesome
  " -- it includes all of the Powerline glyphs, for one -- but there's a
  " 1-pixel space at the edge of each Powerline glyph. Bah.
  " Note also that the Powerline glyphs are not actual Unicode.
  "   http://www.fileformat.info/info/unicode/char/e0b0/index.htm
  " The 'Symbol, Other' category has good unicode.
  "   http://www.fileformat.info/info/unicode/category/So/list.htm

  if a:nr == 0
    "let l:statline .= "%1*"
    "let l:statline .= "%1*⛘"
    "let l:statline .= '%1*\ '
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
  let l:statline .= '%{SetStatusLineGitBranch()}'

  let l:statline .= "\\ %3*\\ "

" FIXME/2017-12-06 00:24: Make s:bool's for each option, and
" then do this automatically based on if bool is enabled
" (and only add to statusline if bool enabled, 'natch).
  let l:avail_width = winwidth(0)
  if a:nr == 0
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
  if a:nr > 0
    let l:avail_width -= 3
  else
    let l:avail_width -= 4
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
    "let l:statline .= "%f\\ %{&ro?'⭤':''}%{&mod?'+':''}%<"
    "let l:statline .= "%." . l:avail_width . "f\\ %{&ro?'⭤':''}%{&mod?'+':''}%<"
    "let l:statline .= "%." . l:avail_width . "f\\ %{&ro?'':''}%{&mod?'○':'●'}%<"
    "let l:statline .= "%." . l:avail_width . "f\\ %{&ro?'':''}%{&mod?'+':''}%<"
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

  if a:nr > 0
    let l:statline .= "%4*"
  else
    let l:statline .= "%5*"
  endif
  let l:statline .= ""

  " Meh. I thought about honoring StatusLine, but since we use the
  " Powerline glyphs, we need to make sure adjacent highlights match.
  "if a:nr > 0
  "  let l:statline .= "%#StatusLineNC#"
  "else
  "  let l:statline .= "%#StatusLine#"
  "endif
  " %=      split left-alighed and right-aligned
  let l:statline .= "%="

  if a:nr > 0
    let l:statline .= "%6*"
  else
    let l:statline .= "%7*"
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

  "echom 'l:statline: ' . l:statline

  " WEIRD: If only one window open, calling setlocal doesn't do the trick.
  if winnr('$') == 1
    exe 'set statusline=' . l:statline
  else
    exe 'setlocal statusline=' . l:statline
  end

  if a:nr > 0
    execute l:orig_nr . "wincmd w"
  endif
endfunction

function! SetStatusLineGitBranch()
  return matchstr(fugitive#statusline(),'(\zs.*\ze)')
endfunction

" "set statusline=......%{FileSize()}.....
" function FileSize()
"  let bytes = getfsize(expand("%:p"))
"  if bytes <= 0
"    return ""
"  endif
"  if bytes < 1024
"    return bytes
"  else
"    return (bytes / 1024) . "K"
"  endif
"endfunction

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
    call s:SetStatusLineMain(nr)
  endfor

  "echom 'On active window: ' . winnr() . ' / ' . winbufnr(0)
  call s:SetStatusLineMain(0)

  if l:mrunr != -1
    execute 'silent ' . l:mrunr . 'wincmd w'
    execute 'silent ' . l:curnr . 'wincmd w'
  endif

  "echom 'Done on_window_changed: curnr: ' . l:curnr . ' / mrunr: ' l:mrunr
endfunction

function! s:MescalineStandUpStatusline()
  " Weird: If you call SetStatusLineHighlights(0) on Vim boot, it gets
  " stuck in a loading look and you have to Ctrl-C to break free....
  call SetStatusLineHighlights(0)

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
    "   gvim -V9myVim.log ~/.vim/bundle_/dubs_appearance/after/plugin/dubs_appearance.vim
    autocmd VimResized * call <sid>on_window_changed('VimResized')

    " Reset the highlights after a :colorscheme change.
    autocmd ColorScheme * call SetStatusLineHighlights()
  augroup END

  let s:ready_to_roll = 1
endfunction

"call s:MescalineStandUpStatusline()
if v:vim_did_enter
  call <sid>MescalineStandUpStatusline()
else
  " Weird. I don't think the original author really wanted to hook VimEnter...
  "autocmd VimEnter * call <sid>on_window_changed('VimEnter')
  autocmd VimEnter * call <sid>MescalineStandUpStatusline()
endif

