OPTIONAL Testing A simple unit-test framework for SwiftForth

{ ----------------------------------------------------------------------
A testing framework for interactive unit test

TESTING <name>  defines which word to check the function of

The word TRY( takes a standard forth stack picture with actual values
and executes the word under test in a guarded stack frame. The results
of the execution and the guards are compared to the given output
values specified in the TRY( statement. An example will show its use.

testing +          \ let us test the addition word
try( 1 2 -- 3 )    \ this is correct, and the system will not complain
try( 3 4 -- 7 )    \ the system will complain that the result failed

The user is making an assertion in the TRY( statement about
what the expected interface or api is to the word being tested.
Let's pretend to define a function that doesn't behave properly
with regard to the stack: 

: foo ( a b -- c )   swap ;

We were trying to implement nip, but left off the drop. It won't work,
but let's use the TRY( function to detect its failure.

testing foo
try( 1 2 -- 2 )     \ test formulated based on stack comment of FOO

The guards also prevent consumption of stack items not specified:

: bar ( a b -- c )   + nip ;

testing bar
try( 2 3 -- 5 )

Rick VanNorman  19May2020  rick@neverslow.com
---------------------------------------------------------------------- }

2variable input
single xt

: testing ( <name> -- )   ' to xt ;

: guards ( -- n n n )   11111111 22222222 33333333 ;
   
: -- ( guards i*x -- guards j*x guards )
   xt execute  guards ;

: mismatch? ( i*x j*x n -- i*x j*x flag )   
   cells >r  sp@ r@  over r@ +  r> compare ;
   
: dotstack ( addr n -- )
   1- cells bounds  swap do i @ . -cell +loop ;

: failed ( guards i*x guards j*x n -- guards i*x guards j*x )
   >r
      cr ." input    " input 2@ type
      cr ." expected " sp@            r@ dotstack
      cr ." got      " sp@ r@ cells + r@ dotstack 
   r> drop ;

: report ( guards i*x guards j*x n -- )  
   dup >r  2/ mismatch? if   r@ 2/ failed   then  r> discard ;

: try(
   depth >r guards
   [char] ) parse  2dup input 2!  evaluate
   depth r> - report  ;

