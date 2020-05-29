\ include oopext.f

{ ----------------------------------------------------------------------
update swoop
---------------------------------------------------------------------- }

[+switch (throw)
     -103 RUN: S" Object is not correct class for ::" ;
switch]

package oop

THROW#
   S" Execution not allowed during class compilation"   >THROW ENUM IOR_OOP_NOTALLOWED
   S" Invalid method"                                   >THROW ENUM IOR_INVALID_METHOD
   S" Not a class"                                      >THROW ENUM IOR_OOP_NOTACLASS
   S" Not a colon definition"                           >THROW ENUM IOR_OOP_NOTCOLON
TO THROW#

private

: (FIND-MEMBER) ( member class -- 'member true | member 0 )
   2DUP >PUBLIC     BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >PROTECTED  BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >PRIVATE    BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >ANONYMOUS  BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >ANONYMOUS2 BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >ANONYMOUS3 BELONGS? IF NIP NIP -1 EXIT THEN DROP
   DROP 0 ;

PUBLIC

\ add a 2variable data type

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : 2VARIABLE ( -- )   THIS SIZEOF ALIGNED THIS >SIZE !
      [ +CC ] 2 CELLS BUFFER: [ -CC ] ;

   : label: ( -- )   THIS SIZEOF ALIGNED THIS >SIZE !
      [ +CC ] 0 BUFFER: [ -CC ] ;

   : flabel: ( -- )   THIS SIZEOF FALIGNED THIS >SIZE !
      [ +CC ] 0 BUFFER: [ -CC ] ;


   : builds:id
      this sizeof >r  >in @ >r
      [ +cc ] builds [ -cc ]
      r> >in !
      <%  r> %.  %"  constant id_"
         bl word count %type
      %> evaluate ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT



{ ----------------------------------------------------------------------
RELINK-CHILDREN fixes the static links of all of the children
   of a class after it is extended
---------------------------------------------------------------------- }

: RELINK-CHILDREN ( class -- )
   CLASSES BEGIN
      @REL ?DUP WHILE   \ address of class, not handle of class!
      2DUP 2 CELLS + @ = IF
          DUP BODY> RELINK
      THEN
   REPEAT DROP ;

: FIND-MEMBER ( method class -- xt )
   (FIND-MEMBER) IF 3 CELLS + @ ELSE IOR_OOP_NOTMEMBER THROW THEN ;

: DEREF ( class object member -- xt object )
   ROT FIND-MEMBER SWAP ;
{ ----------------------------------------------------------------------
[MY] will return an actual executable xt for the specified member
in the current class context (THIS).  Other extensions are possible
but I don't know what I want, yet.

while defining a class which already contains the ondestroy method:

   [my] ondestroy

[METHOD] will parse for two names, first the class then the
method and return an executable token for the method.

at any arbitrary time:

   [METHOD] genericwindow onclose


---------------------------------------------------------------------- }

: find-executable-member ( method class -- xt )
   (find-member) 0= ior_oop_notmember ?throw
   dup cell- @ ['] a-colon <> ior_oop_notcolon ?throw
   3 cells + @ ;

: find-class ( addr len -- 'class )
   classes begin
      @rel ?dup while   \ a n b
      3dup  body> >name count compare(nc)
   0= until nip nip cell+ @ else 2drop 0 then ;

PUBLIC

: [my] ( -- xt )
   'member 0= ior_oop_notmember ?throw  this find-executable-member
   state @ if postpone literal then ;  immediate

: [method] ( -- xt )
   bl word count find-class  dup 0= ior_oop_notaclass ?throw
   'member 0= ior_oop_notmember ?throw  swap  find-member
   state @ if postpone literal then ;  immediate

: map ( o o o n xt -- )
   locals| xt n |
   n 0 do  xt execute loop ;

{ ----------------------------------------------------------------------
MEMBERS is a function to traverse the member lists of a class, reporting
all members known to the class. Super-class members are automatically
included in the list with no differentiation. The message lists are
printed in BOLD informs about context for which the message is defined.
---------------------------------------------------------------------- }

: #MEMBERS ( head -- n )
   0 BEGIN
      SWAP  @REL ?DUP WHILE  SWAP 1+
   REPEAT ;

: .MEMBER-LIST ( head zstr -- )
   OVER #MEMBERS IF
      CR BOLD ZCOUNT TYPE SPACE NORMAL   BEGIN
         @REL ?DUP WHILE
         DUP CELL+ @ >NAME .ID
      REPEAT
   ELSE 2DROP  THEN ;

: .ID-LIST ( head zstr -- )
   OVER #MEMBERS IF
      CR BOLD ZCOUNT TYPE SPACE NORMAL   BEGIN
         @REL ?DUP WHILE
         DUP CELL+ @ DUP
         FindWM ?DUP IF  NIP ZCOUNT  ELSE  (.)  THEN  ?TYPE SPACE
      REPEAT
   ELSE 2DROP  THEN ;

: SHOW-SUPERCLASS ( class -- )
   >SUPER @ ?DUP IF
      ." superclass "   >NAME .ID
   THEN ;

PUBLIC

: HAS-MEMBERS ( class -- )
   DUP SHOW-SUPERCLASS CR ." <members> "
   DUP >PUBLIC     Z" PUBLIC"     .MEMBER-LIST
   DUP >PROTECTED  Z" PROTECTED"  .MEMBER-LIST
   DUP >PRIVATE    Z" PRIVATE"    .MEMBER-LIST
   DUP >ANONYMOUS  Z" ANONYMOUS"  .ID-LIST
   DUP >ANONYMOUS2 Z" ANONYMOUS2" .ID-LIST
       >ANONYMOUS3 Z" ANONYMOUS3" .ID-LIST ;

{ ----------------------------------------------------------------------
broadcast messages without error; the standard broadcast will throw
an error if a class doesn't know a message. this is good, but better
in practice might be to silently ignore messages that are unknown.

xmsg::
send the message to the object in the given class context, failing
silently if the class doesn't know the message

announce::
in an object context, send (broadcast) the message to all children
of the indicated object, silently failing

announce[]::
like announce, but sends to all children, including the arrays of objects

proclaim::
send the message to all of MY children, including myself.
---------------------------------------------------------------------- }


: XMSG ( class object member-id -- )
   ROT  DUP >C  (FIND-MEMBER) IF 2 CELLS + @+ EXECUTE ELSE 2DROP THEN  C> ;

: ANNOUNCE ( class object message -- )   2>R
   DUP >OBJCHAIN BEGIN
      @REL ?DUP WHILE  DUP
      2 CELLS - 2@ 2R@ >R + R> RECURSE
   REPEAT  2R> XMSG ;

: ANNOUNCE[] ( class object message -- )   2>R
   DUP >OBJCHAIN BEGIN
       @REL ?DUP WHILE
       DUP CELL +  @ >MEMBER-MSG !
      DUP 2 CELLS - 2@ 2R@ >R + R>
          >MEMBER-MSG @   0 DO
             >R 2DUP R@ ROT ROT R>
             >MEMBER-MSG !  OVER SIZEOF I *   + >MEMBER-MSG @   RECURSE
             LOOP DROP 2DROP
   REPEAT  2R> XMSG ;

end-package

SUPREME REOPEN

   : SIZE-OF ( -- n )   THIS SIZEOF ;
   : ZERO ( -- )   addr  size-of erase ;

   : proclaim   ( message -- )   this self rot announce[] ;

end-class  supreme relink-children

{ ----------------------------------------------------------------------
rewrite during refill
assuming that we are using refill to grab a buffer, we can
redefine refill to always copy to a temporary buffer which is much
larger than the program TIB, or we can just have one available
and use it when rewrite-tib is called. to rewrite, we need what?

if we just let a word parse whatever it wants, then call rewrite-tib
starting with its input and appending the rest of the original tib

---------------------------------------------------------------------- }

1024 cell+ buffer: rewrite-buffer

: rewrite-tib ( addr len pos -- )   locals| pos |
   1024 cell+ r-alloc >r  0 r@ !
   'tib @ pos r@   1024 |xappend|
   ( addr len) r@ 1024 |xappend|
   s"  " r@ 1024 |xappend|
   /source r@ 1024 |xappend|
   r> @+ rewrite-buffer xplace
   rewrite-buffer @+ #tib 2!  pos >in ! ;

: <retib ( -- )
   postpone >in postpone @ postpone >r ; immediate

: retib> ( -- )
   postpone r> postpone rewrite-tib ; immediate

{ ----------------------------------------------------------------------
shorthand for object references in definitions
addresses for assignment come off stack in reverse order, just like locals

: foo (o point= blah ) ;   ==>
: foo [objects point names blah objects] ;

: bar ( a1 a2 -- )   (o px= a2 px= a1 )

\ use reference for blah, make new poo on stack frame
(o point= blah   point: poo )
---------------------------------------------------------------------- }

: (o
   postpone [objects
   <retib
      [char] ) word count
      s" =" s"  names" subst here place
      here count s" :" s"  makes" subst here place
      s"  objects] " here append
      here count
   retib> ; immediate

{ ----------------------------------------------------------------------
rewrite rules for object building, to make the syntax easier.

class poo ... end-class  ( or subclass)

poo builds this             == same as ==>    poo: this
3 poo builds[] that[]       == same as ==>    3 poo: that[]
---------------------------------------------------------------------- }

: insert-builds ( addr len -- )
   <retib
      bl peek-word  count s" []" -match nip 0= >r
      here place  s"  builds" here append
      r> if  s" []" here append  then
      here count
   retib> ;

: class:
   bl word count pad place  s" :" pad append
   pad count create-word  here body> ,
   does> @ >name count 1- insert-builds ;

-? : class
   >in @ >r  class:  r> >in !  class ;

-? : subclass
   >in @ >r  class:  r> >in !  subclass ;

: check-size ( n -- )   \ must be exactly n
   [ oop +order ]  this >size @ [previous] <> abort" mis-allocation in class definition" ;

: force-allocation ( n -- )
   [ oop +order ]
   dup this >size @ < abort" size already exceeds request"
   this >size ! [previous] ;

{ ----------------------------------------------------------------------
new defining methods

example:
   class point single x single y : dot x . y . ;   end-class
   point builds pt  
   s" corner" pt anew value xx
   corner dot
   5 to corner x  7 to corner y
   corner dot
   using point xx dot
---------------------------------------------------------------------- }

: create-from-string ( addr len -- xt )
   get-current (wid-create)
   last @ >create !  last 2 cells + @ code> ;

oop +order

: build-from-string ( addr len class -- addr )
   -rot create-from-string  immediate
   dup >data >r  ,   dup sizeof (builds) r>
   does> ['] >data  (object) ;

previous

supreme reopen

   : anew ( addr len -- 'obj )
      this build-from-string ;

end-class  supreme relink-children


