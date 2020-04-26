{ ----------------------------------------------------------------------
Manage data going to and coming from the windows system clipboard.
10feb2020 rcvn

CopyFileToClipboard ( addr len -- )
   Given a filename, copy its contents onto the clipboard. Not a
   forth specific thing, but very useful. THROW on failure.
CLIP-FILE ( addr len -- ior )
   A wrapper on CopyFileToClipboard. Catches and manages THROW conditions.
CLIP-TEXT ( addr len -- ior )
   Copy a string from memory to the clipboard.

CopyClipboardToFile ( addr len -- )
   Copy the data on the clipboard to the named file.

>CLIP ( -- )   in use: >CLIP HERE 100 DUMP
   Preserve the current console context, initialize the output-to-buffer
   personality, then execute the rest of the line of commands in that
   context. Any output from this line of commands will be coped to the
   clipboard, and the original console context restored.
---------------------------------------------------------------------- }

0 value file-to-clip
0 value length
0 value clipmem
0 value dest

: CopyFileToClipboard ( addr len -- )
   r/w open-file throw to file-to-clip
   file-to-clip file-size throw drop to length
   GMEM_MOVEABLE length cell+ GlobalAlloc to clipmem
   clipmem 0= throw
   clipmem GlobalLock to dest
   0 OpenClipboard 0= throw
   EmptyClipboard 0= throw
   dest length file-to-clip read-file throw drop
   file-to-clip close-file drop
   0 dest length + !
   clipmem GlobalUnlock throw
   CF_TEXT clipmem SetClipboardData 0= throw
   CloseClipboard 0= throw ;

: CLIP-FILE ( addr len -- ior )
   ['] CopyFileToClipboard CATCH DUP IF
      NIP NIP
      FILE-TO-CLIP CLOSE-FILE DROP
      CLIPMEM GlobalUnlock DROP
      CLIPMEM GlobalFree DROP
   THEN  ;

: CLIP-TEXT ( addr len -- ior )
   0 0 locals| h dest len src |
   HWND OpenClipboard DROP
   EmptyClipboard DROP
   GMEM_MOVEABLE len CELL+ GlobalAlloc TO H  H GlobalLock TO dest
   src dest len CMOVE  0 dest len + !
   h GlobalUnlock drop
   CF_TEXT h SetClipboardData  0=
   CloseClipboard DROP ;

{ ----------------------------------------------------------------------
Copy the clipboard to a file
---------------------------------------------------------------------- }

: CopyClipboardToFile ( addr len -- )
   0 OpenClipboard 0= z" failed to open clipboard" ?throw
   CF_TEXT GetClipboardData dup 0= z" no CF_TEXT data on clipboard" ?throw
   GlobalLock dup >r  0= z" GlobalLock failed in CopyClipboardToFile" ?throw
   ( fname len) R/W create-file if   drop -1  else
      ( handle) r@ zcount third write-file drop  ( handle) close-file
   then ( ior)
   r> GlobalUnlock drop   CloseClipboard drop
   ( ior) z" WRITE-FILE failed in CopyClipboardToFile" ?throw ;



{ ----------------------------------------------------------------------
Being able to redirect normal program output to a file is important to
me. The built-in >FILE function works, but pops a file-create dialog for
the output file. I want a function that works for all normal forth
output and accepts the filename from the command line.

This personality redirects the output of the rest of the executable line
to the specified file, like piping output in unix. All "input" functions
return null. All non-text-output functions do nothing but discard
parameters.  The syntax is

|> filename.ext executable line of forth code

The filename must have an explicit 3 char extension with a dot.  This
helps ensure that a word intended to be executed isn't interpreted as a
filename.

This code depends on knowledge of the way P-EVAL calls (P-EVAL) and
INVOKE.
---------------------------------------------------------------------- }

PACKAGE PIPE-OUTPUT

0 value sx       \ screen x and y
0 value sy

: |get-xy ( -- x y )   sx sx ;
: |get-size ( -- x y )   80 60 ;   \ old-fashioned sheet of paper

: |REVOKE ( -- )
   PHANDLE CLOSE-FILE DROP  0 PERSONALITY-HANDLE ! ;

: |INVOKE ( addr len -- addr len )
   2DUP 0 ARGV  DUP >R
   2DUP 4 - 0 MAX + C@ [CHAR] . <> THROW
   R/W CREATE-FILE THROW PERSONALITY-HANDLE !
   R> /STRING  0 to sx  0 to sy ;

: |TYPE ( addr len -- )
   TUCK  PHANDLE WRITE-FILE DROP  +TO SX ;

: |EMIT ( char -- )
   SP@ 1 |TYPE DROP ;

: |CR ( -- )
   <EOL> COUNT |TYPE  0 TO SX  1 +TO SY ;

: NULL 0 ;

: |PAGE ( -- )   |CR  0 TO SX 0 TO SY  ;

PUBLIC

CREATE PIPEOUT
        16 ,            \ datasize
        19 ,            \ maxvector
         0 ,            \ handle
         0 ,            \ PREVIOUS
   ' |INVOKE ,          \ INVOKE    ( -- )
   ' |REVOKE ,          \ REVOKE    ( -- )
   ' NOOP ,             \ /INPUT    ( -- )
   ' |EMIT ,            \ EMIT      ( char -- )
   ' |TYPE ,            \ TYPE      ( addr len -- )
   ' |TYPE ,            \ ?TYPE     ( addr len -- )
   ' |CR ,              \ CR        ( -- )

   ' |PAGE ,            \ PAGE      ( -- )
   ' DROP ,             \ ATTRIBUTE ( n -- )
   ' NULL ,             \ KEY       ( -- char )
   ' NULL ,             \ KEY?      ( -- flag )
   ' NULL ,             \ EKEY      ( -- echar )
   ' NULL ,             \ EKEY?     ( -- flag )
   ' NULL ,             \ AKEY      ( -- char )
   ' 2DROP ,            \ PUSHTEXT  ( addr len -- )
   ' 2DROP ,            \ AT-XY     ( x y -- )
   ' |get-xy ,          \ GET-XY    ( -- x y )
   ' |get-size ,        \ GET-SIZE  ( -- x y )
   ' DROP ,             \ ACCEPT    ( addr u1 -- u2 )

-? : >FILE ( -- )    \ >FILE filename.ext [string of forth to evaluate]
   0 PARSE  PIPEOUT P-EVAL ;

{ ----------------------------------------------------------------------
Another value-added feature is to be able to write the output to the
windows clipboard. The easy way is to write it to a file, then write
the file to the clipboard.
---------------------------------------------------------------------- }

\ synthesize the command line with a default filename, pipe the
\ output to the file, then copy the file to the clipboard.

: >CLIP ( -- )   R-BUF
   S" clip_temp.txt " R@ PLACE  0 PARSE  R@ APPEND
   R> COUNT PIPEOUT P-EVAL
   S" clip_temp.txt" CLIP-FILE ABORT" |>clip failed" ;

END-PACKAGE

