{ ----------------------------------------------------------------------
atom-buffer defines the buffer structure used by the atom editor

Rick VanNorman  29Apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

class atom-buffer
   variable link      \ Link to next buffer_t
   single mark        \ the mark
   single point       \ the point
   single cpoint      \ the original current point, used for mutliple window displaying
   single page        \ start of page
   single epage       \ end of page
   single reframe     \ force a reframe of the display
   single cnt         \ count of windows referencing this buffer
   single size        \ current size of text being edited (not including gap)
   single psize       \ previous size
   single 'buf        \ start of buffer
   single 'ebuf       \ end of buffer
   single 'gap        \ start of gap
   single 'egap       \ end of gap
   single row         \ cursor row
   single col         \ cursor col
   single flags       \ buffer flags
   256 buffer: fname  \ filename
   256 buffer: bname  \ buffer name

   : set-fname ( addr len -- )   fname place ;
   : set-bname ( addr len -- )   bname place ;

   : =fname ( addr len -- flag )   fname count compare 0= ;
   : =bname ( addr len -- flag )   bname count compare 0= ;

   : same? ( addr len -- flag )
      2dup =fname if  =bname  else  2drop -1  then ;
      
end-class

: find-buffer ( addr len flag -- addr )   locals| f len addr |
   buffer-list begin
      @ ?dup while >r
      addr len  using atom-buffer r@ same? if
         drop r> exit  then
      
      

\ 
\ 
\ : buffer-exists? ( addr len -- buffer true | 0 false )
\    buffer-list begin
\       @ ?dup while >r
\       using atom-buffer r@ fname count  2dup compare 
\       
      
       

: find-buffer ( addr len flag -- buffer )
  search for filename in buffer list
  if found, return buffer
  if flag is true
     make a new buffer
     if fail, return 0
     init buffer
     insert buffer into list
     

