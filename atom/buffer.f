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
   single buf         \ start of buffer
   single ebuf        \ end of buffer
   single gap         \ start of gap
   single egap        \ end of gap
   single row         \ cursor row
   single col         \ cursor col
   single flags       \ buffer flags
   256 buffer: fname  \ filename
   256 buffer: bname  \ buffer name

   : init ( -- )
      NOMARK to mark  0 to point  0 to cpoint  0 to page  0 to epage
      0 to reframe  0 to size  0 to psize  0 to flags  0 to cnt
      0 to buf  0 to ebuf
      0 to gap  0 to egap
      0 fname !  0 bname !  0 link ! ;

   : set-fname ( addr len -- )   fname place ;
   : set-bname ( addr len -- )   bname place ;

   : =fname ( addr len -- flag )   fname count compare 0= ;
   : =bname ( addr len -- flag )   bname count compare 0= ;

   : same? ( addr len -- flag )
      2dup =fname if  =bname  else  2drop -1  then ;

\ ======================================================================
   

end-class
