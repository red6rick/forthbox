{ ----------------------------------------------------------------------
a simple example of using the genericdialog class

Rick VanNorman   8May2020  rick@neverslow.com
---------------------------------------------------------------------- }

s" foo.bmp" bmp image

gui-framework subclass window-test
   : myappname ( -- z )   z" test" ;

   mybmp  builds:id logo

   : place-children ( x y -- X Y )
      2dup         logo placed ;

   : init-children ( -- )
      mhwnd 640 350  0                logo      make
      ;

   : init  init-children  5 5 place-children  
      2dup to ysize  to xsize  resize-window ;

end-class

window-test builds bar
image bar logo set-image
: go bar construct ;

\ ----------------------------------------------------------------------
\ ----------------------------------------------------------------------
\ ----------------------------------------------------------------------

dialog dialog-template
[modeless  " SIMPLE TEST" 10 10 700 400 (FONT 8, MS Sans Serif) (CLASS SFDLG)  ]
   [pushbutton     " Cancel" IDCANCEL  5  5 40 15 ]
   [defpushbutton  " OK"     IDOK      5 25 40 15 ]
   [static id: photo   5  20 210 75 (+STYLE SS_OWNERDRAW) (-STYLE WS_BORDER) ]   
end-dialog 

genericdialog subclass dialog-test
   : save-dialog-position 1 ;
   : template ( -- a )   dialog-template ;
   : finished ( -- )  0 close-dialog ;
   IDOK command: ( -- )   finished ;
   WM_DRAWITEM message:
      (o bitmap: bm )
      image  lparam 5 cells + @  bm centered 0 ;
end-class

dialog-test builds foo
: zot 0 foo modeless drop ;

: zam dialog-test new >r
   using dialog-test  0 r@ modeless drop
   r> free drop ;
