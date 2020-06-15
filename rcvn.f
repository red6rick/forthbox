{ ----------------------------------------------------------------------
Compile all my extensions on top of the SwiftForth distribution

rick vannorman 26apr2020 rick@neverslow.com
---------------------------------------------------------------------- }

pushpath
'fname @ zcount -name pad zplace  pad SetCurrentDirectory drop

\ ----------------------------------------------------------------------

requires fpmath

\ ----------------------------------------------------------------------

include sfx\prelude.f
include sfx\indexed-loops

\ ----------------------------------------------------------------------
\ text utilities

include sfx\printf.f
include sfx\clipboard.f

\ ----------------------------------------------------------------------
\ enhance the object model

include sfx\oopext
include sfx\struct

\ ----------------------------------------------------------------------
include sfx\fpext

\ ----------------------------------------------------------------------
\ frameworks and extensions for building window applications

include sfx\registry
include sfx\winapi.f
include sfx\winapp
include sfx\widget
include sfx\infopane
include sfx\gui-framework
include sfx\derived-control
include sfx\regex

\ ----------------------------------------------------------------------
include sfx\editors
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

