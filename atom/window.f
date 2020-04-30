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
   : construct window-list @ link !  link window-list ! ;
end-class


: dot ( -- )
   window-list begin   @ ?dup while  dup . repeat ;

: new-window ( -- addr )   atom-window new ;


