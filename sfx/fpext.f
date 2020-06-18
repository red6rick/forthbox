{ ========== fpext.f ===================================================
  (C) 2020 Stratolaunch LLC ---- 13Feb2020 rcw/rcvn

  Extensions to the standard FPMATH package in SwiftForth.
====================================================================== }


-? icode fnegate fchs ret end-code
-? icode f+ faddp ret end-code
-? icode f- fsubp ret end-code
-? icode f* fmulp ret end-code
-? icode f/ fdivp ret end-code

-? icode fswap st(1) fxch               ret end-code 
-? icode fdup  st(0) fld                ret end-code
-? icode f2dup st(1) fld  st(1) fld     ret end-code
-? icode fover st(1) fld                ret end-code
-? icode fdrop st(0) fstp               ret end-code
-? icode frot  st(1) fxch   st(2) fxch  ret end-code

-? icode #0.0e  fldz   ret end-code
-? icode #1.0e  fld1   ret end-code
-? icode pi     fldpi  ret end-code
-? icode ln2    fldln2 ret end-code

-? icode f!   0 [ebx] qword fstp   0 [ebp] ebx mov  4 # ebp add  ret end-code
-? icode f@   0 [ebx] qword fld    0 [ebp] ebx mov  4 # ebp add  ret end-code

-? icode f+!  0 [ebx] qword fadd  0 [ebx] qword fstp
          0 [ebp] ebx mov  4 # ebp add  ret end-code

-? icode fcos fcos ret end-code
-? icode fsin fsin ret end-code

CODE (FCONSTANT)
   EAX POP  0 [EAX] QWORD FLD
   RET END-CODE

code (FINDIRECT)
   eax pop  0 [eax] eax mov  0 [eax] qword fld  ret end-code

-? : FCONSTANT  HEADER POSTPONE (FCONSTANT) F, ;

: indirect-fvalue
   header  postpone (findirect) , ;

\ ----------------------------------------------------------------------

OPTIMIZING-COMPILER +ORDER

[+SWITCH SAFE
   ' (FVALUE) RUN: ['] (FVALUE) ;
   ' (FCONSTANT) RUN: ['] (FCONSTANT) ;
   ' (FINDIRECT) RUN: ['] (FINDIRECT) ;
SWITCH]

: FVAR-@ [+ASM]
   LASTCHILD CELL+ @ [EDI] QWORD FLD
   [-ASM] ;

OPTIMIZE ANY (FVALUE) WITH FVAR-@

: LIT->BODYF! ( -- )   [+ASM]
   LASTLIT @ 5 + [EDI] QWORD FSTP
   [-ASM] ;

OPTIMIZE (LITERAL) >BODYF! WITH LIT->BODYF!

OPTIMIZE NEW-VAR F@ WITH FVAR-@

: FVAR-@-F+ ( -- )   [+ASM]  LASTCHILD CELL+ @ [EDI] QWORD FADD   [-ASM] ;
: FVAR-@-F* ( -- )   [+ASM]  LASTCHILD CELL+ @ [EDI] QWORD FMUL   [-ASM] ;
: FVAR-@-F/ ( -- )   [+ASM]  LASTCHILD CELL+ @ [EDI] QWORD FDIV   [-ASM] ;
: FVAR-@-F- ( -- )   [+ASM]  LASTCHILD CELL+ @ [EDI] QWORD FSUB   [-ASM] ;
   

OPTIMIZE FVAR-@ F+ WITH FVAR-@-F+
OPTIMIZE FVAR-@ F* WITH FVAR-@-F*
OPTIMIZE FVAR-@ F- WITH FVAR-@-F- 
OPTIMIZE FVAR-@ F/ WITH FVAR-@-F/


{ ----------------------------------------------------------------------
: FCONST->LITERAL ( -- )
   LASTLIT @ LASTCHILD @ >BODY @ LASTLIT 2!
   ['] (LITERAL) XTHIST ! ;

not what's wanted; the literal isnt correct it is not a float!
---------------------------------------------------------------------- }

: NEW-FCONST ( -- )   [+ASM]
   LASTCHILD @ 5 + [EDI] QWORD FLD
   [-ASM] ;

OPTIMIZE ANY (fCONSTANT) WITH NEW-fCONST

optimizing-compiler +order

: new-findirect [+asm]
   lastchild @ >body @ origin - [edi] qword fld
   [-asm] ;

optimize any (findirect) with new-findirect

: findirect-plus [+asm]
   lastchild @ >body @ origin - [edi] qword fadd
   [-asm] ;

optimize new-findirect f+ with findirect-plus


PREVIOUS



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

====================================================================== }

: f(   [CHAR] ) SKIP-PAST ; IMMEDIATE

: f<= ( -- flag ) f( f1 f2 -- )   f> not ;
: f>= ( -- flag ) f( f1 f2 -- )   f< not ;
: f<> ( -- flag ) f( f1 f2 -- )   f= not ;

{ ========== floats on return stack ====================================
  These functions allow using the return stack as temporary storage
  for floating point numbers, just like >R etc do for integers

   F>R  ( -- ) f( r -- ) rs( -- r )   save a float on the return stack
   FR>  ( -- ) f( -- r ) rs( r -- )   get a float from the return stack
   FR@  ( -- ) f( -- r ) rs( r -- )   copy a float from the return stack

   FR@N ( n -- ) f( -- f )   copy the nth float from the return stack
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

icode fr!n ( n -- ) f( r -- )
   0 [esp] [ebx*8] qword fstp
   pop(ebx) ret end-code

icode fr@n ( n -- ) f( -- r )
   0 [esp] [ebx*8] qword fld
   pop(ebx)  ret end-code


{ ========== dot-s replacement =========================================
  The built-in .s can't print but 5 floats; we make it possible to
  print 6. We should be able to do all 8, but... time and money
====================================================================== }

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
\ support; optimization possible here

: indirect-fvalue ( addr <name> -- )   \ run: f( -- rval )
   create , does> @ f@ ;

====================================================================== }




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
dump fp data
====================================================================== }

: fdump ( addr len -- )
   0 ?do
      cr  10 0 do
         dup f@ (f.10.3) type space  1 floats +
      loop
   10 +loop drop cr ;

: f.14   14 6 (f.r.frac) type space ;

: fdots ( addr len -- )
   0 ?do
      dup f@ f.14 1 floats +
   loop drop ;

{ ======================================================================
replace the >FLOAT word in swiftforth, which is broken
====================================================================== }

-? : >FLOAT ( caddr n -- true | false ) ( -- r )
   DUP 0= IF NIP EXIT THEN
   R-BUF  -TRAILING R@ ZPLACE  R@ FCONVERT2 ( 0 | a\f ) IF
      R> ZCOUNT + = DUP ?EXIT FDROP EXIT
   THEN R> DROP 0 ;

