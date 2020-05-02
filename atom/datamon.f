{ ----------------------------------------------------------------------
Create a data monitoring window with personality for watching process
data in or during execution in other threads.  It is intended to be
for a pane of data whose format is static, it is not a "tty" window.

Rick VanNorman  26Apr2020  rick@neverslow.com
---------------------------------------------------------------------- }



gui-framework subclass datamon

   : MyWindow_Style ( -- style )
      WS_SYSMENU  WS_BORDER OR  WS_POPUP OR  WS_CAPTION OR
      WS_MINIMIZEBOX OR WS_THICKFRAME OR ;

   single hfont
   single charw
   single charh
   
   single xmax
   single ymax
   single measured    \ if true, xy extents of output are known

   textmetric builds tm

   single tbuf

   single cb-ref
   single cb-xt
   
   : set-callback ( object xt -- )   to cb-xt  to cb-ref ;
   : do-callback ( -- addr len )  cb-xt cb-ref >s execute s> ;

   : MyAppName ( -- z )   z" DataMonitor" ;

   : measure-font ( hdc -- )   tm addr GetTextMetrics drop
      tm height @ to charh    tm avecharwidth @ to charw ;

   : char>pixel ( x y -- x y )   >r charw * r> charh * ;
   
   defer: font ( -- [font descriptor] )   lucida-console-10 ;

   : init ( -- )
      font CreateFont to hfont
      dc hfont SelectObject drop   dc measure-font
      0 to measured  0 to xmax  0 to ymax
      100 100  2dup  to ysize  to xsize   resize-window
      mhwnd 99 100 0 settimer drop
      ;

   : measure-text ( len x y -- )
      ymax max  to ymax  +  xmax max to xmax ;

   : dot-text ( addr len x y -- )
      measured not if  3dup measure-text  then 
      2swap 2>r  2>r   dc  2r> char>pixel 2r> TextOut drop ;

   : print-column ( addr len x y -- )   locals| y x |
      begin ( a l)
         dup 0> while
         2dup eol-scanner >r
         third swap x y dot-text 1 +to y
         r> /string
      repeat 2drop ;

   : measured ( -- )
      measured not if
         xmax 3 + ymax 2+ char>pixel resize-window
         1 to measured
      then ;
   
   : redraw ( -- )   do-callback  2 2 print-column  measured ;

   WM_TIMER message:
      wparam loword case
         99 of redraw  endof
      endcase ;

end-class




