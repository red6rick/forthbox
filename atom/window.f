{ ----------------------------------------------------------------------
the window functions for atom

Rick VanNorman  29Apr2020  rick@neverslow.com

it seems like what i want to do is have a window class which
is the visible part of the editor

i don't think i care about a split window, but i might...

each window would be an object, dynamically assigned,
a linked list one to another

each window has a buffer associated with it

my model is that the class exists; build or new one of it, or
simple start with a pre-allocated max number? nah...

---------------------------------------------------------------------- }

variable window-list

class atom-window
   variable link
   single bufp
   single point
   single mark
   single page
   single epage
   single top
   single rows
   single row
   single row
   single col
   single update
   256 buffer: name

   : init ( -- )
      0 to next  0 to bufp  NOMARK to mark  0 to top
      0 to rows  FALSE to update
      1 +to wincnt   <% %" W" wincnt 3 %.0 %> name place ;

end-class

: dot ( -- )
   window-list begin   @ ?dup while  dup . repeat ;

: new-window ( -- wp )
   atom-window new >r
   r@ 0= z" failed to allocate new window" ?throw
   using atom-window  r@ init
   window-list @  r@ !  r@ window-list ! ;
   
: associate-buffer ( bp wp -- )
   using atom-window  2dup to bufp  
   using atom-buffer  1 +to cnt ;
   

