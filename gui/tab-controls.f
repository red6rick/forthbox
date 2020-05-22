{ ----------------------------------------------------------------------
Build a window with tabs.

The tab control, unlike the other "derived-control" children, doesn't
factor into an easily reusable subclass. I think each use will be
custom. This provides a template to build on.

Rick VanNorman  13May2020  rick@neverslow.com
---------------------------------------------------------------------- }

{ ----------------------------------------------------------------------
We assign a richedit control to each of the tabs; anything else could
be assigned. POST-MAKE is called after the tab control is instantiated
and creates all of the tab children. These determine the size of the
tab control so its parent can set it accordingly.
---------------------------------------------------------------------- }

mytabframework subclass mytabcontrol

   myrichbox builds:id zero
   myrichbox builds:id one
   myrichbox builds:id two

   : place-children ( x y -- X Y )
      2dup    zero placed      \ initial placement, 
      zero ul one  placed      \ others overlay its origin but 
      zero ul two  placed ;    \ might be a different size

   : make-tab-children ( -- )
      mhwnd 64 16 0 zero make   
      mhwnd 64 16 0 one  make   
      mhwnd 64 16 0 two  make ;

   : create-tabs ( -- )   make-tab-children
      zero mhwnd z" zero" new-tab   
      one  mhwnd z" one"  new-tab   
      two  mhwnd z" two"  new-tab   ;

   : post-make ( -- )   create-tabs
      mhwnd TCM_GETITEMRECT 0 pad SendMessage drop 
      5  pad 3 cells + @ 5 + ( place children below tab buttons)
      place-children to ysize to xsize
      0 show-tab ;

   : update ( -- )   selected  show-tab ;

end-class

{ ----------------------------------------------------------------------
Finally, we can define a framework and create a tab control in it.
---------------------------------------------------------------------- }

gui-framework subclass myapp
   : MyAppName ( -- z )   z" MyTabDemo" ;
   : MyClass_hbrBackground ( -- h )  COLOR_BTNFACE GetSysColorBrush ;
   
   mytabcontrol builds:id tabs

   : place-children ( x y -- X Y )
      2dup tabs placed ;

   : init-children ( -- )
      mhwnd 200 200 0 tabs make  ;

   : init ( -- )   init-children
      5 5 place-children  2dup to ysize  to xsize  resize-window ;

   : tab-notification ( notification -- )   
      case
         TCN_SELCHANGE   of  tabs update 0 endof
      endcase ;

   WM_NOTIFY message:
      lparam @ case 
         tabs mhwnd of  lparam 2 cells + @ tab-notification  endof
      endcase ;
 
end-class

myapp builds app
: go   app construct ;

