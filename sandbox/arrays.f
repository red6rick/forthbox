{ ----------------------------------------------------------------------
multi-dimensional, arbitrary index arrays

a 2d example will suffice:

       -5 -2  0  2  3  5  8
   0.0
   0.2
   0.3
   0.4
   0.7

notice that the indices are "floats" and not linear.
and the content isn't filled in yet. the goal will be to
generate a map and find an index of the point below the
point of interest, and by definition you know where
to find the point above it.

Rick VanNorman  19May2020  rick@neverslow.com
---------------------------------------------------------------------- }


{ ----------------------------------------------------------------------
First, the indices. If we keep these as floats will will be doing
64 bit reads and a minimum of two pushes to the fp stack (one for
the number another for the search item. But, all of the floats
can be stored as scaled integers -- use 1,000,000 as the scale
and the floats can be up to +/- 2,000,000,000 without issue.
On index creation, this can be vetted and adjusted as needed, or
ignored.

So the original matrix can be translated into a pure 7 column
by 5 row matrix, addressed as 0..6 , 0..4

But how to find the index? How large is each dimension? With
integers (32 bit values) we can store the array of values of
each dimension in a linear array and use the  scasd (i think)
opcode in a loop to search for it.

---------------------------------------------------------------------- }

{ ----------------------------------------------------------------------
so, create a test block of integers; I will simply use the values
as specified because they will represent scaled floats later.
the data in this table doesn't matter
---------------------------------------------------------------------- }

create dim0  ( n) 7 ,  -500 ,  -200 ,  000 ,  200 ,  300 ,  500 ,  800 ,
create dim1  ( n) 5 ,   000 ,   200 ,  300 ,  400 ,  700 ,

{ ----------------------------------------------------------------------
first, prototype in high level. return index of first element whose
value is above the requested n or -1 if none
search 1000000 elements, about 2300 usec
---------------------------------------------------------------------- }

: dfind ( n array -- index | -1 )
   @+ 0 do  \ n a
      dup i cells + @  third >= if
         2drop i unloop exit
      then
   loop 2drop -1 ;

requires testing

testing dfind
try( 200 dim0 -- 3 )
try( 250 dim0 -- 4 )

{ ----------------------------------------------------------------------
now, define DFIND in code; search 1000000 elements, about 2200 usec
---------------------------------------------------------------------- }

code df ( n array -- index | -1 )
   0 [ebp] eax mov         \ get target value
   4 # ebp add             \ discard from s tack
   0 [ebx] ecx mov         \ get length
   4 [ebx] edx lea         \ addr of first in edx
   0 # ebx mov             \ prime for index
   begin                   \
      0 [edx] [ebx*4] eax cmp      \ check
      <= if ret then
      ebx inc
   loop
   -1 # ebx mov
   ret end-code

testing df
try( 200 dim0 -- 3 )
try( 250 dim0 -- 4 )

{ ----------------------------------------------------------------------
with scas; for a search 1000000 elements, about 1900 usec
doesn't return actual index, needs more calculation on exit
---------------------------------------------------------------------- }

code df2 ( n array -- index | -1 )
   edi push
   0 [ebp] eax mov         \ get target value
   4 # ebp add             \ discard from s tack
   0 [ebx] ecx mov         \ get length
   4 [ebx] edi lea         \ addr of first in edx
   begin                   \
      scasd
      <= if   edi ebx sub  edi pop  ret then
   loop
   -1 # ebx mov
   edi pop
   ret end-code

{ ----------------------------------------------------------------------
speed testing; synthesize a large array and scan for numbers near
the end of it
---------------------------------------------------------------------- }

1000000 constant nn

create dimx   ( n) nn ,  nn cells /allot
   400 dimx nn 20 - cells + !

{ ----------------------------------------------------------------------
large real dataset for binary searching
---------------------------------------------------------------------- }

: fill-dimx
   nn 0 do  i 3 *   i cells dimx + cell+ !  loop ;

fill-dimx

100 value reps

: timed ( xt -- ) locals| xt |
   ucounter drop >r
   reps 0 do  nn 3 * 50 - dimx xt execute drop  loop
   ucounter drop r> - cr  dup . reps /  . ." usec per search" ;

{ ----------------------------------------------------------------------
binary search
---------------------------------------------------------------------- }

: bf0 ( target array -- index | -1 )
   @+ 0 0 locals| m l r a t |
   begin
      l r <
   while
      l r + 2/ to m
      a m cells + @ t < if
         m 1+ to l
      else
         m to r
      then
   repeat l cells a + ;

: timing
   ['] dfind timed
   ['] df    timed
   ['] df2   timed
   ['] bf0   timed ;

