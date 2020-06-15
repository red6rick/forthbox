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
   
\ read fp state, print the valid items as stack, restore state

: f.stack
   r-buf  r@ get-fpstate
   7 begin
      dup 0< not while
      r@ over fpitem-valid? if
         r@ 28 + over xfloats + xf@ f.
      then
   1- repeat drop  r> set-fpstate ;
   
\ ========== add constants to the object structure =====================

supreme reopen

: fsvec ( n -- )   ( n) 0 do  0.0 sf,  loop ;

: fsvar   create   1 fsvec ;

: fsvec3:  create   3 fsvec ;
: fsvec4:  create   4 fsvec ;


end-class   supreme relink-children

\ ----------------------------------------------------------------------
{ ----------------------------------------------------------------------
1/F   ( -- )   f( r -- 1/r )    return the inverse of r

F@+ ( addr -- addr+8 ) f( -- r )   read data from the address,
   leave an incremented address on the stack

FXCHG ( addr addr -- )   swap the contents of the two float variables

---------------------------------------------------------------------- }


: fxchg ( addr addr -- )
   dup f@  over f@  f! f! ;

: 1/f ( -- ) f( f1 -- 1/f1 )   1.0 fswap f/ ;

: f@+ ( addr -- addr+8 ) f( -- data )   dup f@  1 floats + ;
