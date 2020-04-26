\ include line-noise.f

{ ----------------------------------------------------------------------
A new command-line editor

The entire file is compiled as private in the LINE-NOISE package.

General principle: printable characters insert or overstrike in the
buffer. All others are converted to a string which is searched for in
the wordlist LINE-NOISE and executed if found. All estrokes depend on

   a) using a common TBUF for editing,
   b) knowing max length and current column, and
   c) being able to use the cursor positioning facilities at will.
---------------------------------------------------------------------- }

package line-noise
private

command-history +order
: >history save-string ;

{ ----------------------------------------------------------------------
The history buffer is managed as a pool of unpacked text. The array is a
moving window on the user typed lines; a new line goes in at the end,
the first line is lost. This array is allocated at :ONENVLOAD.
---------------------------------------------------------------------- }

 128 equ c/l                      \ max chars per line
2048 equ #max-lines               \ power of two, please!

single cmdlines                   \ address of line history buffer

#max-lines c/l * equ |cmdlines|   \ how big the history buffer is

: /cmdlines ( -- )
   cmdlines free drop  0 to cmdlines
   |cmdlines| dup  allocate throw  dup to cmdlines  swap blank ;

: 'line ( n -- addr )
   #max-lines 1- and  c/l * cmdlines + ;

: 'text ( n -- addr len )   'line c/l -trailing ;

: 'end ( -- addr )    #max-lines 1- 'line ;
: 'penult ( -- addr )   #max-lines 2-  'line ;

: keep-line ( addr len -- )
   -trailing ?dup if
      2dup >history
      1 'line 0 'line |cmdlines| c/l - cmove
      'end c/l blank  'end swap cmove
   else drop then ;

: fill-history-window ( -- )
   history-visible?  dup >r  if  hide-history  then
   #max-lines 0 do
      i 'text  dup if  >history else  2drop  then
   loop
   r> if show-history then ;

: cmdlines-filename ( -- addr len )
   s" userprofile" find-env  -rot pad place  if
      s" \sfx\cmdlines.txt"  pad append
      pad count -name  makedir drop
   then  pad count ;

: save-cmd-lines ( -- )
   cmdlines |cmdlines| cmdlines-filename
   ['] spew catch if 4drop then ;

: restore-cmd-lines ( -- )
   cmdlines-filename slurp-file if  2drop exit  then
   third >r  cmdlines swap |cmdlines| min cmove  r> free drop
   fill-history-window ;

:onenvload   /cmdlines restore-cmd-lines ;
:onenvexit   save-cmd-lines ;

/cmdlines restore-cmd-lines

{ ----------------------------------------------------------------------
expect/accept, adapted from F32 !!! 1991 !!!!

<%fn%> formats a 5-digit hex value preceeded by a tilde at here

~stroke finds and executes the echar or discards it silently.  all
words execute with "max col" on the stack. see twin: below
---------------------------------------------------------------------- }

: <%fn%> ( echar -- addr len )
   base @ >r  hex  0
   here 1+ 4 bounds swap do  (#) i c!  -1 +loop  2drop
   [char] ~ here c!   here 6  r> base ! ;

: ~stroke ( max col echar -- max col )
   <%fn%> 2dup (find) if  nip nip execute exit  then
        line-noise search-wordlist if execute then ;

\ ----------------------------------------------------------------------

variable ins   1 ins !
single patline

c/l 2+ buffer: tbuf

: tb@ ( col -- char )   tbuf + c@ ;

: #lag ( max col -- 'col lag )   dup tbuf + -rot - 1- ;
: #eot ( max col -- 'col n )   #lag -trailing ;
: #eol ( max col -- max eol col )   2dup  #eot nip  over + swap ;

: slide> ( max col -- )   #lag over 1+ swap cmove> ;
: <slide ( max col -- )   #lag over 1+ -rot cmove ;

: .eol ( max col -- )   get-xy  2swap  #lag type  at-xy ;

: retype ( max col addr len -- max col )
   bounds ?do i c@ emit 1+ loop ;

: istroke ( max col char -- max COL )
   >r  2dup slide>  r@ over tbuf + c!  2dup .eol  r> emit  1+ ;

: ostroke ( max col char -- max COL )
   2dup emit  tbuf + c!  1+ ;

: stroke ( max col char -- max COL )
   ins @ if istroke else ostroke then ;

: strokes ( max col addr len -- max col )
   bounds do i c@ stroke loop ;

: estroke ( max col ekey -- max col )
   dup 32 127 within  if  stroke  else ~stroke  then ;

: xacceptor ( max -- MAX )
   0 begin ( ... max col)
      2dup swap <  while  ekey estroke
   repeat drop ;

: xaccept ( a # -- # )
   c/l min  tbuf c/l 2+ blank
   xacceptor ( a #) tuck tbuf -rot cmove space ;

: ins/ovr ( mode -- )
   dup ins !
   dup phandle TtyCaretMode drop
   dup if s" ins" else s" ovr" then 5 sf-status pane-type
   drop ;

config: ins ( -- addr len )   ins cell ;

:onenvload ( -- )   ins @ ins/ovr ;

\ ----------------------------------------------------------------------
\ all twin definitions have stack ( max col -- max col ) so none state it...

: twin:
   header postpone (else) (begin)
   current @ >r  line-noise current !
   : HERE OVER - SWAP !BELOW
   r> current ! ;

twin: ~left         ~10025    dup if  8 emit  1-  then ;

twin: ~insert       ~1002d    ins @ 0= ins/ovr ;
twin: ~right        ~10027    2dup > if  dup tb@ emit 1+  then ;
twin: ~del          ~1002e    2dup <slide  2dup .eol ;

: rubout ( max col -- max col )
   ~left ins @ if  ~del  else  bl ostroke ~left   then ;

twin: ~backspace    ~00008    dup if  rubout then ;
twin: ~home         ~10024    begin  ~left  dup 0= until ;
twin: ~end          ~10023    ~home 2dup #eot retype ;
twin: ~ctrl-k       ~0000b    2dup #lag blank  2dup .eol ;
twin: ~escape       ~0001b    ~home  ~ctrl-k  ;
twin: ~ctrl-a       ~00001    ~home ;
twin: ~ctrl-e       ~00005    ~end ;
twin: ~enter        ~0000d    ~end min dup  tbuf over keep-line ;
twin: ~ctrl-d       ~00004    ~del ;
twin: ~f9           ~10078    ~escape s" include debug.f" strokes ~enter ;
twin: ~f8           ~10077    ~escape s" include build.f" strokes ~enter ;
twin: ~ctrl-v       ~00016    [ console-window +order ] paste-text [previous] ;
twin: ~ctrl-c       ~00003    [ console-window +order ] copy-text  [previous] ;
twin: ~alt-pgup     ~90021    hwnd WM_COMMAND MI_HISTORY 0 SendMessage drop
                              hwnd SetFocus drop ;

: ~00015 ( alias on ctrl-u )  ~escape ;

: tbscan ( max col -- max col )
   begin  2dup > while
      dup tb@ bl <> while  ~right
   repeat then  ;

: tbskip ( max col -- max col )
   begin  2dup > while
      dup tb@ bl = while  ~right
   repeat then ;

: -tbscan ( max col -- max col )
   begin  dup while
      dup tb@ bl <> while  ~left
   repeat then ;

: -tbskip ( max col -- max col )
   begin  dup while
      dup tb@ bl = while  ~left
   repeat then ;

twin: ~ctrl-right   ~30027   #eol  tbscan tbskip  nip ;
twin: ~ctrl-left    ~30025   ~left -tbskip -tbscan dup if tbskip then ;

twin: ~ctrl-backspace ~0007f   dup -exit
   tuck   ~ctrl-left  rot over - 0 max 0 ?do ~del loop ;

twin: ~ctrl-del ~3002e
   begin  2dup #eot while c@ bl =  while  ~del  repeat else drop then
   begin  2dup #eot while c@ bl <> while  ~del  repeat else drop then ;

\ ----------------------------------------------------------------------

single patdir   ( -1 or 1 )

c/l 1+ buffer: pattern  pattern c/l erase

: +patline ( n -- n )
   patline +  0 max  #max-lines 1- min  dup to patline ;

: recall-line ( max col n -- max col )
   >r  ~escape drop  r>      \ max n
   'text tbuf swap c/l min cmove
   0 ~end ;

: matches? ( addr len -- flag )
   pattern count search(nc) nip nip ;

: refill-match ( max col dir -- max col )
   locals| dir |
   #max-lines 0 do
      dir +patline 'text matches? if
         patline recall-line  unloop exit
      then
   loop ;

: refill-sequential ( max col dir -- max col )
   +patline recall-line ;

: refill-tbuf ( max col dir -- max col )
   pattern c@ if  refill-match  else  refill-sequential  then ;

: grab-tbuf ( -- )
   tbuf c/l -trailing  pattern place ;

\ this needs to know which keystrokes to use... breaks the pattern

: recall-browser ( max col -- max col )
   grab-tbuf  #max-lines to patline
   -1 begin
      refill-tbuf
      ekey case
         $10026 of ( up)   -1 endof
         $00009 of ( up)   -1 endof
         $10028 of ( dn)    1 endof
         estroke exit
      endcase
   again ;

twin: ~up   ~10026 ( max col -- max col )   recall-browser ;
twin: ~tab  ~00009 ( max col -- max col )   recall-browser ;

{ ----------------------------------------------------------------------
An initial keystroke of PGUP will invoke the window scroll browser.
This mode is persistent until a non-scrolling key is detected.
---------------------------------------------------------------------- }

: scroller ( ekey -- flag )
   dup  $10021 =     \ pgup
   over $10022 = or  \ pgdn
   over $10026 = or  \ up
   over $10028 = or  \ down
   nip ;

: scroll-browser ( max col ekey -- max col )
   get-xy 2>r  begin   emit
      ekey dup scroller not
   until
   2r> at-xy  estroke ;

twin: ~pgup         ~10021    $10021 scroll-browser ;

command-history -order

\ ======================================================================
\ user history interface

: .lines ( -- )
   #max-lines 0 do
      i 'text  dup if  cr type  else  2drop  then
   loop ;

: .lines-matching ( addr len -- )
   pad zplace   #max-lines 0 do
      i 'text here zplace
      pad here matchrx if
         cr i 4 .r ." | " i 'text type
      then
   loop ;
   
public

-? : history ( -- )   bl word count
   ?dup if  .lines-matching  else  drop .lines  then ;

-? : .history ( n -- )
   cr get-size nip 3 / >r
   0 max  r@ -  r> 2* bounds ?do
         cr i 4 .r ." | " i 'text type
   loop ;

: cls page ;
: clear page ;

: @line ( n -- )   1- 'text pushtext ;

end-package

{ ----------------------------------------------------------------------
Here we make the global accept vector use the new vector
---------------------------------------------------------------------- }

line-noise +order  acceptor +order  tty-words +order
: /line-noise   ['] xaccept is (accept)  1 to pass-keys ;
: line-noise/   ['] e-accept is (accept) 0 to pass-keys ;
previous previous previous

/line-noise

