{ ----------------------------------------------------------------------
Explore how defers compile in swoop.
Yes, I wrote it. No, I don't remember.

Rick VanNorman  12Jun2020  rick@neverslow.com
---------------------------------------------------------------------- }

\ placeholders
single a
single b
single c

class 2d
   single x
   single y
   defer: dot   x . y . ;
end-class

2d subclass 3d
   single z 
   : dota [ here to a ]  dot ;   \ late binding, will resolve to new dot
   : dot x . y . z . ;           \ the new dot
   : dotb [ here to b ]  dot ;   \ early binding, references new dot
   : foo   ['] dotb h. ;
end-class

cr a dasm
cr b dasm

3d builds cube
cr b code> h. cube foo 

{ ----------------------------------------------------------------------
what we can observe above is that the executable address of dotb
can be found by capturing (in a "meta" way) during compilation.
however, it can't be directly found and saved by code during execution
or compilation.

let's add a compiler tool to the oop system
---------------------------------------------------------------------- }

package oop
private

: find-executable-member ( method class -- xt )
   (find-member) 0= ior_oop_notmember ?throw
   dup cell- @ ['] a-colon <> ior_oop_notcolon ?throw
   3 cells + @ ;

public

: [my] ( -- xt )
   'member 0= ior_oop_notmember ?throw  this find-executable-member
   state @ if postpone literal then ;  immediate

end-package

{ ----------------------------------------------------------------------
the function [my] will return the proper xt of a method in a class.
let's show the results; in 4d, we can retrieve the actual xt of dotc.
this means we can save it in a variable and directly use the kernel
forth word execute to reference it

BUT ONLY FROM ANOTHER WORD IN THE CLASS!!!

so we can make instantiation time decisions about which method to
run without having to use a run-time decision pattern like IF THEN
---------------------------------------------------------------------- }

2d subclass 4d
   single z
   single w
   : dot x . y . z . w . ;       \ the new dot
   : dotc [ here to c ]  dot ;   \ early binding, references new dot
   : foo   ['] dotc h. ;
   : bar   [my] dotc h. ;
end-class

4d builds hyper
cr c code> h. hyper foo hyper bar

{ ----------------------------------------------------------------------
a pair of examples; yes they are points...
---------------------------------------------------------------------- }

class ex1
   single x  single y   \ data
   single how           \ how to print, true or not
   : set-xy ( x y -- )   to y to x ;
   : dot(10)   base @ >r decimal  x . y .  r> base ! ;
   : dot(16)   base @ >r hex      x . y .  r> base ! ;
   : dot cr how if dot(10) else dot(16) then ;
   : use-dot(10)   1 to how ;
   : use-dot(16)   0 to how ;
end-class

ex1 builds t1   100 199 t1 set-xy
t1 use-dot(10) t1 dot
t1 use-dot(16) t1 dot

class ex2
   single x  single y   \ data
   single how           \ how to print, a class xt
   : set-xy ( x y -- )   to y to x ;
   : dot(10)   base @ >r decimal  x . y .  r> base ! ;
   : dot(16)   base @ >r hex      x . y .  r> base ! ;
   : dot cr how execute ;
   : use-dot(10)   [my] dot(10) to how ;
   : use-dot(16)   [my] dot(16) to how ;
end-class

ex2 builds t2   100 199 t2 set-xy
t2 use-dot(10) t2 dot
t2 use-dot(16) t2 dot

{ ----------------------------------------------------------------------
with ex2, we can decide at instantiation of an object how it will
be printed with mimimal overhead for the decision at runtime. it does
require that the class defines a function to find the xt of the
desired method and set the execution vector.

if we extend our operator set a little, we can do even better
---------------------------------------------------------------------- }

package oop
private

: find-class ( addr len -- 'class )
   classes begin
      @rel ?dup while   \ a n b
      3dup  body> >name count compare(nc)
   0= until nip nip cell+ @ else 2drop 0 then ;

public

: [method] ( -- xt )   \   [method] class method --> xt 
   bl word count find-class  dup 0= ior_oop_notaclass ?throw
   'member 0= ior_oop_notmember ?throw  swap  find-member
   state @ if postpone literal then ;  immediate

end-package

{ ----------------------------------------------------------------------
now, we can do this without having to have any class function for it
---------------------------------------------------------------------- }

class ex3
   single x  single y   \ data
   single how           \ how to print, a class xt
   : set-xy ( x y -- )   to y to x ;
   : dot(10)   base @ >r decimal  x . y .  r> base ! ;
   : dot(16)   base @ >r hex      x . y .  r> base ! ;
   : dot cr how execute ;
end-class

ex3 builds t3   100 199 t3 set-xy  [method] ex3 dot(10) to t3 how
ex3 builds t4   100 199 t4 set-xy  [method] ex3 dot(16) to t4 how

t3 dot
t4 dot


