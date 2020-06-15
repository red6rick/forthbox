{ ----------------------------------------------------------------------
Enhancements to the SwiftForth programming environment
10feb2020 rcvn

ZCOMPARE ( z z -- n )
   compare two zero-terminated strings, case insensitive, return zero
   if they are equal.
CREATE-WORD ( addr len -- )
   make a dictionary entry from the given string. Essentially, passing
   a string to the built-in CREATE function.
PEEK-WORD ( ch -- addr )
   parse the next word in the input stream delimited by CH into a
   temporary buffer without disturbing the input stream.
DEFER: ( <name> <body> -- )
   create a deferred definition with a default behavior. Equivalent
   to            "defer foo   : foo-defined ... ;  ' foo-defined is foo
   but shorter:  "defer: foo   ... ;
SINGLE ( <name> -- )   create a value datum which is equal to zero
EQU ( n <name> -- )   alias of constant

UMAXINT UMININT MAXINT MININT
   max and min of signed and unsigned 32 bit integers

CONTAINS ( haystack len needle len -- haystack len flag )
   simple string matcher. original string is returned. search for
   a needle in a haystack

CREATE-UPDATE ( -- )
   just like create, but forces the name into uppercase

The last lines set an environment variable so we can "require" files
from the sfx\lib directory
---------------------------------------------------------------------- }


{ ----------------------------------------------------------------------
ZCOMPARE is case-insensitive on zstrings
---------------------------------------------------------------------- }

: ZCOMPARE ( z z -- n )
   >r zcount r> zcount compare(nc) ;

{ ----------------------------------------------------------------------
create a dictionary entry from a string
---------------------------------------------------------------------- }

: CREATE-WORD ( addr len -- )
   GET-CURRENT (WID-CREATE)  LAST @ >CREATE ! ;

: PEEK-WORD ( ch -- addr )
   >IN @ >R  WORD COUNT >QPAD  R> >IN ! ;

{ ----------------------------------------------------------------------
defer: defines a defer with an initial behavior, like in swoop

alias the "single" method of classes so I can develop without a
class structure, then import into a class easily.

equates are easy constants, but if we make them values they are
potentially easier debug targets...
---------------------------------------------------------------------- }

[undefined] crash [if]
: CRASH ( -- )
   S" un-initialized defer" ERR ;
: (ADDR-OF) ( xt -- addr )
   STATE @ IF  POSTPONE LITERAL POSTPONE >BODY  EXIT  THEN   >BODY ;
[then]

[undefined] (begin) [if]
  : (BEGIN) ( -- addr)   HERE  +BAL ;
  : !BELOW ( n addr -- )
   DUP ORIGIN HERE 1+ WITHIN NOT -22 ?THROW
   4 - DUP @ 1018 1020 WITHIN NOT -22 ?THROW  ! ;
[then]

: DEFER: HEADER POSTPONE (DEFER) HERE >R ['] CRASH , :NONAME R> ! ;

: single 0 value ;

: equ   constant ;

{ ----------------------------------------------------------------------
simple stuff
---------------------------------------------------------------------- }

$ffffffff constant umaxint
$00000000 constant uminint

$7fffffff constant maxint
$80000000 constant minint

{ ----------------------------------------------------------------------
managing stand-alone applications
---------------------------------------------------------------------- }

: carp ( z -- )
   0 swap z" error" 0 ( MBOK) MessageBox drop ;

: die ( z -- )
   carp bye ;

: ?die ( ior z -- )
   swap if die else drop then ;

: ?carp ( ior z -- )
   swap if carp else drop then ;

{ ----------------------------------------------------------------------
Error handling? need improvement.
---------------------------------------------------------------------- }

: GRIPE ( z z -- )
   0 ROT ROT MB_OK MessageBox DROP ;

: ?GRIPE ( ior z -- )
   SWAP IF   Z" Gripe" GRIPE EXIT THEN DROP ;

: ?FATAL ( ior z -- )
   SWAP IF   Z" Fatal" GRIPE BYE  THEN DROP ;

{ ----------------------------------------------------------------------
set up custom colors, "skins", so that different targets look different
---------------------------------------------------------------------- }

: !FACE ( text background n -- )
   2 * CELLS COLOR-TABLE + 2! ;

: !BGCOLOR ( background -- )   >r
   R@ BLACK 0 !FACE  BLACK R@   1 !FACE
   R@ RED   2 !FACE  R@    BLUE 3 !FACE
   R> DROP  COLOR-TABLE SET-COLORS ;

: SKIN ( n -- )
   7 AND CASE
      0 OF  $C0C0C0  ENDOF
      1 OF  $C0C0FF  ENDOF
      2 OF  $C0D0C0  ENDOF
      3 OF  $C0FFFF  ENDOF
      4 OF  $FFC0C0  ENDOF
      5 OF  $FFC0FF  ENDOF
      6 OF  $FFFFC0  ENDOF
      7 OF  $FFFFFF  ENDOF
   ENDCASE  !BGCOLOR ;

{ ----------------------------------------------------------------------
Similar is the ability to read an entire file into memory for use
by an application. MAP-FILE provides this; SLURP provides a wrapper
around MAP-FILE
---------------------------------------------------------------------- }

: SLURP-FILE ( filename length -- data-addr length ior )
   R/O OPEN-FILE ?DUP IF  0 SWAP EXIT  THEN
   DUP >R  MAP-FILE  R> CLOSE-FILE DROP ;

: SLURP ( filename length -- data-addr length )
   SLURP-FILE ABORT" slurp failed" ;

: SPEW ( data-addr len filename len -- )
   R/W CREATE-FILE ABORT" spew failed" >R
   R@ WRITE-FILE DROP  R> CLOSE-FILE DROP ;

{ ----------------------------------------------------------------------
Cell-counted strings aren't necessary for most things, but if available
make simple strings that can be treated like their big brother "here-doc"
strings. The source code is simpler for similar treatments. They are
limited to 255 bytes due to the input buffer length.  We will always pad
their end with null.
---------------------------------------------------------------------- }

: X, ( addr len -- )
   DUP CELL+ R-ALLOC >R  R@ XPLACE
   R> @+ HERE  OVER CELL+ ALLOT  XPLACE  0 , ;

: ,X" ( -- )
   [CHAR] " WORD COUNT X, ;

{ ----------------------------------------------------------------------
Build a "here-doc" facility to compile multi-line text easily

X,LINES creates an x-string from a multi-line text input thru but not
including the specified terminator.

<<< parses a terminator, then compiles a multi-line string

XSTRING: FOO <<< END

This is a test\n of the text procesing
harness for a "here-doc" clone in swiftforth.
It should be useful for templates and such...
Does it perhaps need a substitution ability?
END

XSTRING: BAR ,X" THIS IS A SHORT STRING"
---------------------------------------------------------------------- }

: X,LINES ( term len -- )
   R-BUF  R@ PLACE  HERE 0 ,
   BEGIN
      REFILL  WHILE  /SOURCE ( a n)
      2DUP -TRAILING R@ COUNT COMPARE WHILE
      ( a n) -TRAILING  PAD PLACE
      PAD COUNT  DUP ALLOT  THIRD XAPPEND
      <EOL> COUNT  DUP ALLOT  THIRD  XAPPEND
   REPEAT 2DROP THEN DROP  BL WORD DROP  0 ,  R> DROP ;

: X,\LINES ( term len -- )
   R-BUF  R@ PLACE  HERE 0 ,
   BEGIN
      REFILL  WHILE  /SOURCE ( a n)
      2DUP -TRAILING R@ COUNT COMPARE WHILE
      ( a n) -TRAILING FORMAT COUNT PAD PLACE
      PAD COUNT  DUP ALLOT  THIRD XAPPEND
      <EOL> COUNT  DUP ALLOT  THIRD  XAPPEND
   REPEAT 2DROP THEN  DROP  BL WORD DROP
   0 ,  R> DROP ;

: <<<
   BL WORD COUNT X,\LINES ;

: XSTRING: ( -- )
   CREATE DOES> @+ ;

{ ----------------------------------------------------------------------
DRAIN a buffer which has a cell-sized count and a known size. The buffer
should be twice the size indicated. You should never XAPPEND or XPLACE
a single string longer than 1/2 the buffer size; you should always
drain the buffer
---------------------------------------------------------------------- }

: XDRAIN ( buffer size -- )
   OVER @ OVER < IF  2DROP EXIT  THEN
   OVER CELL+ DUP THIRD + SWAP THIRD CMOVE
   NEGATE SWAP +! ;


{ ----------------------------------------------------------------------
elide a pathname into the first n chars, an ellipsis, and the remaining
m characters

for instance, the pathname

s" c:\foo\bar\this\that\and\theother\file.txt" 5 14 elide

produces the null-terminated string

c:\fo ... other\file.txt

at pad, returning the address and length excluding the null.
if the string length is <= first+last+5, then place the string
unmodified at pad
---------------------------------------------------------------------- }

: elide ( addr len first last -- addr len )
   3dup + 5 + < if  2drop pad zplace   else
      r-buf  2swap r@ place  swap
      r@ count rot min pad zplace
      s"  ... " pad zappend
      r> count rot over swap - /string pad zappend
   then
   pad zcount ;

{ ----------------------------------------------------------------------
a simple mkdir command, which will recursively create directories
---------------------------------------------------------------------- }

: isdir ( addr len -- flag )
   r-buf  r@ zplace r> is-dir ;

: makedir ( addr len -- flag )
   r-buf  r@ zplace  r> 0 CreateDirectory 0<> ;

: (mkdir) ( addr len -- )
   2dup isdir if  2drop exit  then
   2dup -name recurse makedir 0= throw ;

: mkdir ( addr len -- )
   2dup 2>r
   ['] (mkdir) catch if
      2drop  s" pathname: " pad zplace
      2r@ pad zappend
      0 pad z" mkdir error" MB_OK MessageBox drop
   then 2r> 2drop ;

{ ----------------------------------------------------------------------
more better stack picture
---------------------------------------------------------------------- }

: h.s.r
   cr 0 3 do i pick 8 h.0 space -1 +loop
   ." . "
   r> r> r> r> r>
   0 3 do  i pick 8 h.0 space  -1 +loop
   >r >r >r >r >r ;

: .s.r
   cr 0 3 do i pick 8 .r space -1 +loop
   ." . "
   r> r> r> r> r>
   0 3 do  i pick 8 .r space  -1 +loop
   >r >r >r >r >r ;

\ ----------------------------------------------------------------------

: contains ( haystack len needle len -- haystack len flag )
   2over 2swap search(nc) nip nip ;

: create-upcase ( -- )
   >in @ >r  parse-word upcase  r> >in !  create ;

\ ----------------------------------------------------------------------

Function: SetEnvironmentVariable ( zvariable zvalue -- bool )

:onsysload ( -- )
   z" sflocal_user"
   z" %SwiftForth\sfx\lib" SetEnvironmentVariable drop ;

\ ----------------------------------------------------------------------

FUNCTION: AllowSetForegroundWindow      ( process -- bool )

{ ----------------------------------------------------------------------
a set of patches the base swiftforth distribution
---------------------------------------------------------------------- }

PACKAGE STRING-TOOLS

[+SWITCH ADDCH
   CHAR j RUN:  [CTRL] J PUTCH ;    \ line feed inserted for "\j"
SWITCH]

END-PACKAGE

\ ----------------------------------------------------------------------
\ xroot is a better +root behavior;

: exepath ( -- addr len )   this-exe-name -name ;
: binpath ( -- addr len )   exepath  -name ;

: source-exists? ( filename len root len -- addr len true | false )
   pocket place  pocket append
   pocket count file-exists if  pocket count 1 exit  then
   s" .f" pocket append
   pocket count 2dup file-exists ;

: +xroot ( addr n -- addr n )
   over c@ [char] % <> ?exit   1 /string  \ doesn't want rootpath
   2dup rootpath count source-exists? if 2nip exit then 2drop
   '\' scan  2dup binpath source-exists? if  2nip exit  then  2drop
   exepath source-exists? drop ;

\ ----------------------------------------------------------------------
\ better restart

-? : RESTART ( -- )
   POPPATH-ALL
   -1 AllowSetForegroundWindow DROP
   GetCommandLine >PROCESS  drop
   BYE ;

\ ----------------------------------------------------------------------


PACKAGE TTY-WORDS

DEFER PUTC-SPECIAL   ' PUTC IS PUTC-SPECIAL

0 VALUE PASS-KEYS

-? : PUTCHAR ( char -- )   CASE
   13 OF  PUTCR  ENDOF
   10 OF  PUTLF  ENDOF
      8 OF  PUTBS  ENDOF
    $10027 OF  1 +X  ENDOF
    $10025 OF -1 +X  ENDOF
    $10026 OF -1 +Y  ENDOF
    $10028 OF  1 +Y  ENDOF
    $10024 OF  X NEGATE +X  ENDOF
    $10023 OF  0 Y XY> COLS -TRAILING NIP X - +X ENDOF
    $10021 OF  HIGH @ NEGATE +Y ENDOF
    $10022 OF  HIGH @        +Y ENDOF
      DUP PUTC-SPECIAL
   ENDCASE ;

-? : WM-KEYDOWN ( -- res )
   ?RAW IF  IN-SCROLLBACK OFF  KDOWN  0 EXIT  THEN
   IN-SCROLLBACK @ IF SCROLLING-VKEYS ELSE NORMAL-VKEYS THEN 0 ;

: ALL-KEYS ( -- res )   cdown 0 ;
: PC-KEYS  ( -- res )   WM-CHAR ;

[+SWITCH TTY-MESSAGES
   TTY_EMIT       RUN: -CARET  WPARAM PUTCHAR  IS-DIRTY  0  ;
   WM_KEYDOWN     RUN: WM-KEYDOWN  ;
   WM_CHAR        RUN: PASS-KEYS IF ALL-KEYS ELSE PC-KEYS THEN  ;
SWITCH]

end-package

\ ----------------------------------------------------------------------

command-history +order
: >history save-string ;
: show-history ( -- )   history toend ;
: history-visible? ( -- flag )   historyorg @ ;
command-history -order

{ ----------------------------------------------------------------------
This, in conjuction with the restart via >process and
AllowSetForegroundWindow is the correct (per msft) way to set focus
---------------------------------------------------------------------- }

: sf-on-top ( hwnd -- )
   10 0 do
      dup SW_SHOW ShowWindow drop
      dup SetForegroundWindow drop
      GetForegroundWindow over = if
         drop unloop exit
      then
      500 sleep drop
   loop drop ;

{ ----------------------------------------------------------------------
redefine the console window closing behavior to save our local info
---------------------------------------------------------------------- }

CONSOLE-WINDOW +ORDER

[+SWITCH SF-MESSAGES
   WM_CREATE RUN:   CREATES  HWND sf-on-top ;
SWITCH]

CONSOLE-WINDOW -ORDER

{ ----------------------------------------------------------------------
local control of startup
---------------------------------------------------------------------- }

: EDIT-RESTART ( -- )
   EDIT-START  250 MS   restart ;

: BETTER-BAILOUT? ( -- )
   CR ." Exit? (Yes/No/Edit/Restart) "
   BEGIN
      KEY DUP EMIT  $20 OR  CASE
         [CHAR] y OF   -1 EXITSTATUS !  BYE  ENDOF
         [CHAR] e OF  EDIT-START EXIT        ENDOF
         [CHAR] g OF  EDIT-START EXIT        ENDOF
         [CHAR] r OF  EDIT-RESTART           ENDOF
         [CHAR] n OF  EXIT                   ENDOF
         [CHAR] - OF  EXIT                   ENDOF  \ also return
         [CHAR] ; OF  EDIT-RESTART           ENDOF  \ also escape
      ENDCASE
   AGAIN ;

' BETTER-BAILOUT? IS BAILOUT?

{ ----------------------------------------------------------------------
A better version of -ext which returns the entire string if no explicit
ext (defined by a dot) exists in the string.
---------------------------------------------------------------------- }

-? : -EXT ( addr len -- addr len )
   2DUP -EXT DUP IF 2NIP EXIT THEN  2DROP ;

{ ----------------------------------------------------------------------
It is useful to be able to use quotes around tokens.
If the string to be parsed begins with a quote, parse a quoted
string. Otherwise, parse a space-delimited string.

SwiftForth has a definition of '''TOKEN''' already; this can
replace it with no issues.
---------------------------------------------------------------------- }

: QUOTED ( -- addr len )
   /SOURCE OVER >R
   [CHAR] " SCAN  [CHAR] " SKIP DROP
   R> - >IN +! [CHAR] " PARSE ;

-? : TOKEN ( -- addr len )
   >IN @  BL WORD 1+ C@  SWAP >IN !
   [CHAR] " = IF  QUOTED  ELSE  BL WORD COUNT  THEN ;

{ ======================================================================
  For file output purposes, we have a header with a default delimiter
  of "blank" which may need to change to TAB or COMMA. So, this is
  a generic function to do character substitution in a string
====================================================================== }

\ replace CHOLD with CHNEW in place in the string
: gsub-char ( addr len chold chnew -- )
   2swap bounds ?do
      i c@ third = if  dup i c!  then
   loop 2drop ;

\ ======================================================================

: upcase-header ( -- )
  bl word count  2dup upcase  get-current wid-header ;

\ print the name of a function based on its xt
: xt.name ( xt -- )   >code c>name count type space ;

\ print the name of a function based on it body address
: body.name ( body -- )   body> >name count type space ;

\ ======================================================================

icode k ( -- n )
   push(ebx)                        \ save tos
   16 [esp] ebx mov                  \ get loop counter
   20 [esp] ebx add                 \ and subtract from loop terminator
   ret   end-code


\ ======================================================================

ICODE fifth ( x0 x1 x2 x3 x4 -- x0 x1 x2 x3 x4 x0 )
   PUSH(EBX)                        \ push x4 into memory
   16 [EBP] EBX MOV                 \ replace tos with x1
   RET   END-CODE

{ ----------------------------------------------------------------------
2 point vector addition
---------------------------------------------------------------------- }

icode v+ ( a b c d -- a+c b+d )
   4 [ebp] ebx add
   0 [ebp] eax mov
   8 # ebp add
   eax 0 [ebp] add
   ret end-code

\ ======================================================================

ICODE R@+ ( -- x )   ( R: a -- a+4 )
   PUSH(EBX)                        \ save tos on stack
   0 [ESP] EBX MOV                  \ read top of return stack to tos
   0 [EBX] EBX MOV
   4 # 0 [esp] add
   RET   END-CODE

ICODE 2@+ ( a-addr -- a+8 x1 x2 )
   8 # EBP SUB
   EBX 4 [EBP] MOV
   4 [EBX] EAX MOV
   0 [EBX] EBX MOV                  \ read x2 from addr+0, replacing tos
   EAX 0 [EBP] MOV
   8 # 4 [EBP] ADD                  \ increment address
   RET   END-CODE

\ ======================================================================
\ another variation of .(

: .[   [char] ] echo-until ; immediate

{ ----------------------------------------------------------------------
   EOL-SCANNER2 ( addr len -- got skip )
   Take a line of text, look for an eol sequence. Return the length
   of the line and how far ahead to skip in the line. Eol sequences
   are: <cr> <lf> and <cr><lf>. If no eol sequence is found, return
   the total length for both got and skip.

   Implemented in code to scan for both cr and lf simultaneously; the
   original scanned for a cr before evaluating a potential lf. Our
   TLG files are all lf terminated; parsing them with the original
   EOL-SCANNER took 3 minutes; this one takes 55 usec. :-)

   NO-COMMAS ( addr len -- addr len )
   Replace each comma in the string with a space. In place, modifies
   the original string.

   NEXT-WORD ( haystack len -- HAYSTACK LEN addr len )
   Parse the next blank delimited word from the haystack and return
   an updated haystack and the word found.

   NEXT-LINE ( haystack len -- HAYSTACK LEN line len )
   Parse a line from the haystack; update the address and length
   of the remaining haystack.
---------------------------------------------------------------------- }

code eol-scanner2 ( addr n -- len #adv )
   ebx ebx test  0= if                \ no string
      0 # 0 [ebp] mov  ret            \ bail early
   then                               \
   0 [ebp] edx mov  ebx ecx mov       \ edi=addr ecx=n
   13 # al mov  10 # ah mov           \ delimiters in al and ah
   begin                              \
      0 [edx] bl mov                  \ get char and increment

      bl al cmp 0= if                 \ found cr
         1 # ecx cmp 0<> if           \ if not at end
            1 # ebx mov               \ for cr
            1 [edx] ah cmp  0= if     \ if next is lf
               ebx inc                \ len+2 for crlf
            then                      \
         then                         \
         0 [ebp] edx sub              \ len of string
         edx 0 [ebp] mov              \ for return, actual len
         edx ebx add                  \ len+1 for just cr

         ret
      then

      bl ah cmp 0= if                 \ found lf
         0 [ebp] edx sub              \ len of string
         edx 0 [ebp] mov              \ for return, actual len
         1 [edx] ebx lea              \ len+1 for just lf
         ret
      then
      edx inc
   loop                               \
   0 [ebp] edx sub                    \ len of string
   edx 0 [ebp] mov                    \ for return,
   edx ebx mov                        \
   ret end-code                       \

\ ----------------------------------------------------------------------

: get-next-word ( haystack len -- HAYSTACK LEN word len )
   bl skip  2dup  bl scan  2swap third - 0 max ;

: get-next-line ( haystack len -- HAYSTACK LEN line len )
   2dup eol-scanner2    \ addr len got #advance
   fourth rot 2>r /string 2r>  ;

: this-line ( haystack len -- line len )   get-next-line 2nip ;

: trim ( addr len -- ADDR LEN )   -trailing  bl skip ;


