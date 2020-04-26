{ ----------------------------------------------------------------------
set emacs editor, just for me!
---------------------------------------------------------------------- }

FILE-VIEWER +ORDER

: use-emacs
   s" cmd.exe" editor-name zplace
   s\" /c c:\\emacs\\em.bat -n +%l \"%f\"" editor-options zplace
   0 USE-NOTEPAD ! ;

: use-npp
   this-exe-name -name here place
   s" \npp\npp.exe" here append
   here count editor-name zplace
   s" -n%l -lforth %f" editor-options zplace
   0 use-notepad ! ;

\ ----------------------------------------------------------------------

: em ( -- )
   0  bl word count
   2dup [char] . scan 0= nip if
      pad place  s" .f" pad append  pad count
   then edit-file ;

FILE-VIEWER -ORDER

: gx g ;
