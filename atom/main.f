{ ----------------------------------------------------------------------
a forth clone of the atto editor
https://github.com/hughbarney/atto

Rick VanNorman  29Apr2020  rick@neverslow.com

notes:
1. atto/main.c sets up io as raw, colors, etc. not needed here.
2. new_window() is called, and assigned, and set as only
3. associate_b2w is called; associate buffer to window
4. the buffer is gap model
5. key dispatcher is called, until done
6. close and done.
---------------------------------------------------------------------- }

include ncurses-stubs

0 equ NOMARK
1 equ B_MODIFIED
: file-msg ( n zname ztype -- )
   operator's cr zcount type space zcount type space . ;
   
variable window-list
variable buffer-list

single curbuf
single curwin

: disassociate-buffer ( n -- ) drop ;
: associate-buffer ( a a -- )   2drop ;

include buffer
include gap
include test
include buffer-management

\ ----------------------------------------------------------------------

\ s" one" new-buffer value z1
\ 
\ : test
\    z1 (o atom-buffer= bp )
\    s" main.f" bp insert-file ;
oop +order
: foop ( addr -- )
   [objects atom-buffer names foo objects]
   foo addr  atom-buffer swap [member] construct broadcast 
   foo init s" this" foo set-bname 
   buffer-list @ foo link !  foo link buffer-list !
   foo addr ;
previous
atom-buffer builds foo
foo addr foop
2048 foo grow-gap
s" clip_temp.txt" slurp   value len value addr   
addr foo buf 1200 cmove   
1200 +to foo gap
500 foo move-gap drop


\\

make a buffer, buf ebug gap egap point  = 0
make a window
grow a gap

: atom ( -- )
   atom-window construct ;

( init based on args passed... )

: edit-file ( addr len -- )
   2dup true find-buffer  to curb
   2dup false insert-file drop
   using curb set-filename ;

[...]
   new-window  dup to curw  to curb

