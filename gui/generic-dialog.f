{ ----------------------------------------------------------------------
a simple example of using the genericdialog class

Rick VanNorman   8May2020  rick@neverslow.com
---------------------------------------------------------------------- }

dialog dialog-template
[modeless  " SIMPLE TEST" 10 10 50 50 (FONT 8, MS Sans Serif) (CLASS SFDLG)  ]
   [pushbutton     " Cancel" IDCANCEL  5  5 40 15 ]
   [defpushbutton  " OK"     IDOK      5 25 40 15 ]
end-dialog 

genericdialog subclass dialog-test
   : save-dialog-position 1 ;
   : template ( -- a )   dialog-template ;
   : finished ( -- )  0 close-dialog ;
   IDOK command: ( -- )   finished ;
end-class

dialog-test builds foo
: zot 0 foo modeless drop ;

: zam dialog-test new >r
   using dialog-test  0 r@ modeless drop
   r> free drop ;

\ ----------------------------------------------------------------------
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 


   : (BMPHANDLE) ( -- )
      hDC @ CreateCompatibleDC hMemDC !
      hDC @ Width @ Height @
         CreateCompatibleBitmap hBitmap !
      hMemDC @ hBitmap @ SelectObject hOldBitmap !
      hMemDC @ hBitmap @ 0 Height @ Data InfoHeader
         DIB_RGB_COLORS SetDIBits DROP
      hMemDC @ hOldBitmap @ SelectObject DROP
      hMemDC @ DeleteDC DROP ;

   : RENDER ( bitmap-addr -- ) BMP!
      (BMPHANDLE)
      Palette? IF
         hDC @ hPalette @ 0 SelectPalette
         hOldPalette !
         hDC @ RealizePalette DROP
      THEN
      hDC @ CreateCompatibleDC hMemDC !
      hMemDC @ hBitmap @ SelectObject hOldBitmap !
      hDC @ X @ Y @ Width @ Height @ hMemDC @
         0 0 SRCCOPY BitBlt DROP
      hMemDC @ hOldBitmap @ SelectObject DROP
      Palette? IF
         hDC @ hOldPalette @ 0 SelectPalette DROP
      THEN
      hMemDC @ DeleteDC DROP
      Palette? IF  hPalette @ DeleteObject DROP  THEN
      hBitmap @ DeleteObject DROP ;
