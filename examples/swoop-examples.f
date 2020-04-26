{ ----------------------------------------------------------------------
Examples of use of obscure but useful Swoop features in SwiftForth

Rick VanNorman  26apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

\ ----------------------------------------------------------------------
\ using "using" -- invoke a class method on an address, once.

: measure-font ( [font-descriptor] -- )
   CreateFont   GetDesktopWindow GetDC
   CreateCompatibleDC           \ hfont dc
   dup third SelectObject drop  \ hfont dc
   dup pad GetTextMetrics drop  \
   DeleteDC drop  DeleteObject drop
   using textmetric   pad height @
   using textmetric   pad avecharwidth @ ;   

: lucida-console-14  -19 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;

\ lucida-console-14 measure-font . .
