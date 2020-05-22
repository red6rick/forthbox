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

: guards ( -- n n )   11111111 22222222 ;
   
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

{ ----------------------------------------------------------------------
now, for floating point functions.
we will use the same basic techniques, but no guards... the fp stack
is too limited.

try( i*x -- j*x ) 
try( i*x -- j*x ) f( k*fp -- l*fp )
---------------------------------------------------------------------- }

256 buffer: i-entry
256 buffer: i-exit
256 buffer: f-entry
256 buffer: f-exit
256 buffer: actual

: trim ( addr len -- addr len )   bl skip  -trailing ;

: chopstr ( addr len pat len -- right len left len )
   dup >r  splitstr trim  2swap r> /string  0 max  2swap ;

: parse-test-string ( -- )
   0 word count  2dup actual place
   s" ("  chopstr  2drop
   s" --" chopstr  i-entry place
   s" )"  chopstr  i-exit  place
   s" f(" chopstr  2drop
   s" --" chopstr  f-entry place
   s" )"  chopstr  f-exit  place
   2drop ;

: dot   cr
   ." i-entry " i-entry count type cr
   ." i-exit  " i-exit  count type cr
   ." f-entry " f-entry count type cr
   ." f-exit  " f-exit  count type cr ;

{ ----------------------------------------------------------------------
given a parser, we can build an execution wrapper
---------------------------------------------------------------------- }

32 cells buffer: returned-istack   \ max 31 words plus depth
32 cells buffer: expected-istack

8 floats buffer: returned-fstack
8 floats buffer: expected-fstack

\ ======================================================================
\ spool the fpstack into memory, which resets the fp stack, then
\ format the data from the state as dfloats in memory
\ "to" must be memory allocated 8 dfloats long

: unpack-fpstate ( from to -- )
   8 0 do
      over i fpitem-valid? if
         over 28 +  i xfloats + xf@
         dup i floats + f!
      else
         -1 -1  third i floats + 2!
      then
   loop 2drop ;

: save-fstack ( addr -- )
   r-buf  r@ get-fpstate  r@ h@ !cw  r> swap unpack-fpstate ;

: /istack ( i*x -- )   s0 @ sp! ;

: save-istack ( i*x addr -- )   >r
   depth 31 0 within abort" exit depth out of range"
   depth sp@ r> third 1+ cells cmove  /istack ;

: guards? ( -- flag )
   returned-istack @+ 2- cells + 2@  guards d= ;

: unguard ( -- )   guards? -exit
   -2 returned-istack +!  -2 expected-istack +! ;

: dot-istack ( addr -- )  @+ begin
     1- dup 0< not while
     2dup cells + @ .
  repeat 2drop cr ;
  
: dot-fstack ( addr -- )
   8 floats begin
      1 floats -
      dup 0< not while
      2dup + 2@  -1 -1 d= not if
         2dup + f@ f.
      then
   repeat 2drop cr ;

: report-istacks ( -- )   unguard 
   ." i: wanted -- " expected-istack dot-istack
   ." i: got    -- " returned-istack dot-istack ;

: report-fstacks ( -- )
   ." f: wanted -- "  expected-fstack dot-fstack
   ." f: got    -- "  returned-fstack dot-fstack ;

\ ======================================================================

: setup-entry ( -- )   /istack /ndp  guards
   i-entry count evaluate  f-entry count evaluate ;

: capture-exit ( i*x -- ) f( j*r -- )
   returned-istack save-istack   returned-fstack save-fstack ;

: capture-expected ( -- )
   guards i-exit count evaluate  expected-istack save-istack
   f-exit count evaluate  expected-fstack save-fstack ;

: check-ireturn ( -- )
   returned-istack @+ cells
   expected-istack @+ cells compare -exit  report-istacks  ;

: check-freturn ( -- )
   returned-fstack 8 floats
   expected-fstack 8 floats compare -exit  report-fstacks ;

: try ( -- )
   parse-test-string  capture-expected  setup-entry  
   xt catch abort" fatal error caught in function" 
   capture-exit     check-ireturn check-freturn ;

\ ======================================================================

: bar ( a b -- c )
   + 2/ ;

: zam ( -- ) f( rval rval -- rval )
   f+ f2/ ;

: foo ( a b -- c ) f( rval rval -- rval )
   bar zam ;

testing foo

try ( 4 6 -- 5 ) f( 4.0 6.0 -- 5.0 )

: z testing  try ;
