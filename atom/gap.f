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
      0 max  buf +  dup gap < ?exit  gapsize + ;


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
      delta grew + +to egap  delta grew + +to ebuf
      delta +to gap  delta +to buf ;
   
   : grow-gap ( n -- )   2048 ( MIN_GAP_EXPAND ) max  
      buflen if ( exists already)
         buf over buflen + resize z" Failed to resize gap" ?throw
         repoint-buffer
      else
         dup allocate z" Failed to allocate gap" ?throw
         dup to buf  dup to gap  +  dup to ebuf  to egap 
      then ;
   
   
   \ old   |xxxxxx|.................|yyyyyyyyyyyyy|
   \ <new  |xxxx|.................|xxyyyyyyyyyyyyy|
   \ new>  |xxxxxxyy|.................|yyyyyyyyyyy|




   : <move-gap ( pos -- )
      begin  dup gap <  while
         -1 +to gap  -1 +to egap  gap c@ egap c!
      repeat drop ;

   : move-gap> ( pos -- )
      begin  egap over < while
         egap c@ gap c!  1 +to egap 1 +to gap
      repeat drop ;

   : move-gap ( offset --  egap-pos )   ptr
      dup gap   < if  <move-gap  then
      egap over < if  move-gap>  then
      drop egap pos ;

   : insert-file ( zstr mod -- flag )   >r >r 
      r@ zcount file-status nip z" No such file" ?throw
      r@ zcount slurp ( a n)
.s      dup grow-gap 
.s      point move-gap  to point
.s      2dup   gap swap cmove  swap free
      dup +to gap  r> z" read" file-msg
      B_MODIFIED  r> 0= if invert  then  flags and to flags
      -1 ;
      
   : load-file ( zstr -- flag )
      buf to gap  ebuf to egap  top  0 insert-file ;

      

end-class

\ ----------------------------------------------------------------------
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 
