
' Ultrabreaker Leveler!
' (C) 2006 - 2008 Innova and Kristopher Windsor

#include once "windows.bi"
#undef true
#undef false
#undef min
#undef float
#undef transparent
'#undef false
'#define false 0

#include once "fbgfx.bi"
#include "vbcompat.bi"

#include once "version.bi"
#include once "abfont/abfont.bi"
#include once "igui/igui.bi"
#include once "fbpng/png_image.bi"

#include once "image/multiput.bas"
#define multiput _multiput

#inclib "igui"
#inclib "fbpng"

const screen_sx = 1024, screen_sy = 768

Enum color_enum
  none = 0
  
  black = &HFF000000
  gray  = &HFF888888
  lightgray = &HFFCCCCCC
  white = &HFFFFFFFF
  
  green = &HFF44FF44
  red   = &HFFFF0000
  
  transparent = &HFFFF00FF
End Enum

enum item_enum
  bonusbutton  = 1 'drop bonus when hit
  brickmachine = 2 'make bricks constantly
  portal       = 3
  portal_out   = 4
  gravity      = 5
  
  max          = 5
end enum

type isettings_type
  declare sub register ()
  
  as integer up 'settings mode
  
  As igui.form_type iform
  As igui.button_type iclose, ihead_main, ihead_paddles, ihead_balls, ihead_graphics, ihead_more, ihead_special, ihead_manage, imanage_newlp
  As igui.checkbox_type iballmelee, ibackgroundimagetile, ispecial_noballlose, ispecial_nobrickwin, ispecial_shooter
  As igui.selector_type ilevelpack, ilevelnumber, ipaddlesides(1 to 5), ibackgroundcolor, ibackgroundimage, iballmultiplier
  As igui.selector_type iballscale, iballspeed, ibonuslives, imousegravity, ipaddlescale, ipaddlestyle, itime_minutes, itime_seconds, imanage_gfxset, imanage_deletelp
  As igui.textbox_type ilevelname, iminscore, itip, itiplose, itipwin, imanage_levelpack
end type

type itoolbar_type
  
  declare sub register ()
  
  As igui.form_type iform
  As igui.button_type iopensettings, itest, idone, iload
  As igui.checkbox_type igridalign
  As igui.selector_type ilayer, ilayersize, iobjectscale, iobjectvalue
  As igui.textbox_type iobjectstyle
  
  as integer pen
  
  as string style(1 to 67) = {"Default", "Invincible", "Exploding", "Replicating", "Moving", _
    "Bonus score", "Bonus time", "Bonus life", "Levelup", "Gravity", "Ball bonus", "Ball bonus double", _
    "Ball big", "Ball small", "Ball speed", "Ball slow", "Ball fire", "Make explode brick", "Make normal brick", _
    "Paddle grow", "Paddle shrink", "Paddle destroy", "Paddle laser", "Paddle stick", "Paddle super", "Paddle rapidfire", _
    "Paddle create", "Orb token", _
    "Enemy rocker", "Enemy speedster", "Enemy destroyer", "Enemy scout", _
    "Wind", "Rain", "Fireworks", "Metal", _
    "Brick A", "Brick B", "Brick C", "Brick D", "Brick E", "Brick F", "Brick G", "Brick H", "Brick I", _
    "Brick J", "Brick K", "Brick L", "Brick M", "Brick N", "Brick O", "Brick P", "Brick Q", "Brick R", _
    "Brick S", "Brick T", "Brick U", "Brick V", "Brick W", "Brick X", "Brick Y", "Brick Z", _
    "Item: bonus button", "Item: brick machine", "Item: portal", "Item: portal destination", "Item: gravity"}
end type

type brick_object_type
  
  declare function displayscale () as double
  declare sub set (byref s as string)
  
  as integer style, value, scale
  as double x, y 'not used by matrix
end type

type brick_type
  const matrix_sx_max = 100, matrix_sy_max = 120, list_max = 1024
  const style_max = 62
  const codes = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"
  
  declare sub matrix_set_size overload (byval hugeness as integer) 'hugeness rating of 1 to 5
  declare sub matrix_set_size overload (byval xlength as integer, byval ylength as integer)
  declare sub matrix_set_scale ()
  
  as integer matrix_sx, matrix_sy, list_total, ycollapse 'ycollapse is forced on, but preserved when loaded from file
  as double matrix_scale
  
  as brick_object_type matrix(1 to matrix_sx_max, 1 to matrix_sy_max)
  as brick_object_type list(1 to list_max)
end type

type item_object_type
  as integer style, d
  as double x, y
end type

type item_type
  const list_max = 32
  
  as integer list_total
  
  as item_object_type list(1 to list_max)
end type

type graphic_type
  const brick_sx = 200, brick_sy = 80
  const item_sr = 120, item_sd = 240
  
  declare sub start ()
  declare sub finish ()
  
  as fb.image ptr brick(1 to brick_type.style_max)
  as fb.image ptr item(1 to item_enum.max)
end type

type layer_type
  const workspace_sx = 1024, workspace_sy = 732
  
  declare sub startover ()
  declare function isempty () as integer
  declare sub edit ()
  declare sub redraw ()
  declare sub backup ()
  declare sub restore ()
  
  as brick_type brick, backup_brick
  as item_type item, backup_item
  
  as integer autoexplode 'delay in seconds
  
  as fb.image ptr workspace
end type

type levelpack_type
  'levelpack loaded when selected levelpack changes; saved when a level is saved
  const d_max = 1024, level_max = 128
  
  declare sub load (byref lp as string)
  declare sub save ()
  
  as string pack
  
  as integer leveltotal, unlockedtotal
  as string gfxset
  
  'other lines of file are not processed
  as integer d_total
  as string d(1 to d_max)
  
  'level names (needed for selecting a level number for the new level)
  as string level(1 to level_max)
end type

type level_type
  const layer_max = 5
  
  declare sub startover ()
  declare sub load (byref lp as string, byval ln as integer, byval temp as integer = false)
  declare sub load_temp ()
  declare sub save (byval istemp as integer = false)
  
  declare sub setupgui ()
  declare sub display ()
  
  'set when level is loaded (when levelR starts, the values are loaded from a data file, sent here via load())
  as levelpack_type levelpack
  as integer levelnumber
  as string levelname
  
  as integer paddlesides(1 to 5)
  
  as uinteger backgroundcolor
  as string backgroundimage
  as integer backgroundimagetile
  
  as integer ballmultiplier, ballmelee
  as double ballscale, ballspeed
  as integer bonuslives, minscore
  as double mousegravity, paddlescale
  as integer paddlestyle
  as integer special_noballlose, special_nobrickwin, special_shooter, time_minutes, time_seconds
  as string tip, tipLose, tipWin
  
  'this is a temp variable; set before processing
  'only read for resetting selected if auto-explode option was selected
  as integer layer_selected
  as layer_type layer(1 to layer_max)
end type

type mouse_type
  as integer x, y, b
end type

declare sub ibackgroundcolor_target ()
declare sub ibackgroundimage_target ()
declare sub ibackgroundimagetile_target ()
declare sub iballmelee_target ()
declare sub iballmultiplier_target ()
declare sub iballscale_target ()
declare sub iballspeed_target ()
declare sub ibonuslives_target ()
declare sub iclose_target ()
declare sub idone_target ()
'declare sub igridalign_target ()
declare sub ilayer_set ()
declare sub ilayer_target ()
declare sub ilayersize_set ()
declare sub ilayersize_target ()
declare sub ilevelpack_target ()
declare sub ilevelnumber_target ()
declare sub ilevelname_target ()
declare sub iload_target ()
declare sub imanage_deletelp_target ()
declare sub imanage_newlp_target ()
'declare sub imanage_levelpack_target ()
declare sub iminscore_target ()
declare sub imousegravity_target ()
declare sub iobjectstyle_target ()
'declare sub iobjectscale_target ()
'declare sub iobjectvalue_target ()
declare sub iopensettings_target ()
declare sub ipaddlesides_target ()
declare sub ipaddlescale_target ()
declare sub ipaddlestyle_target ()
'declare sub iquit_target ()
declare sub ispecial_noballlose_target ()
declare sub ispecial_nobrickwin_target ()
declare sub ispecial_shooter_target ()
declare sub itest_target ()
declare sub itime_minutes_target ()
declare sub itime_seconds_target ()
declare sub itip_target ()
declare sub itiplose_target ()
declare sub itipwin_target ()
