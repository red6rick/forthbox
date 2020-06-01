\ {: writes the deepest element on return stack first
\ locals| writes the shallowest element first
\ no manipulation can make binary equivalent definitions'
\ but 1 and 3 are same except for the initial writing offsets

{ ========== indexed-loops.f ===========================================
  (C) 2020 Stratolaunch LLC ----  8Mar2020 rcw/rcvn

  Local indices for do loops. Takes advantage of the local variable
  allocation methods and allows do loops to have locally-scoped
  named indices. To use, a local variable MUST be declared via
  any normally accepted method. The local variable is available for
  normal use prior to the DO( invocation, but never afterward and so
  is discouraged completely. Examples of use below the fold
====================================================================== }

LOCAL-VARIABLE reopen

   : fetch-ndx ( -- n )
      [+asm]
         push(ebx)
         'lf [u] eax mov
         spot @ [eax] eax mov           \ get remembed stack pointer
         -4 [eax] ebx mov               \ find and calculate do loop
         -8 [eax] ebx add               \ index, just like I and J
      [-asm] ;

   : init-ndx ( -- )   [+asm]           \ remember stack pointer
         'lf [u] eax mov
         esp spot @ [eax] mov
      [-asm] ;

end-class  local-variable relink

\ ======================================================================

\ since the local-variables clas is only used once as a static
\ instance, the extra resource we need for the named loop indices
\ can be a static array EXTERNAL to the class.  not very pretty, but
\ possibly better than redefining all the lvar-comp references just to
\ have the buffer

lobj-comp #n buffer: lobj-comp-ndxes

local-variables reopen

   : ndxes ( -- a )   lobj-comp-ndxes ;

   : show ( -- )
      n @ 0 do i pool[] name count type space loop ;

   \ replace the old REFERENCE method with one that compiles
   \ loop index references as well as local variable references

   : new-reference ( n -- )
      dup ndxes + c@ if  pool[] fetch-ndx  else  pool[] fetch  then ;

   : becomes-ndx ( -- flag )
      local? dup if             \ if local name defined
         1 third ndxes + c!     \ flag it as an index
         swap pool[] init-ndx   \ and compile initialization code
      then ;

end-class  local-variables relink

\ ======================================================================

: search-local-space-ndxes ( c-addr len -- 0 | xt flag )
   state @ if
      members ?order >r  lobj-comp any? if
         2dup lobj-comp find-name if
            nip nip lobj-comp reference ( class) >this +members
            r> drop  ['] noop 1  exit
         then
      then
      lvar-comp any? if
         2dup lvar-comp find-name if
            nip nip lvar-comp new-reference
            r> if +members then  ['] noop 1  exit
         then
      then
      r> if +members then
   then 2drop 0 ;

' search-local-space-ndxes is (findext)

{ ----------------------------------------------------------------------
define a named local variable index for a loop
requires that a local variable already exist, and from the
point index: is used, the variable represents the loop index
not any previous local value.... an example:

: test   0 0 locals| xx yy |
   index: xx  10 0 do
      index: yy  8 0 do
         cr xx . yy . ." <=> " j . i .
      loop
   loop ;
---------------------------------------------------------------------- }


: index: ( -- )
   lvar-comp becomes-ndx 0= abort" no local variable for ndx:" ; immediate

\   bl peek-word  count over c@ [char] ? = if  1 /string then
\   s" do" compare(nc) abort" missing 'do' or '?do'" ;  immediate
\ 
\ : do: ( -- flag addr)
\    lvar-comp becomes-ndx  0= abort" no local variable"
\    postpone (do) 0 (begin) ; immediate
\ 
\ : ?do: ( -- addr1 flag addr2)
\    lvar-comp becomes-ndx  0= abort" no local variable"
\    postpone (?do) (begin)
\    postpone (do) 1  (begin) ;  immediate


\ ======================================================================
\ initialization via system hook!

: clear-locals-indices ( -- )
   lobj-comp clear  lobj-comp-ndxes #locals erase 
   lvar-comp clear ;

' clear-locals-indices is /locals




\ ======================================================================
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 

: test
   0 0 locals| rows cols |
   4 0 index: rows do
      cr  6 0 index: cols do
         rows . cols . ." | "
      loop
   loop ;
   
