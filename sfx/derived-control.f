{ ========== derived-controls.f ========================================

Define a window subclass to make using a windows standard control
such as a button or listbox as a child in a GUI-FRAMEWORK defined
window class/object.

Various derived controls are defined here, added as needed.

(C) 2020 Rick VanNorman  -- rick@digital-sawdust.com  
====================================================================== }

class reflected-message
   single hwnd
   single msg
   single wparam
   single lparam

   : capture ( hwnd msg wparam lparam -- )
      to lparam  to wparam  to msg  to hwnd ;

end-class

derivedwindow subclass derived-control

   single x             \ where in the device context to
   single y             \ actually draw the image
   single xsize         \ size to draw
   single ysize         \

   single id            \ control id for forwarded messages
   single hdc
   single charw
   single charh
   single high
   single wide

   reflected-message builds reflected

   2 constant margin   ( match surface)
   margin 2* constant border

{ ----------------------------------------------------------------------
control placement of surface objects
---------------------------------------------------------------------- }

   : xr ( -- x )   x xsize + border + ;
   : yb ( -- y )   y ysize + border + ;

   : ul ( -- x y )   x  y  ;
   : ur ( -- x y )   xr y  ;
   : lr ( -- x y )   xr yb ;
   : ll ( -- x y )   x  yb ;

   : below ( -- x y )   ll ;
   : beside ( -- x y )   ur ;

   : mywindow_shape ( -- x y cx cy )   0 0 100 20 ;

   textmetric builds tm

   : measure-font ( -- )
      hdc tm addr GetTextMetrics drop
      tm height @ to charh
      tm avecharwidth @ to charw ;

   : measure-client ( -- )
      mhwnd pad GetClientRect drop  pad 2 cells + @+ to wide  @ to high ;

   defer: pre-make ;
   defer: post-make ;
   defer: pre-placed ;
   defer: post-placed ;

   \ x and y are where you were told to be
   \ maxes are max of both values

   : placed ( xmax ymax x y -- xmax ymax )
      pre-placed
      to y to x  lr rot max >r  max r>
      x y xsize ysize resize   measure-client
      post-placed ;

   : sized ( xsize ysize -- )   to ysize to xsize  ;

   : title ( zstr -- )   mhwnd swap SetWindowText drop ;

   defer: font ( -- hfont )   lucida-console-10 CreateFont ;

   single hfont

   : set-font ( hfont -- )   to hfont
      mhwnd WM_SETFONT hfont 0 SendMessage drop
      hdc hfont SelectObject drop ;

   : make ( hwnd id xsize ysize zname -- )
      pre-make
      >r  sized  attach   r> title
      addr  hparent WM_GETBASEADDR 0 0 SendMessage  -  to id
      mhwnd getdc to hdc  
      font ?dup if  dup to hfont  set-font  then  measure-font   
      post-make ;

   : reflect ( -- )
      hwnd msg wparam lparam reflected capture
      hparent WM_COMMAND  msg >h<  id or  mhwnd SendMessage ;      

   : get-ztext ( addr len -- len )
      1- mhwnd pad rot GetWindowText  pad over fourth zplace  nip ;
   : set-ztext ( z -- )
      mhwnd swap SetWindowText drop ;
   : set-text ( addr len -- )
      r-buf  r@ zplace  r> set-ztext ;

end-class

{ ======================================================================
Create derived controls as needed; append here. These serve as much
as examples as useful derivations. The subclassing of a derived
control allows access to things that are ordinarilly more difficult
to do in the win32 api
====================================================================== }


{ ========== user defined button behavior ==============================

A simple user button; the WM_LBUTTONDOWN message handler is
commented out as not generally useful, but left in as an example
of what is easy to get to when needed for user behavior

MYWINDOW_CLASSNAME is required; almost all other things can be
defaulted and defined as needed by the actual program use.

====================================================================== }

derived-control subclass mybutton
   : mywindow_classname z" BUTTON" ;

    WM_LBUTTONDOWN    message:  defproc  reflect ;
    WM_RBUTTONDOWN    message:  defproc  reflect ;   
 
end-class

derived-control subclass mystatic
   : mywindow_classname z" STATIC" ;
end-class

mystatic subclass myltext      \ left justified; alias
end-class

mystatic subclass myrtext     \ right justified
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        SS_RIGHT or ;
end-class

mystatic subclass myctext     \ right justified
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        SS_CENTER or ;
end-class

\ ======================================================================

derived-control subclass mylistbox
   : mywindow_classname z" LISTBOX" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        LBS_NOINTEGRALHEIGHT OR
        WS_VSCROLL OR
        WS_HSCROLL OR ;
   : TYPE ( addr len -- )   R-BUF R@ ZPLACE  
      mHWND LB_ADDSTRING 0 R> :: SendMessage DROP
      mHWND LB_GETCOUNT 0 0 :: SendMessage 500 > IF
         mHWND LB_DELETESTRING 0 0 :: SendMessage DROP
      THEN
      mHWND LB_GETCOUNT 0 0 :: SendMessage 1- 
      mHWND LB_SETCURSEL ROT 0 :: SendMessage DROP ;
end-class

\ ======================================================================

derived-control subclass myeditbox
   : mywindow_classname z" EDIT" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        WS_THICKFRAME or
        ES_RIGHT or ;
end-class    

myeditbox subclass mynumberbox
   : mywindow_classname
      z" Msftedit.dll" loadlibrary drop
      z" RICHEDIT50W" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        WS_EX_STATICEDGE or
        ES_RIGHT or ;
   WM_CHAR message:
      defproc  wparam 13 = if  reflect  then ;
   : post-placed ( -- )
      mhwnd EM_GETRECT 0 pad SendMessage drop
      high tm ascent @ - 2/ pad cell+ +!
      charh negate pad 2 cells + +!
      mhwnd EM_SETRECT 0 pad SendMessage drop ;
   : get-float ( -- ) f( -- rval )
      pad dup 32 get-ztext >float ?exit  0.0e0 ;
   : set-float ( -- ) f( rval -- )
      (f.3) set-text ;
end-class    

\ ======================================================================

derived-control subclass mygroupbox
   : mywindow_classname z" BUTTON" ;
   : mywindow_style ( -- n )
      0 WS_VISIBLE or  WS_CHILD or  BS_GROUPBOX or ;
   : surrounds ( xmax ymax x y -- xmax ymax )
      third over max >r  fourth third  max >r
      y - to ysize  x - to xsize
      mhwnd  HWND_BOTTOM x y xsize ysize  SWP_NOMOVE SetWindowPos drop
      r> border + r>  border + ;
end-class    
