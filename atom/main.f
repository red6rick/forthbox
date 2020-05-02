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

0 equ NOMARK
variable window-list
variable buffer-list

single curbuf
single curwin

: disassociate-buffer ( n -- ) drop ;
: associate-buffer ( a a -- )   2drop ;

include buffer
include test
include buffer-management

\\

: atom ( -- )
   atom-window construct ;

( init based on args passed... )

: edit-file ( addr len -- )
   2dup true find-buffer  to curb
   2dup false insert-file drop
   using curb set-filename ;

[...]
   new-window  dup to curw  to curb

