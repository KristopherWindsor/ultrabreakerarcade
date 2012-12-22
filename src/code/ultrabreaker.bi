
' Ultrabreaker!
' (C) 2006 - 2009 Innova and Kristopher Windsor

#include once "version.bi"

'modes

'#define debug
#ifdef debug
  #define mop(x) , x
  #define multiput Scope: var f = Freefile(): Open cons For Output As #f: Print #f, __line__: Close #f: End Scope: _multiput
#else
  #define mop(x)
  #define multiput _multiput
#endif

'#define server_validator
#ifdef __FB_LINUX__
  #define server_validator
#endif
#ifdef server_validator
  #define superfluous REM ''''
  #define server_dummy As Integer dummy
#else
  #define superfluous
  #define server_dummy

  'headers
  
  #include once "network/network.bas"
  
  #define UNICODE
  #include once "disphelper/disphelper.bi"
  #include once "windows.bi"
  #undef true
  #undef false
  #undef min
  #undef float
  #undef transparent
  
  #include once "fbgfx.bi"
  #include once "abfont/abfont.bi"
  #include once "fbpng/png_image.bi"
  #include once "sound/audio.bi"
  
  'source
  
  #include once "abfont/abfont.bas"
  #include once "image/imagescaler.bas"
  #include once "image/multiput.bas"
  #include once "sound/audio.bas"
  #include once "video/avicapture.bas"
  
  'libraries
  #inclib "fbpng"
#endif

'defines

#define float double
#define pi atn(1) * 4

#undef option
#undef screen
#undef wait

'dsfactor scales the size of the "virtual screen"
'larger number means fewer troubles with integer rounding
'but the number can't be too large because control coords would overflow in recording files
#define dsfactor 10

Const true = -1, false = 0

Enum color_enum
  none = 0
  
  black = &HFF000000
  gray  = &HFF888888
  white = &HFFFFFFFF
  
  green = &HFF44FF44
  red   = &HFFFF0000
  
  transparent = &HFFFF00FF
End Enum

#include once "objects/setting.bi"
#include once "objects/ball.bi"
#include once "objects/brick.bi"
#include once "objects/bonus.bi"
#include once "objects/screen.bi"
#include once "objects/utility.bi"
#include once "objects/main.bi"
#include once "objects/menu.bi"
#include once "objects/enemy.bi"
#include once "objects/explodepaddle.bi"
#include once "objects/gravity.bi"
#include once "objects/item.bi"
#include once "objects/game.bi"
#include once "objects/laser.bi"
#include once "objects/paddle.bi"
#include once "objects/orb.bi"
#include once "objects/server.bi"
#include once "objects/sound.bi"
#include once "objects/weather.bi"
#include once "objects/xfx.bi"

#include once "objects/ball.bas"
#include once "objects/bonus.bas"
#include once "objects/brick.bas"
#include once "objects/enemy.bas"
#include once "objects/explodepaddle.bas"
#include once "objects/game.bas"
#include once "objects/gravity.bas"
#include once "objects/item.bas"
#include once "objects/laser.bas"
#include once "objects/main.bas"
#include once "objects/menu.bas"
#include once "objects/orb.bas"
#include once "objects/paddle.bas"
#include once "objects/screen.bas"
#include once "objects/server.bas"
#include once "objects/setting.bas"
#include once "objects/sound.bas"
#include once "objects/utility.bas"
#include once "objects/weather.bas"
#include once "objects/xfx.bas"
