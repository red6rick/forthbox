{ ----------------------------------------------------------------------
Compile all my extensions on top of the SwiftForth distribution

rick vannorman 26apr2020 rick@neverslow.com
---------------------------------------------------------------------- }

pushpath
'fname @ zcount -name pad zplace  pad SetCurrentDirectory drop


requires fpmath

include sfx\prelude.f
include sfx\printf.f
include sfx\clipboard.f
include sfx\winapi.f
include sfx\oopext
include sfx\fpext
include sfx\struct
include sfx\sprites
include sfx\registry
include sfx\winapp
include sfx\indexed-loops
include sfx\widget
include sfx\infopane
include sfx\gui-framework
include sfx\derived-control

include sfx\editors
include sfx\regex
include sfx\line-noise

hwnd pad getwindowrect drop pad 2@ swap 0 monitorfrompoint 0= [if]
   console-window +order  force-onscreen  previous
[then]

\ ----------------------------------------------------------------------

' (ddmmmyyyy) is (date)

title" sf/rcvn" 
title zcount type   cr
version zcount type cr
cr
\ ----------------------------------------------------------------------

ONLY FORTH DEFINITIONS  GILD

poppath


\\

cd 

include c:\rcvn\editors
include c:\rcvn\regex
include c:\rcvn\line-noise

.(
rcvn.f
) version count type cr

