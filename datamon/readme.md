# A data monitor for SwiftForth

This is a top-level window which can update and display
text live and directly from a running SwiftForth program.

The general principle is to create the window and use an
output pattern to generate text that is displayed in it.
The display is updated on a WM_TIMER event.
