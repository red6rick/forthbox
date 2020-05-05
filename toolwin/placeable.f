{ ----------------------------------------------------------------------
a placeable window conforms to the placement pseudo-standard for
swiftforth class-based window applications

Rick VanNorman   4May2020  rick@neverslow.com
---------------------------------------------------------------------- }

childwindow subclass placeable-window

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

   : make ( hwnd xsize ysize zname -- )
      pre-make
      >r  sized  attach   r> title
      addr  hparent WM_GETBASEADDR 0 0 SendMessage  -  to id
      mhwnd getdc to hdc
      font ?dup if  dup to hfont  set-font  then  measure-font
      post-make ;

   : get-ztext ( addr len -- len )
      1- mhwnd pad rot GetWindowText  pad over fourth zplace  nip ;

end-class
