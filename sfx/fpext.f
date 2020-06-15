{ ========== fpext.f ===================================================
  (C) 2020 Stratolaunch LLC ---- 13Feb2020 rcw/rcvn

  Extensions to the standard FPMATH package in SwiftForth.
====================================================================== }

{ ========== simplified float numeric input ============================
  SwiftForth uses strict floating point numeric input by default. This
  means numbers are required to end with an exponent indication.
  This is useful if the application mixes single integers, double integers,
  and floating point numbers.

     1234      single integer, 32 bits, value 1234
     12.34     double integer, 64 bits, value 1234
     12.34e0   floating point, ?? bits, value 12.34

  It isn't as convenient when the application uses no double integers,
  but the user wishes to use simple representations of floating point
  numbers, such as 12.34 to mean "12.34".

  EASY-FNUMBER? adds a hook to the front of the numeric input
  converter in SwiftForth to allow this using the loose-and-easy
  version specified by ANS standard forth in  "12.6.1.0558   >FLOAT"

  It can be turned off by setting EASYFLOAT to zero.
  It ignores the text if the number is already converted.
  It ignores the text if the base isn't DECIMAL
  It ignores the text if the text doesn't include a decimal point
  It ignores the text if it fails the >FLOAT conversion.

====================================================================== }

: nodot ( addr len 0 -- addr len 0 flag )
   third third [char] . scan nip 2 < ;

1 value easyfloat

: easy-fnumber? ( addr len 0 | ... xt -- addr len 0 | ... xt )
   easyfloat -exit            \ user doesn't want, so exit
   dup ?exit                  \ already resolved, exit.
   base @ 10 <> ?exit         \ not base 10, exit
   nodot ?exit drop           \ check for dot, ignore dot as last char
   r-buf  2dup r@ place       \ save string
   r> count >float if         \ made a simple float
      2drop                   \ discard original addr len
      ['] fliteral exit       \ leave with fliteral on ds, float on fstack
   then ( addr len) 0 ;       \ otherwise, continue

\ insert this at the head of the chain so it runs first

' easy-fnumber? number-conversion >chain

{ ======================================================================

F(   defines a float-stack comment, just like (.  In use:

             : foo ( n -- a b c )  f( pi -- pi*2 )

F<=   ( -- f ) f( r1 r2 -- )    returns true if r1 <= r2
F>=   ( -- f ) f( r1 r2 -- )    returns true if r1 >= r2
F<>   ( -- f ) f( r1 r2 -- )    returns true if r1 <> r2
1/F   ( -- )   f( r -- 1/r )    return the inverse of r

F@+ ( addr -- addr+8 ) f( -- r )   read data from the address,
   leave an incremented address on the stack

FXCHG ( addr addr -- )   swap the contents of the two float variables

====================================================================== }

: f(   [CHAR] ) SKIP-PAST ; IMMEDIATE

: f<= ( -- flag ) f( f1 f2 -- )   f> not ;
: f>= ( -- flag ) f( f1 f2 -- )   f< not ;
: f<> ( -- flag ) f( f1 f2 -- )   f= not ;
: 1/f ( -- ) f( f1 -- 1/f1 )   1.0 fswap f/ ;

: f@+ ( addr -- addr+8 ) f( -- data )   dup f@  1 floats + ;

: fxchg ( addr addr -- )
   dup f@  over f@  f! f! ;

{ ========== floats on return stack ====================================
  These functions allow using the return stack as temporary storage
  for floating point numbers, just like >R etc do for integers

   F>R ( -- ) f( r -- ) rs( -- r )   save a float on the return stack
   FR> ( -- ) f( -- r ) rs( r -- )   get a float from the return stack
   FR@ ( -- ) f( -- r ) rs( r -- )   copy a float from the return stack

====================================================================== }

icode f>r \ move a float from hardware stack to return stack, has to be inline
   >f
   1 floats # esp sub
   0 [esp] qword fstp
   fnext

icode fr@
   0 [esp] qword fld
   f> fnext

icode fr>
   0 [esp] qword fld
   1 floats # esp add
   f> fnext

icode fr@n ( n -- )
   0 [esp] [ebx*8] qword fld
   pop(ebx)
   f> fnext

: (f.s) ( -- )   fdepth ?dup -exit
   begin  fdepth while  f>r  repeat
   ( *) 0 begin  2dup > while  dup fr@n n.  1+  repeat drop
   ( *) begin  ?dup while  fr>  1- repeat ;

: i.s ( ? -- ? )
   cr depth 0> if depth 0 do s0 @ i 1+ cells - @ . loop then ." <-Top "
   depth 0< abort" Underflow" ;

-? : .s ( ? -- ? )   i.s  fdepth if (f.s) ." <-NTop " then ;

: f.s ( ? -- ? )   cr (f.s) ." <-NTop " ;

{ ========== floating point values in classes ==========================
  We extend the object compiler to include floating point values.
  For the same reason that SINGLE is used in classes instead of VALUE,
  FSINGLE is used instead of FVALUE

====================================================================== }


PACKAGE OOP

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : FSINGLE ( -- )
      MEMBER  THIS SIZEOF
      ['] RUN-VALUE ['] COMPILE-VALUE  NEW-MEMBER
      4 ,  ['] F@ , ['] F! ,  ['] F+! ,  ['] NOOP ,
      1 FLOATS THIS >SIZE +! ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

END-PACKAGE

\ ========== add constants to the object structure =====================

supreme reopen

: fsvec ( n -- )   ( n) 0 do  0.0 sf,  loop ;

: fsvar   create   1 fsvec ;

: fsvec3:  create   3 fsvec ;
: fsvec4:  create   4 fsvec ;


end-class   supreme relink-children

\ ========== add floating point constants as a basic datatype ==========

PACKAGE OOP

: RUN-FCONST ( object 'data -- ) ( -- f )
   NIP f@ ;

: COMPILE-FCONST ( 'data -- )   "SELF"  POSTPONE DROP
   f@  POSTPONE fLITERAL  END-REFERENCE ;

FLAVOR A-FCONST SAME-AS  IS-UNDEFINED
>COMPILE-XT  <WILL-BE COMPILE-FCONST
>RUNTIME-XT  <WILL-BE RUN-FCONST
>CCOMPILE-XT <WILL-BE COMPILE-FCONST
>CRUNTIME-XT <WILL-BE RUN-FCONST


GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : FCONST ( -- )
      member 0 ['] RUN-FCONST ['] COMPILE-FCONST NEW-MEMBER
      cell negate allot  f, ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

end-package

\ ========== modest extensions to the optimizer ========================

1 floats 8 = [if]   \ only if we're sure ....

-? icode floats ( n -- n )
   ebx 3 # shl
   ret end-code

[then]

{ ======================================================================
(F.3) formats a float in
====================================================================== }


: (f.frac) ( frac -- addr len ) f( r -- )
   dup >r  >10** f>d
   swap over dup 0< if dnegate then
   <#  r> 0 ?do # loop  [char] . hold  #s rot sign  #> ;

: (f.r.frac) ( n frac -- addr len ) f( r -- )
   (f.frac)  rot over - 0 max  0 ?do  bl hold  loop    #> ;

: f.r.frac ( n frac -- )   (f.r.frac) type space ;

: (f.3)   3 (f.frac) ;
: f.3   (f.3) type ;

: (f.8.3)  ( -- addr len ) f( r -- )    8 3 (f.r.frac) ;
: (f.10.3) ( -- addr len ) f( r -- )   10 3 (f.r.frac) ;

: %f.3 (f.8.3) %type ;


{ ======================================================================
a few specific code optimizations for interpolate
====================================================================== }

code 3-fpick ( -- )   f( r0 r1 r2 r3 -- r0 r1 r2 r3 r0 )
   4 >fs   ST(3) FLD   5 fs>   FNEXT

code 2-fpick ( -- )   f( r0 r1 r2 -- r0 r1 r2 r0 )
   3 >fs   ST(2) FLD   4 fs>   FNEXT

CODE F-ROT ( -- ) ( r r r -- r r r )
   3 >fs   ST(2) FXCH   ST(1) FXCH  3 fs>   FNEXT

{ ======================================================================
linear interpolation

                     (y1-y0)             (y1-y0)             yd
   y = y0 + (x-x0) * ------- = y0 + xm * ------- = y0 + xm * --
                     (x1-x0)               xd                xd

simple, straightforward linear interpolation

: interpolate ( -- )  f( y0 y1 x0 x1 x -- y )
   2-fpick f-  f-rot  fswap f- \ y0 y1 xm xd
   frot 3-fpick f-             \ y0 xm xd yd
   fswap f/ f* f+ ;

If the program interpolates several dependent variables against
fixed independent variables, interpolants may be used. This amounts
to refactoring the interpolation equation into

   y = y0 * ( 1 - xi ) + y1 * xi      | code interpolant ( x0 x1 x -- xi )
                                      |    st(2) fld       \ x0 x1 x  x0  
         x - x0                       |    fsubp           \ x0 x1 xm     
   xi = --------   and  xq = (1 - xi) |    st(2) fxch      \ xm x1 x0     
        x1 - x0                       |    fsubp           \ xm xd        
                                      |    fdivp                          
   y = (y0 * xq) + (y1 * xi)          |    fnext                          

====================================================================== }

code interpolate ( -- )  f( y0 y1 x0 x1 x -- y )
                     \ y0 y1 x0 x1 x
     st(2) fld       \ y0 y1 x0 x1 x x0
     fsubp           \ y0 y1 x0 x1 xm
     st(2) fxch      \ y0 y1 xm x1 x0
     fsubp           \ y0 y1 xm xd
     fdivp           \ y0 y1 md
     st(1) fxch      \ y0 md y1
     st(2) fld       \ y0 md y1 y0
     fsubp           \ y0 md yd
     fmulp           \ y0 xd
     faddp
     fnext

code interpolants ( x0 x1 x -- xi xq )
   st(2) fld          \ x0 x1 x  x0    
   fsubp              \ x0 x1 xm       
   st(2) fxch         \ xm x1 x0       
   fsubp              \ xm xd          
   fdivp              \ xi             
   fld1               \ xi 1.
   st(1) fld          \ xi 1. xi
   st(0) st(1) fsubp  \ xi xq
   fnext              \

{ ======================================================================

Given that we have interpolants, we can save tremendous execution time
if we keep the xi and xq terms on the fpstack instead of loading them
for each operation. This poorly-named function does this; it interpolates
between y0 and y1 using the ratios of xi and xq, returning y and
preserving xi and xq for further use.

====================================================================== }

code polate ( xi xq y0 y1 -- xi xq y )
   st(3) st(0) fmul    \ xi xq y0 Y1 
   st(1) fxch          \ xi xq Y1 y0 
   st(2) st(0) fmul    \ xi xq Y1 Y0
   faddp               \ xi xq Y
   fnext

{ ======================================================================
FNEXT nominally ends a floating point code word; early exit
begs for FRET which simply does not change context away from assembler
====================================================================== }

ASSEMBLER

: FRET ( -- )   [DEFINED] FPDEBUG [IF]  WAIT  [THEN]
   RET  ;

FORTH

{ ======================================================================
create a self-fetching fvalue (which isn't eligible for "to" operators)
====================================================================== }

\ support; optimization possible here

: indirect-fvalue ( addr <name> -- )   \ run: f( -- rval )
   create , does> @ f@ ;

{ ======================================================================
redefine fvariable here so we can dereference it by its code pointer.
the definition of (fcreate) is exactly the same as (create) but has
a unique address
====================================================================== }

CODE (DFCREATE)
   PUSH(EBX)                        \ push old tos
   EBX POP                          \ new tos from return stack
   RET   END-CODE

CODE (SFCREATE)
   PUSH(EBX)                        \ push old tos
   EBX POP                          \ new tos from return stack
   RET   END-CODE

-? : SFVARIABLE   HEADER  POSTPONE (SFCREATE)  #0.0E SF, ;   \ Usage: SFVARIABLE <name>
-? : DFVARIABLE   HEADER  POSTPONE (DFCREATE)  #0.0E DF, ;   \ Usage: DFVARIABLE <name>

-? AKA DFVARIABLE FVARIABLE

{ ======================================================================
function for fvalues NOT defined in fpmath.f
====================================================================== }

: &OF-FVALUE ( -- addr -1 | 0 )   >IN @ >R  '
   DUP PARENT ['] (FVALUE) = IF  (ADDR-OF)  R> DROP  -1
   ELSE  DROP  R> >IN !  0  THEN ;

-? : &OF ( -- addr )
   LOBJ-COMP &OF-LOCAL  ?EXIT
   LVAR-COMP &OF-LOCAL  ?EXIT
             &OF-VALUE  ?EXIT
             &OF-FVALUE ?EXIT
   3 'METHOD ! ; IMMEDIATE

{ ======================================================================
check the ndp status register for detectable errors
====================================================================== }

: ?ndp ( -- )
   @fsts $05 and -exit
   @fsts  $01 and  z" ndp error - invalid operation" ?throw
   @fsts  $04 and  z" ndp error - divide by zero"    ?throw
\  @fsts  $20 and  z" ndp error - lost precision"    ?throw
               -1  z" unknown ndp error"             ?throw ;

{ ======================================================================
The current swiftforth doesn't manage fp state very well.
These functions put a patch layer over the fp functions to allow
capture and control of the fpu.
====================================================================== }


\ ========== read and write control word ===============================

code !cw ( cw -- )
   push(ebx)  0 [ebp] fldcw  pop(ebx) pop(ebx)
   ret end-code

code @cw ( -- cw )
   push(ebx) push(ebx)  0 [ebp] fstcw  pop(ebx) $ffff # ebx and
   ret end-code

\ ======================================================================
\ read and write fp state, including all 8 registers of stack
\ note that FNSAVE will do FINIT after reading state, so
\ all exceptions masked and stack is empty until FRSTOR

code get-fpstate ( addr -- )   0 [ebx] fnsave  pop(ebx) ret end-code
code set-fpstate ( addr -- )   0 [ebx] frstor  pop(ebx) ret end-code

\ ======================================================================
\ manage data in the fpu state record

code xf@ 0 ( a -- ) f( -- rval )
   [ebx] tbyte fld  pop(ebx)  f> fnext

: xfloats ( n -- n )   10 * ;

\ check fpu tag word for a valid item in the saved state stack
\ see fig 8.7 in intel's 64-ia-32-architectures.. vol1 manual

: fpitem-valid? ( fpstate n -- flag ) 
   7 and >r  8 + h@  7 r> - 2* rshift 2 and 0= ;
   
\ read fp state, print the valid items as stack, retore state

: f.stack
   r-buf  r@ get-fpstate
   7 begin
      dup 0< not while
      r@ over fpitem-valid? if
         r@ 28 + over xfloats + xf@ f.
      then
   1- repeat drop  r> set-fpstate ;
   
