{ ----------------------------------------------------------------------
experiments with x87 fpu

Trying to use the control register and save/restore fpu state
properly. With this, we can do a proper .s for all stack items,
and potentially do numeric input no matter how many things on
the stack.

Rick VanNorman  21May2020  rick@neverslow.com
---------------------------------------------------------------------- }

requires fpmath

\ read and write control word

code !cw ( cw -- )
   push(ebx)  0 [ebp] fldcw  pop(ebx) pop(ebx)
   ret end-code

code @cw ( -- cw )
   push(ebx) push(ebx)  0 [ebp] fstcw  pop(ebx) $ffff # ebx and
   ret end-code

\ read and write fp state, including all 8 registers of stack

code get-fpstate ( addr -- )   0 [ebx] fnsave  pop(ebx) ret end-code
code set-fpstate ( addr -- )   0 [ebx] frstor  pop(ebx) ret end-code

\ read a 10 byte fp number from memory to fpu

code xf@ 0 ( a -- ) f( -- rval )
   [ebx] tbyte fld  pop(ebx)  f> fnext

\ size of a 10 byte float

: xfloats ( n -- n )   10 * ;

\ check fpu tag word for a valid item in the saved state stack
\ see fig 8.7 in intel's 64-ia-32-architectures.. vol1 manual

: fpitem-valid? ( fpstate n -- flag ) 
   7 and >r  8 + h@  7 r> - 2* rshift 2 and 0= ;
   
\ show all of stack without fail

: f.stack
   r-buf  r@ get-fpstate
   7 begin
      dup 0< not while
      r@ over fpitem-valid? if
         r@ 28 + over xfloats + xf@ f.
      then
   1- repeat drop  r> set-fpstate ;
   
