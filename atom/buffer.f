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

   : init ( -- )
      NOMARK to mark  0 to point  0 to cpoint  0 to page  0 to epage
      0 to reframe  0 to size  0 to psize  0 to flags  0 to cnt
      0 to buf  0 to ebuf  0 to gap  0 to egap  0 fname !  0 bname !  0 to link ;

   : dot ( -- )
      cr ." fname " fname count type
      cr ." bname " bname count type
      cr ." flags " flags . reframe .
      cr ." point " point h. cpoint h. mark h.
      cr ." buf   " 'buf h. 'ebuf h.
      cr ." gap   " 'gap h. 'egap h.
      cr ." page  " page h. epage h.
      cr ." rc    " row . col .
      cr ." size  " size . psize . ;
      



   : set-fname ( addr len -- )   fname place ;
   : set-bname ( addr len -- )   bname place ;

   : =fname ( addr len -- flag )   fname count compare 0= ;
   : =bname ( addr len -- flag )   bname count compare 0= ;

   : same? ( addr len -- flag )
      2dup =fname if  =bname  else  2drop -1  then ;

\ ======================================================================

   : ptr ( offset -- buffer-addr )
      dup 0< if  drop  'buf exit  then
      'buf +  dup 'gap < ?exit   'egap 'gap - + ;
   



end-class

: dot-buffers ( -- )
   buffer-list begin
      @ ?dup while >r
      using atom-buffer r@ bname count type space
      r>
   repeat ;

: find-buffer ( name len -- buffer )
   buffer-list begin
      @ ?dup while >r
      using atom-buffer r@ bname count 2over compare(nc)
      0= if  2drop r> exit then
      r>
   repeat 2drop 0 ;
   
: new-buffer ( name len -- addr )
   2dup find-buffer ?dup if  nip nip exit  then
   atom-buffer new >r
   using atom-buffer  r@ init  using atom-buffer  r@ set-bname
   buffer-list @ r@ !  r@ buffer-list !
   r> ;

: delete-buffer ( item list -- )   
   begin  dup @  ?dup  while
      third over = if  @ swap !  free drop  exit  then
   nip repeat  2drop ;

: next-buffer ( -- )
   curbuf 0= z" no buffer selected" ?throw
   buffer-list @ 0= z" no buffers defined" ?throw
   curwin disassociate-buffer
   curbuf @ dup 0= if drop buffer-list @ then
   dup to curbuf  curwin associate-buffer ;

: buffer-name ( buf -- addr len )
   [objects atom-buffer names b objects]
   b fname c@ if  b fname  else  b bname  then count ;

: count-buffers ( -- n )
   0  buffer-list begin  @ ?dup while swap 1+ swap  repeat ;


\\

s" this"   new-buffer value x1
s" that"   new-buffer value x2
s" one"    new-buffer value x3
s" two"    new-buffer value x4
s" three"  new-buffer value x5
