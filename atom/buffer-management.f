
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
   atom-buffer new [objects atom-buffer names foo objects]
   foo init  foo set-bname 
   buffer-list @ foo link !  foo link buffer-list !
   foo addr ;

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
