{ ========== infopane.f ================================================
   (C) 2020 Stratolaunch LLC ---- 20Apr2020 rcw/rcvn

   INFO-PANEL

   A class defining the behavior of a panel of arbitrary text which
   the controller can render at will. It participates in the size and
   position paradigm, and can be drawn on etc at need.

   Methods:
   
   PRINT ( addr len x y -- )
   Display a line of text at the logical character-based xy coordinate

   CPRINT ( addr len x y colorndx -- )
   Same as print, but with a selected color

   TYPE ( addr len -- )
   Clear the area, then proceed to print text from edge to edge, wrapping
   as needed

   TYPES ( addr len -- )
   Similar to TYPE, but doesn't wrap. Text falls off the right edge of
   the control, and next line is reached on CRLF
   
====================================================================== }

widget subclass info-panel

   single cols
   single rows

   : attach ( dc -- )   to hdc   10 10 hdc create ;

   : +border ( n -- n )   hide-borders ?exit border + ;

   : set-size ( x y -- )   to rows to cols ;

   : sized ( x y -- )   image destroy-dib
      dup to rows  charh * +border to ysize
      dup to cols  charw * +border to xsize
      xsize ysize hdc create ;

   : borderless ( x y -- )   no-border  sized ;

   : ypx ( y -- pixel )   rows mod charh * ;
   : xpx ( x -- pixel )   cols mod charw * ;
   
   : xy->point ( x y -- x y )   ypx swap  xpx swap  margin dup v+ ;

   : print ( addr len x y -- )   xy->point 2swap print-xy ;

   : cprint ( addr len x y color -- )   >r xy->point 2swap r> cprint-xy ;

   : type ( addr len -- )
      clear rows 0 do
         dup 0> if
            over cols 0 i print  cols /string
         then
      loop 2drop ;

   : type-line ( addr len line -- ADDR LEN )
      >r  over >r [ctrl] m scan  r> third over -
      cols min  0 max  0 r> print  2 /string  0 max ; 

   : type-lines ( addr len -- )   rows 0 do  i type-line  loop 2drop  ;   

   : types ( addr len -- )    type-lines ;

end-class
