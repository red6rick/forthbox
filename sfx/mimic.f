
oop +order
: mimic
   create 0 ,  immediate
   does> ( addr) .s
      bl peek-word count s" mimics" compare(nc) 0= if
         bl word drop  '  >body swap ! exit
      then ( else) @ ['] >data (object) ;
previous



\\

class point  single x single y : dot x . y . ; end-class
class joint  : dot ." up in smoke" ; end-class

point builds pt
joint builds doobie

mimic foo

foo mimics point   foo dot
foo mimics joint   foo dot


