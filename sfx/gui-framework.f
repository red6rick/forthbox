{ ========== gui-framework.f ===========================================

A window class extension for building user interfaces with
windows common controls and user defined "widgets"

(C) 2020 Rick VanNorman  -- rick@digital-sawdust.com  
====================================================================== }

gui-wrapper subclass gui-framework

   \ a non-resizeable window with a border

   : MyWindow_Style ( -- style )
      WS_SYSMENU  WS_BORDER OR  WS_POPUP OR  WS_CAPTION OR WS_MINIMIZEBOX OR ;

   : MyClass_hbrBackground ( -- hbrush )   WHITE_BRUSH GetStockObject ;

   single xsize
   single ysize

   defer: init  ;
   defer: repaint-widgets ;
   
   : %time ( -- )   @time (time) %type  s"   "  %type  ;
      
   : after-create ( -- )   mHWND GetDC to dc   init ;

{ ----------------------------------------------------------------------
 When we repaint the window, we will render all surfaces defined by
 REPAINT-WIDGETS

The HDC returned by BeginPaint isn't used -- we established a fixed
connection to the window's DC when the DIBs were initialized.
---------------------------------------------------------------------- }

   WM_PAINT MESSAGE: ( -- 0 )  
      mHWND PAD BeginPaint DROP
         repaint-widgets 
      mHWND PAD EndPaint DROP
      0 ;

end-class

