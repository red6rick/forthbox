{ ----------------------------------------------------------------------
This technique allows a class member to set a callback for another
object to execute. This is useful for defining data output routines
that are generic but need a reference to the object that contains them.

The only code actually needed that is common enough to import
are the functions to get a true execution token for a class member.
This assumes a reference in the class where you want the reference

A simple example is included.

Rick VanNorman   1May2020  rick@neverslow.com
---------------------------------------------------------------------- }

oop +order

: 'member-xt ( <name> -- xt )
   'member 0= abort" member undefined"
   class-member? 0= abort" not member of class"
   3 cells + @ ;
   
: ['member-xt] ( <name> -- )   
   'member-xt postpone literal ; immediate
   
previous

\ ----------------------------------------------------------------------
\ test the callback mechanism; the datamon is a good test bed but
\ too complicated for an informative example. the callback
\ presented here returns a formatted string to be displayed

gui-framework subclass simplemon
   single hdc
   : MyAppName ( -- z )   z" DataMonitor" ;

   single cb-ref
   single cb-xt
   : set-callback ( object xt -- )   to cb-xt  to cb-ref ;
   : do-callback ( -- addr len )  cb-xt cb-ref >s execute s> ;

   : dot-text ( -- )   hdc 0 0 do-callback TextOut drop ;

   : init ( -- )   mhwnd GetDC to hdc
      mhwnd 99 100 0 settimer drop  ;

   WM_TIMER message:  dot-text ;
end-class

class point
   single x
   single y
   simplemon builds mon
   : dot ( addr len -- )   <%  x 4 %.0  %bl  y 4 %.0  %> ;
   : init ( -- )   addr ['member-xt] dot  mon set-callback
      mon construct  mon init ;
end-class

point builds pt1  pt1 init
25 to pt1 x  1234 to pt1 y
requires rnd
requires fork
: test forks> begin
      1000 rnd to pt1 x  1000 rnd to pt1 y  200 sleep drop
   again ;
