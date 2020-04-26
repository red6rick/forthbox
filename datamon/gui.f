{ ========== gui.f =====================================================
   (C) 2020 Stratolaunch LLC ---- 20Apr2020 rcw/rcvn

   SIMULATION-SERVER-CLASS

   This is the class which defines the overall simulator user interface.
   A static instance of it is created; when constructed, it will open
   a window for user monitoring of the simulator process

====================================================================== }

: measure-font ( font-descriptor -- )
   CreateFont
   GetDesktopWindow GetDC
   CreateCompatibleDC           \ hfont dc
   dup third SelectObject drop  \ hfont dc
   dup pad GetTextMetrics drop  \
   DeleteDC drop
   DeleteObject drop ;



gui-framework subclass simulation-client-class

   : MyWindow_Style ( -- style )
      WS_SYSMENU  WS_BORDER OR  WS_POPUP OR  WS_CAPTION OR
      WS_MINIMIZEBOX OR WS_THICKFRAME OR ;
   

   single hdc
   single hfont
   single charw
   single charh
   
   single xmax
   single ymax
   single measured

   textmetric builds tm

   : MyAppName ( -- z )   z" Bravo Client" ;

   : measure-font ( hdc -- )         \ measure the chars in the dc
      tm addr GetTextMetrics drop
      tm height @ to charh
      tm avecharwidth @ to charw ;

   : char>pixel ( x y -- x y )   >r charw * r> charh * ;
   
   : init ( -- )
      mhwnd getdc to hdc
      lucida-console-10 CreateFont to hfont
      hdc hfont SelectObject drop
      hdc measure-font
      0 to measured  0 to xmax  0 to ymax
      100 100  2dup  to ysize  to xsize   resize-window
      mhwnd 99 20 0 settimer drop
      ;

   : measure-text ( len x y -- )
      ymax max  to ymax  +  xmax max to xmax ;

   : dot-text ( addr len x y -- )
      measured not if  3dup measure-text  then 
      2swap 2>r  2>r   hdc  2r> char>pixel 2r> TextOut drop ;

   : print-column ( addr len x y -- )   locals| y x |
      begin ( a l)
         dup 0> while
         2dup eol-scanner >r
         third swap x y dot-text 1 +to y
         r> /string
      repeat 2drop ;
   
   : redraw ( -- )
      hr fmt  3  1 print-column   
      tc fmt  3  4 print-column   
      tr fmt  3 14 print-column  
      ac fmt 30  1 print-column  
      ar fmt 60  1 print-column 
      wc fmt 30 20 print-column 
      measured not if
         xmax 3 + ymax 2+ char>pixel resize-window
         1 to measured
      then ;

   4 cells buffer: myrect

   WM_TIMER message:
      wparam loword case
         99 of redraw  endof
      endcase ;

end-class




