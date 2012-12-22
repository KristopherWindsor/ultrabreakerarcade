
' Ultrabreaker! A breakout game
' (C) 2006 - 2010 Innova and Kristopher Windsor

' All code and assets are OK for commercial redistribution
' See the README for details

'A brief history:
'Dec 2006: project begins, features take priority over bugs
'Mar 2007: development goes on-and-off, learning PHP on the side
'Jun 2007: development stops, Zonaxtic and other stuff takes priority
'Jun 2008: complete project re-write begins, code is better
'Aug 2008: development slows, but project has progressed well
'Jan 2009: website is up, levels are made
'Feb 2009: development slows (is mostly testing)
'Jun 2009: game is almost complete, but code re-factoring (for more OOP) begins
'Feb 2010: game is ready, music rights acquired

'Command line arguments (only can set one at a time)
'VALIDATE [file - either a .ubr, or the contents of a replay, in hex, in a file with a different extension] (for the server)
'TEST (goes straight to the test menu)
'GETSCREENS (saves full-size screenshots in addition to thumbnails, for each level)

#include once "code/ultrabreaker.bi"

main.run()
