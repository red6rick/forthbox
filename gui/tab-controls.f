{ ----------------------------------------------------------------------
build a window with tabs

Rick VanNorman  13May2020  rick@neverslow.com
---------------------------------------------------------------------- }

: hide SW_HIDE ShowWindow drop ;
: show SW_SHOW ShowWindow drop ;

class TCITEM
   single mask
   single state
   single statemask
   single ztext
   single textmax
   single image
   single lparam
end-class   

derived-control subclass mytabcontrol
   : mywindow_classname WC_TABCONTROL ;
   : mywindow_style ( -- n )
      0 WS_CHILD OR
        WS_VISIBLE OR ;

   myrichbox builds:id zero
   myrichbox builds:id one
   myrichbox builds:id two

   tcitem builds ti
   
   : new-tab ( ztext index -- )   >r  to ti ztext
      TCIF_TEXT to ti mask 
      mhwnd TCM_INSERTITEMA r> ti addr sendmessage drop ;

   : place-children ( x y -- X Y )
      2dup zero placed
      zero ul one placed
      zero ul two placed ;

   : init-children ( -- )
      z" zero" 0 new-tab mhwnd  64 16 0 zero make   
      z" one"  1 new-tab mhwnd  64 16 1 one  make   
      z" two"  2 new-tab mhwnd  64 16 2 two  make   ;

   : post-make ( -- )
      init-children
      mhwnd TCM_GETITEMRECT 0 pad SendMessage drop
      pad @  pad 3 cells + @
      place-children to ysize to xsize ;
      
   : selected ( -- n )
      mhwnd TCM_GETCURSEL 0 0 SendMessage ;



end-class



{ ----------------------------------------------------------------------
Finally, we can define a framework and create a tab control in it.
---------------------------------------------------------------------- }

gui-framework subclass myapp
   : MyAppName ( -- z )   z" MyTabDemo" ;

   mytabcontrol builds:id tabs

\   : make-tabs ( -- )
\      TCIF_TEXT to ti mask  
\      z" zero" 0 new-tab
\      z" one"  1 new-tab
\      z" two"  2 new-tab ;

   : place-children ( x y -- X Y )
      2dup tabs placed ;

   : init-tabs ( -- )
      z" zero" 0 tabs new-tab  
      z" one"  1 tabs new-tab  
      z" two"  2 tabs new-tab ;

   : init-children ( -- )
      mhwnd 200 200 0 tabs make  ;

   : init ( -- )   init-children
      5 5 place-children  2dup to ysize  to xsize  resize-window ;

   : tab-notification ( notification -- )   
      case
         TCN_SELCHANGING of  tabs selected  0 endof \ 0=can change
         TCN_SELCHANGE   of  tabs selected  0 endof
      endcase ;

   WM_NOTIFY message:
      lparam @ case 
         tabs mhwnd of  lparam 2 cells + @ tab-notification  endof
      endcase ;
 
end-class

single one
single two
single zero

myapp builds app
: go   app construct
   app tabs one mhwnd to one
   app tabs two mhwnd to two
   app tabs zero mhwnd to zero
   ;

z" Msftedit.dll" loadlibrary drop




\ app tabs mhwnd constant z   
\ z z" RICHEDIT50W" 10 10 170 170 common-control   
\ z z" RICHEDIT50W" 10 10 170 170 common-control
\ restart
\ go
\ z" Msftedit.dll" loadlibrary drop
\ app tabs mhwnd constant z
\ z pad getclientrect
\ pad  16 idump
\ z TCM_ADJUSTRECT 0 pad sendmessage .
\ pad 16 idump
\ \ z z" RICHEDIT50W" 10 10 170 170 common-control
\ z z" RICHEDIT50W" 4 24 196 196 common-control





\ ----------------------------------------------------------------------
\\ \\\\ from microsoft
\\\ \\\ https://docs.microsoft.com/en-us/windows/win32/controls/create-a-tab-control-in-the-main-window
\\\\ \\ 
\\\\\ \ 


// Creates a child window (a static control) to occupy the tab control's 
//   display area. 
// Returns the handle to the static control. 
// hwndTab - handle of the tab control. 
// 
HWND DoCreateDisplayWindow(HWND hwndTab) 
{ 
    HWND hwndStatic = CreateWindow(WC_STATIC, L"", 
        WS_CHILD | WS_VISIBLE | WS_BORDER, 
        100, 100, 100, 100,        // Position and dimensions; example only.
        hwndTab, NULL, g_hInst,    // g_hInst is the global instance handle
        NULL); 
    return hwndStatic; 
}
