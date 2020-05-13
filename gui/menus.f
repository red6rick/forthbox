{ ----------------------------------------------------------------------
build a sample menu -- this should show the basics of menus,
and link into a do-nothing gui

Rick VanNorman  13May2020  rick@neverslow.com
---------------------------------------------------------------------- }


{ ----------------------------------------------------------------------
First, every menu item needs an application-unique identifier
These are in no particular order; sub-menus don't need ids.
MI_USER is a value; when done we update it for later use.
---------------------------------------------------------------------- }

MI_USER
   enum MI_OPEN
   enum MI_FONT
   enum MI_SAVE
   enum MI_COPY
   enum MI_PASTE
   enum MI_EXIT
   enum MI_ABOUT
to MI_USER

{ ----------------------------------------------------------------------
Next, we build the menu structure. Not a great compiler, but adequate
"&" defines a alt-activated hot keys which must be unique at the
level where defined.
---------------------------------------------------------------------- }

MENU MY-MENU

   POPUP "&File"
      MI_OPEN           MENUITEM "&Open"
      MI_SAVE           MENUITEM "&Save"
                                 ----
      MI_EXIT           MENUITEM "E&xit"
   END-POPUP

   POPUP "&Edit"
      MI_COPY           MENUITEM "&Copy"
      MI_PASTE          MENUITEM "&Paste"
                                 ----
      MI_FONT           MENUITEM "&Font"                                        
   END-POPUP

   POPUP "&Help"
      MI_ABOUT          MENUITEM "&About"
   END-POPUP

END-MENU

{ ----------------------------------------------------------------------
Finally, we can define a framework and hang the menu on it.
We will define only the exit behavior for now, but ...

HasMenu is the key here; it should return the defined menu that you
want to use for the framework.
---------------------------------------------------------------------- }

gui-framework subclass myapp
   : MyAppName ( -- z )   z" MyMenuDemo" ;
   : HasMenu ( -- menu )   my-menu ;
   MI_ABOUT command:
      mhwnd z" This is the about info" z" About" MB_OK MessageBox drop ;
   MI_EXIT command:
      mhwnd WM_CLOSE 0 0 SendMessage drop ;
end-class

myapp builds app
: go   app construct ;




