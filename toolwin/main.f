{ ----------------------------------------------------------------------
a simple tool window; display text and controls together
this requires that the text windows be separate children, just like
the windows controls are.


use the placement technique for these? can the text panes float size?

the text part of the window can inherit from client
the buttons can be derived-controls?
maybe the text window should be derived too? from static?



Rick VanNorman   4May2020  rick@neverslow.com
---------------------------------------------------------------------- }

include gui.f

toolwin-class builds gui
: go gui construct ;

cr cr .( type GO to run the test ) cr


