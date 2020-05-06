{ ----------------------------------------------------------------------
build a test gui for the toolwin

Rick VanNorman   4May2020  rick@neverslow.com
---------------------------------------------------------------------- }

requires rnd

\ ----------------------------------------------------------------------

class text-pane

   single buf
   single xsize
   single ysize
   single bytes

   : ?nopane ( x y -- )   0= swap 0= or
      z" text-pane: x and y must be non-zero" ?throw ;

   : offpane? ( x y -- flag )
      ysize 0 within  swap xsize 0 within or ;

   : resize ( x y -- )   2dup ?nopane  buf free drop
      2dup * to bytes  to ysize  to xsize   0 to buf
      bytes allocate z" allocate filed in text-pane" ?throw to buf ;

   : clear ( -- )   buf bytes blank ;

   : xypos ( x y -- addr )   xsize * + buf + ;

   : #eol ( x -- n )   xsize swap - ;

   : xy-type ( addr len x y -- )
      2dup offpane? if  2drop 2drop exit then
      >r dup >r  #eol min   r> r> xypos swap cmove ;

   : xy-types ( addr len x y -- )   locals| y x |
      begin ( a l)
         dup 0> while
         2dup eol-scanner >r
         third swap x y xy-type 1 +to y
         r> /string
      repeat 2drop ;

   : dot
      xsize ysize ?nopane
      buf ysize 0 do
         cr  dup xsize -trailing type  xsize +
      loop drop cr ;

   : get-line ( n -- addr len )
      0 swap  2dup offpane? if 2drop buf 0 exit then
      xypos  xsize ;

   : get-lines ( -- n )   ysize ;
   : get-cols  ( -- n )   xsize ;
   : get-bytes ( -- n )   bytes ;

   : xy-emit ( char x y -- )
      2dup offpane? if 2drop drop exit then  xypos c! ;
      

end-class

\ ----------------------------------------------------------------------

myctext subclass myflatbutton
   : mywindow__style WS_CHILD WS_VISIBLE or SS_BITMAP or ;
   single pressed
   single down-color
   single up-color
   
   single xoffset
   single yoffset
   single wide
   
   4 constant margin

   256 buffer: text
   
   : thecolor ( -- color )
      pressed if down-color else up-color then  ;

   : draw-button ( -- )
      hdc thecolor  SetBkColor drop
      hdc xoffset yoffset ETO_OPAQUE
      here mhwnd over GetClientRect drop  
      text count  0 ExtTextOut DROP ;


   : release ( -- )   pressed -exit   0 to pressed  draw-button ;
   : press   ( -- )   pressed ?exit   1 to pressed  draw-button ;

   : re-text ( -- )
      mhwnd text 1+ 254 GetWindowText wide min  text c!
      xsize  text c@ charw *  - 2/  to xoffset ; 

   : set-text ( z -- )
      mhwnd swap SetWindowText drop  re-text  draw-button ;

   : post-make ( -- )
      xsize to wide   margin to yoffset
      xsize charw *  margin 2* + to xsize
      ysize charh *  margin 2* + to ysize      
      $c0ffff to down-color  $ffc0ff to up-color
      re-text draw-button ;

   WM_PAINT MESSAGE: ( -- 0 )
      mHWND PAD BeginPaint DROP
         draw-button
      mHWND PAD EndPaint DROP ;

end-class

\ ----------------------------------------------------------------------

derived-control subclass mytextpane
   : mywindow_classname z" STATIC" ;
   : mywindow__style WS_CHILD WS_VISIBLE or SS_BITMAP or ;

   single xmax
   single ymax
   single measured

   text-pane builds stars

   : font ( -- hfont )   lucida-console-12 CreateFont ;

   : measure-text ( len x y -- )
      ymax max  to ymax  +  xmax max to xmax ;

   : char>pixel ( x y -- x y )   >r charw * r> charh * ;
   
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

   single timer

   : rate ( ms -- )   mhwnd 99 rot 0 settimer drop ;

   : stop   mhwnd 99 killtimer drop ;
   : start  timer rate ;
   : slower  timer 50 + 1000 min to timer  start ;
   : faster  timer 50 -   50 max to timer  start ;
   
   : post-make ( -- )
      50 to timer 
      xsize ysize stars resize
      xsize charw *  to xsize  ysize charh * to ysize
      start ;

   : starfield ( -- )
      stars clear
      200 0 do
         [char] * 
         stars get-cols rnd  stars get-lines rnd  stars xy-emit
      loop ;
   
   : render ( -- )
      ysize 0 do
         i stars get-line  0 i dot-text
      loop ;
 
   WM_TIMER message:
      starfield render ;

   WM_PAINT MESSAGE: ( -- 0 )
      mHWND PAD BeginPaint DROP
         render
      mHWND PAD EndPaint DROP ;

   : lbutton ( -- )
      operator's ." press" ;

end-class


gui-framework subclass toolwin-class

   : myappname ( -- z )   z" toolwin" ;

   myflatbutton builds:id button1
   myflatbutton builds:id button2
   myflatbutton builds:id button3
   myflatbutton builds:id button4
   mytextpane builds:id pane

   : place-children ( x y -- X Y )
      2dup button1 placed
      button1 ur button2 placed
      button2 ur button3 placed
      button3 ur button4 placed
      button1 ll pane placed ;

   : init-widgets ( -- )
      mhwnd  16 1  z" stop"    button1 make
      mhwnd  16 1  z" start"   button2 make
      mhwnd  16 1  z" slower"  button3 make
      mhwnd  16 1  z" faster"  button4 make
      mhwnd  64  16  0           pane make ;

   : init ( -- )   init-widgets
     5 5 place-children  2dup to ysize  to xsize  resize-window
     button1 press
     ;

   id_button1 command:   pane stop ;
   id_button2 command:   pane start ;
   id_button3 command:   pane slower ;
   id_button4 command:   pane faster ;

   : release ( -- )
      button1 release  button2 release  button3 release  button4 release ;


   WM_LBUTTONUP message:
      lparam lohi ( x y)
         pane clicked? if  pane lbutton  exit  then
         button1 clicked? if  release  button1 press  exit  then
         button2 clicked? if  release  button2 press  exit  then
         button3 clicked? if  release  button3 press  exit  then
         button4 clicked? if  release  button4 press  exit  then
      2drop ;
   
end-class

