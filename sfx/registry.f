{ ========== registry.f ================================================
  (C) 2020 Stratolaunch LLC ---- 24Feb2020 rcw/rcvn

  Manage registry keys for strings
====================================================================== }

: ZWRITE-REG ( zvalue zkey -- )
   GETREGKEY LOCALS| hreg zkey zsrc |
   zsrc ZCOUNT zkey hreg WRITE-REG DROP  hreg RegCloseKey DROP ;

: ZREAD-REG ( zdest len zkey -- )
   GETREGKEY LOCALS| hreg zkey maxlen dest |
   PAD 256 zkey hreg READ-REG DROP  maxlen 1- MIN
   PAD SWAP dest ZPLACE   hreg RegCloseKey DROP ;

: WRITE-REG-STRING ( addr len zkey -- )
   GETREGKEY >R  R@ WRITE-REG DROP  R> RegCloseKey DROP ;

: READ-REG-STRING ( addr len zkey -- n )
   GETREGKEY >R  R@ READ-REG DROP  R> RegCloseKey DROP ;

