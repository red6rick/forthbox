{ ----------------------------------------------------------------------
Extended print utility; accumulate (build) longer formatted strings
for single write operations. Various formats available.
10feb2020rcvn

(.R) ( n u -- addr len )
   format the integer n right-justified in a field u chars wide.
(DDMMMYYYY) ( u1 -- c-addr u2)
   format date in an unambiguous manner
<%  ( -- )            begin a formatted string
%>  ( -- addr len )   end formatted string, return address and length
Z%> ( -- zaddr )      end and return zero terminated string

... to the output buffer ...

%TYPE   ( a len -- )     add a string 
%DU.    ( d -- )         add an unsigned double integer
%U.R    ( u n -- )       add a right justified unsigned integer
%.R     ( n n -- )       add a right justified signed integer
%.      ( n --  )        add a default formatted signed integer
%U.     ( u --  )        add a default formatted unsigned integer
%EMIT   ( char --  )     add a character
%H.0    ( u n --  )      add a hex number left padded with zeros
%B.0    ( u n --  )      add a binary number left padded with zeros
%H.     ( u --  )        add a default formatted hex number
%04H.   ( u --  )        add a hex number in a 4 wide field
%08H.   ( u --  )        add a hex number in a 8 wide field
%X.     ( u --  )        add a hex number with a "0x" prefix
%BL     ( --  )          add a blank
%TAB    ( --  )          add a tab
%HHMMSS ( h m s -- )     add a time string
%BLANKS ( n --  )        add the number of blanks
%TYPE.R ( a len n -- )   add a string right justified in a field
%TYPE.L ( a len n -- )   add a string left justified in a field
%"      ( "ccc<">" --  ) add a string like ." -- same as s" asdf" %type
---------------------------------------------------------------------- }

: (.R) ( n n -- addr len )
   >R (.) R@ OVER - 0 MAX 0 ?DO BL HOLD LOOP #> R> MIN ;

: (DDMMMYYYY) ( u1 -- c-addr u2)   BASE @ >R  DECIMAL  Y-DD
   ROT 0 <#  # # # #  2DROP    DM 3 *
   C" JanFebMarAprMayJunJulAugSepOctNovDec" +
   3 0 DO  DUP C@ HOLD 1-  LOOP DROP
   0 # #  #>  R> BASE ! ;

{ ----------------------------------------------------------------------
really needed a new # word for printing...
---------------------------------------------------------------------- }

: ?# ( d -- d )
   2dup d0= if bl hold else # then ;

: #str ( -- )
   bounds swap ?do i c@ hold -1 +loop ;

{ ----------------------------------------------------------------------
for creating formatted strings

note the -? for <% and %>. these mask an existing swiftforth function
set (locate %BUF for that source code) which isn't used and really isn't
very useful but can't be removed because someone somewhere might be
using it.
---------------------------------------------------------------------- }

-? : <% ( -- )   0 pad ! ;
-? : %> ( -- addr len )   pad @+ ;

: %type   ( addr len -- )   pad xappend ;

: %du. ( d -- )   (du.) %type ;
: %u.r ( u n -- )   (u.r) %type ;
: %.r ( n n -- )   (.r) %type ;
: %. ( n -- )   (.) %type ;
: %u. ( u -- )   0 %du. ;
: %emit ( char -- )   sp@ 1 %type drop ;
: %.0 ( u n -- )   (.0) %type ;
: %h.0 ( u n -- )   (h.0) %type ;
: %b.0 ( u n -- )   (b.0) %type ;
: %h. ( u -- )   4 %h.0 bl %emit ;
: %04h. ( u -- )   4 %h.0 bl %emit ;
: %08h. ( u -- )   8 %h.0 bl %emit ;
: %x. ( u -- )   s" 0x" %type %h. ;
-? : %spaces ( n -- )   0 ?do bl %emit loop ;
-? : %cr ( -- )   <eol> count %type ;
: %bl ( -- )   bl %emit ;
: %tab ( -- )   9 %emit ;

: %hhmmss ( h m s -- )
   <#   0 # # 2drop [char] : hold
        0 # # 2drop [char] : hold
        0 # #
   #> %type ;

: %blanks ( n -- )   0 ?do bl %emit loop ;

: (%padding) ( len field -- len field )
   dup >r min r>  over - 0 max ;

: %type.r ( addr len field -- )
   (%padding)  %blanks  pad xappend ;

: %type.l ( addr len field -- )
   (%padding) >r  pad xappend  r> %blanks  ;

: %"  \ compiling: ( "ccc<">" -- )  executing: ( -- )
   POSTPONE S" POSTPONE %type ;  IMMEDIATE

: z%> ( -- zaddr )   0 %emit  pad cell+ ;
