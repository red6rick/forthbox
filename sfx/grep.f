
icode lower ( char -- char )
   char A # bl cmp                  \ check char against "a"
   u>= if                           \ if below, do nothing
      char Z # bl cmp               \ check against "z"
      u<= if                        \ if above, do nothing
         32 # bl xor                \ was between, mask with $20 to uppercase
      then                          \
   then                             \
   ret end-code

code dncase ( a # -- )
   ebx ecx mov                      \ count to ecx
   0 [ebp] edx mov                  \ address in edx
   ecx ecx or  0<> if
      begin                         \
         0 [edx] al mov             \ read a char
         char A # al cmp            \ check char against "a"
         u>= if                     \ if below, do nothing
            char Z # al cmp         \ check against "z"
            u<= if                  \ if above, do nothing
               32 # al xor          \ was between, mask with $20 to uppercase
            then                    \
         then                       \
         al 0 [edx] mov             \ and write it back
         edx inc                    \ point to next address
      loop                          \
   then                             \
   4 [ebp] ebx mov                  \ refresh tos
   8 # ebp add                      \ clean up stack
   ret end-code

{ ----------------------------------------------------------------------
build a grep function for output
z" blah" grep words
use p-eval   addr len personality P-EVAL
---------------------------------------------------------------------- }

package grepping

 256 buffer: grep-string
 256 buffer: grep-source
1024 buffer: grep-pipe          \ "typed" data

: set-grep-string ( addr len -- )
   dup 254 > abort" grep string too long"  grep-string zplace
   grep-string zcount dncase ;

: set-grep-source ( addr len -- )
   dup 254 > abort" grep source too long"  grep-source zplace ;

: /grepper ( -- )
   0 grep-pipe ! ;

: grep-cr ( -- )
   grep-pipe @+ over + 0 swap c!  grep-string swap matchrx if
      'personality @ >r  previous-personality @ 'personality !
      grep-pipe @+ type cr
      r> 'personality !
   then 0 grep-pipe ! ;

: grep-emit ( char -- )
   grep-pipe @ 500 > if
      dup bl = if  grep-cr  then
   then
   grep-pipe @ 1000 > abort" grep buffer overflow"
   lower grep-pipe @+ + c!
   1 grep-pipe +! ;

: grep-type ( addr len -- )
   bounds do i c@ grep-emit loop
   grep-pipe @ 64 > if grep-cr then ;


: null 0 ;
: 2null 0 0 ;

create grepper
        16     ,    \ datasize
        19     ,    \ maxvector
         0     ,    \ handle
         0     ,    \ PREVIOUS
   ' /grepper  ,    \ INVOKE    ( -- )
   ' noop      ,    \ REVOKE    ( -- )
   ' NOOP      ,    \ /INPUT    ( -- )
   ' grep-emit ,    \ EMIT      ( char -- )
   ' grep-type ,    \ TYPE      ( addr len -- )
   ' grep-type ,    \ ?TYPE     ( addr len -- )
   ' grep-cr   ,    \ CR        ( -- )
   ' noop      ,    \ PAGE      ( -- )
   ' DROP      ,    \ ATTRIBUTE ( n -- )
   ' NULL      ,    \ KEY       ( -- char )
   ' NULL      ,    \ KEY?      ( -- flag )
   ' NULL      ,    \ EKEY      ( -- echar )
   ' NULL      ,    \ EKEY?     ( -- flag )
   ' NULL      ,    \ AKEY      ( -- char )
   ' 2DROP     ,    \ PUSHTEXT  ( addr len -- )
   ' 2DROP     ,    \ AT-XY     ( x y -- )
   ' 2null     ,    \ GET-XY    ( -- x y )
   ' 2null     ,    \ GET-SIZE  ( -- x y )
   ' DROP      ,    \ ACCEPT    ( addr u1 -- u2 )

public

: grep ( eval-string len match-string len -- )
   cr set-grep-string 2dup set-grep-source grepper p-eval ;

end-package

\ ======================================================================
