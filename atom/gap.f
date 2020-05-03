{ ----------------------------------------------------------------------
gap management for the atom editor
since all gaps belong to buffers, we will reopen the buffer
class and add gap management there.

Rick VanNorman  30Apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

atom-buffer reopen

   : gapsize ( -- n )   egap gap - ;
   
   \ Given a buffer offset, convert it to a pointer into the buffer 
   : ptr ( offset -- buffer-addr )
      0 max  gap <
      dup 0< if  drop  buf exit  then
      buf +  dup gap < ?exit   gapsize + ;

   \ Given a pointer into the buffer, convert it to a buffer offset 
   : pos ( buffer-addr -- offset )
      buf -  0 max  dup egap < ?exit  gapsize - ;

: buflen ( -- n )   ebuf buf - ;
: buf-left ( -- n )   gap buf - ;
: buf-right ( -- n )   ebuf egap - ;

\ the resize operation copied existing buffer

\ old |xxxxxx|....|yyyyyyyyyyyyy|
\ new |xxxxxx|....|yyyyyyyyyyyyy.............|
\ new |xxxxxx|.................|yyyyyyyyyyyyy|

: repoint-buffer ( grew new-buf -- )
   buf - locals| delta grew |
   egap delta +  dup grew +  grew cmove>
   delta +to egap  delta +to ebuf  delta +to gap  delta +to buf ;

: grow-gap ( n -- )   2048 ( MIN_GAP_EXPAND ) max  
   buflen if ( exists already)
      buf over buflen + resize z" Failed to resize gap" ?throw
      repoint-buffer
   else
      dup allocate z" Failed to allocate gap" ?throw
      dup to buf  dup to gap  +  dup to ebuf  to egap 
   then ;

   : move-gap ( offset -- ) ;



end-class

\ ----------------------------------------------------------------------
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 
