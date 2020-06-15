{ ========== struct.f ==================================================
  (C) 2020 Stratolaunch LLC ---- 14Feb2020 rcvn

  Data structures in Swoop
====================================================================== }


{ ========== add helpers to swoop for datastructures. ==================

   field: is an alias of buffer:
   data-structure is a class which guarantees the member function sizeof
      and will allow inheritable data structure functions later
   data-class is a wrapper to hide the sublclass-iness    

====================================================================== }

get-current ( *) cc-words set-current

   : field: ( n -- )   [ cc-words +order ] buffer: [ cc-words -order ] ;

   : end-struct ( -- )   0 [ oop +order ] RE-OPEN  -CC [ oop -order ] ;

( *) set-current

\ ========== a data structure definition is just a class ===============

class data-structure
   : sizeof ( -- n )   this sizeof ;
   : content ( -- addr n )   addr sizeof ;
   defer: format ( -- z )   0 ;
   defer: init ( -- )   content erase ;
end-class   

: data-struct ( -- )
   data-structure subclass ;

{ ========== data structure example ====================================

   data-struct hello-response
      1 cells field: .command-value
      1 cells field: .seconds 
      1 cells field: .minutes 
      1 cells field: .hours   
      1 cells field: .day     
      1 cells field: .month   
      1 cells field: .year
   end-struct
   
   hello-response builds hr
   
   hr sizeof   \ -> 28
   hr .seconds \ -> address of variable
   hr .seconds @ .
   44 hr .day !

alternate syntax (available on all class definitions in the object system)

   hello-response: foo
   foo sizeof
   foo .seconds @ .
   44 foo .day !

notice the ":" following the class name; the defining word is built
automatically when the class (or data structure) is defined, "behind
the user's back"


   
====================================================================== }

