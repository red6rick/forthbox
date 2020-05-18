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

derived-control subclass mytabcontrol
   : mywindow_classname WC_TABCONTROL ;
   : mywindow_style ( -- n )
      0 WS_CHILD OR
        WS_VISIBLE OR ;

   myrichbox builds:id zero
   myrichbox builds:id one
   myrichbox builds:id two

   : new-tab ( ztext index -- )   >r
      here 3 cells + !  TCIF_TEXT here !
      mhwnd TCM_INSERTITEMA r> here sendmessage drop ;

   : place-children ( x y -- X Y )
      2dup    zero placed      \ initial placement, 
      zero ul one  placed      \ others overlay its origin but 
      zero ul two  placed ;    \ might be a different size

   : create-tabs ( -- )   
      z" Msftedit.dll" loadlibrary drop 
      z" zero" 0 new-tab   mhwnd 64 16 0 zero make   
      z" one"  1 new-tab   mhwnd 64 16 0 one  make   
      z" two"  2 new-tab   mhwnd 64 16 0 two  make   ;

   : hideall ( -- )
      zero hide one hide two hide ;

   : select-tab ( n -- )
      mhwnd TCM_SETCURSEL rot 0 SendMessage drop ;
      
   : show-content ( n -- )
      hideall case
         0 of  zero show  endof
         1 of  one  show  endof
         2 of  two  show  endof
      endcase ;

   : selected ( -- n )
      mhwnd TCM_GETCURSEL 0 0 SendMessage ;

   : post-make ( -- )   create-tabs
      mhwnd TCM_GETITEMRECT 0 pad SendMessage drop 
      5  pad 3 cells + @ 5 + ( place children below tab buttons)
      place-children to ysize to xsize
      selected show-content ;

   : update ( -- )   selected  show-content ;

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

