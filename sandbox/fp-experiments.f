requires fpmath

code !cw ( cw -- )
   push(ebx)  0 [ebp] fldcw  pop(ebx) pop(ebx)
   ret end-code

code @cw ( -- cw )
   push(ebx) push(ebx)  0 [ebp] fstcw  pop(ebx) $ffff # ebx and
   ret end-code

code get-fpstate ( addr -- )   0 [ebx] fnsave  pop(ebx) ret end-code
code set-fpstate ( addr -- )   0 [ebx] frstor  pop(ebx) ret end-code

code xf@ 0 ( a -- ) f( -- rval )
   [ebx] tbyte fld  pop(ebx)  f> fnext

: xfloats ( n -- n )   10 * ;

128 buffer: fsbuf

: fpitem-valid? ( fpstate n -- flag ) 
   7 and >r  8 + h@  7 r> - 2* rshift 2 and 0= ;
   
: f.stack
   r-buf  r@ get-fpstate
   7 begin
      dup 0< not while
      r@ over fpitem-valid? if
         r@ 28 + over xfloats + xf@ f.
      then
   1- repeat drop  r> set-fpstate ;
   
