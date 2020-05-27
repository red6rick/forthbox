{ ========== eol-scanner.f =============================================
   (C) 2020 Stratolaunch LLC ---- 27May2020 rcw/rcvn

   a better eol scanner for large files...
====================================================================== }


{ ----------------------------------------------------------------------
EOL-SCANNER is used by the SwiftForth kernel function READ-LINE to
extract lines from a file one at a time. Its current implemention
is shown here:

: EOL-SCANNER ( addr n -- got #adv )
   2DUP <CR> SCAN IF                \ found CR
      NIP SWAP DUP ROT
      OVER - 2+ <LF> SCAN           \ check for LF before/behind CR
      2 MIN                         \ 0=CR; 1=CR/LF; 2=LF
      -ROT  SWAP -  OVER 2-  +      \ calculate got
      DUP 2+  ROT 1-  0<>  +        \ calculate #adv
      EXIT
   THEN DROP
   2DUP <LF> SCAN IF                \ found LF only
      NIP SWAP - DUP 1+
      EXIT
   THEN DROP
   NIP DUP ;                        \ found no EOL

A little obscure. It returns:
   
   0 0        for empty string
   n n        for no eol char
   len len+1  for a line ending with a bare cr
   len len+1  for a line ending with a bare lf
   len len+2  for a line ending with a crlf pair

The problem is that it always searches for a cr first. I was
trying to process a very large file (6,000,000 bytes, 70,000+ lines)
from a SLURP-ed memory image one line at a time (sample code for
this below). It took 192,433,084 micro-seconds (yep, that long, more
than 3 minutes!) to scan all the lines in the file.

Why? The file (which I had not really looked at from an external
source) was a unix-style file with LF line termination. So, the
first line was parsed by looking through all 6 million bytes for a
CR, failing, then looking for an LF. etc.

Changing the file wasn't an option, so re-implement EOL-SCANNER
to search simultaneously for CR and LF and exit accordingly.

The same test run with the new scanner on the same data takes
27,480 usec. That's a factor of about 7000.

---------------------------------------------------------------------- }

code eol-scanner2 ( addr n -- len #adv )
   ebx ebx test  0= if                \ no string
      0 # 0 [ebp] mov  ret            \ bail early
   then                               \
   0 [ebp] edx mov  ebx ecx mov       \ edi=addr ecx=n
   13 # al mov  10 # ah mov           \ delimiters in al and ah
   begin                              \
      0 [edx] bl mov                  \ get char and increment
                                      
      bl al cmp 0= if                 \ found cr
         0 [ebp] edx sub              \ len of string
         edx 0 [ebp] mov              \ for return, actual len
         1 [edx] ebx lea              \ len+1 for just cr
         1 # ecx cmp 0<> if           \ if not at end
            1 [edx] ah cmp  0= if     \ if next is lf
               ebx inc                \ len+2 for crlf
            then                      \
         then                         \
         ret
      then

      bl ah cmp 0= if                 \ found lf
         0 [ebp] edx sub              \ len of string
         edx 0 [ebp] mov              \ for return, actual len
         1 [edx] ebx lea              \ len+1 for just lf
         ret
      then
      edx inc
   loop                            \
   0 [ebp] edx sub                 \ len of string
   edx 0 [ebp] mov                 \ for return, 
   edx ebx mov                     \
   ret end-code                    \

{ ----------------------------------------------------------------------
A function named NEXT-LINE was the basic use case for EOL-SCANNER.
I implemented two of them; one for each scanner function.

Then I wrote a function to walk all the lines in the memory image
using either scanner, and wrapped it in a timing function.
---------------------------------------------------------------------- }

s" all.dat" slurp  value len  value addr  

: next-line ( addr len -- addr len line len )
   2dup eol-scanner    \ addr len got #advance
   fourth rot 2>r /string 2r> ;

: next-line2 ( addr len -- addr len line len )
   2dup eol-scanner2    \ addr len got #advance
   fourth rot 2>r /string 2r> ;

: next ( addr len xt -- addr len line len )
   >r 2dup r> execute  fourth rot 2>r /string 2r> ;

: walk-all-lines ( xt -- )
   >r  all begin ( addr len)
      dup 0> while
      r@ next 2drop
   repeat 2drop r> drop ;

: timed ( -- )
   '  ucounter 2>r walk-all-lines  2r> utimer ;

.(

Measure performance of large file parsing.

timed eol-scanner
timed eol-scanner2

)