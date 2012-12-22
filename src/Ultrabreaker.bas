
' Ultrabreaker...............a breakout game
' Developed since 2006 by Kristopher Windsor

' Licensing
' - All borrowed code and assets are OK for commercial redistribution (mostly in the public domain)
'   (note: music licensing is still in progress)
' - Orginal code and assets for this game should not be redistributed for non-personal use without written permission

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
'Dec 2012: reverting monetization and online community efforts in order to actually release the game

'Command line arguments (only can set one at a time)
'VALIDATE [file - either a .ubr, or the contents of a replay, in hex, in a file with a different extension] (for the server)
'TEST (goes straight to the test menu)
'GETSCREENS (saves full-size screenshots in addition to thumbnails, for each level)

#include once "code/ultrabreaker.bi"

main.run()
