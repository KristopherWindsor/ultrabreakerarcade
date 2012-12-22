
Enum paddle_enum
  normal = 1
  super  = 2
  
  max    = 2
End Enum

Enum paddle_side_enum
  horizontal_first = 1
  top              = 1
  bottom           = 2
  horizontal_last  = 2
  
  vertical_first   = 3
  Left             = 3
  Right            = 4
  center           = 5
  vertical_last    = 5
  
  max              = 5
End Enum

Type paddle_graphic_type
  Const paddle_sx = 600, paddle_sy = 60
  
  Declare Sub start ()
  'not needed: declare sub screenchange ()
  Declare Sub gfxchange ()
  Declare Sub gfxreset ()
  Declare Sub finish ()
  superfluous Declare Sub fadepaddle (Byval thepaddlegraphic As fb.image Ptr)
  
  'the original paddle and 4 mini versions
  superfluous As fb.image Ptr paddle(1 To paddle_enum.max, true To false) 'for each style, with and without lasers
  superfluous As fb.image Ptr minis(1 To 2, 1 To paddle_enum.max, 1 To paddle_side_enum.max) 'player, style, side
  server_dummy
End Type

Type paddle_object_type
  
  declare sub move ()
  declare sub display ()
  
  declare function get_totalInstantReleaseBalls() as integer
  
  As paddle_enum style
  As paddle_side_enum side
  
  As Integer owner, lives 'player / control number
  
  As Double x, y 'current position (center of paddle) (moves to tx, ty)
  As Double xt, yt 'target (resting) place
  As Double xp, yp 'previous coords
  As Double xv, yv 'velocity (affects balls on bounce)
  
  As Integer x1, y1, x2, y2 'calculated each frame for collision detection
  
  As Integer offset 'for lining up multiple paddles
  
  As Integer killme
End Type

Type paddle_type
  Const max = 100
  
  const scale_min as integer = .1 * dsfactor
  const scale_factor as integer = .4 * dsfactor
  const scale_max = 3 * dsfactor
  
  Const frictioneffect = .1 'when ball hits moving paddle, ball velocity changes; this factor minimizes the change
  Const lives_rockloss = 20, lives_max = 32
  const slidefactor = .08 '1 -> moves to mouse immediately (no slide); 0 -> no motion
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub reset2 ()
  declare sub add (Byval side As paddle_side_enum, Byval whichplayer As Integer = -1)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  declare sub addgroup ()
  Declare Sub set_scale (Byval scale As Double)
  Declare Sub set_defaultstyle (Byval style As paddle_enum)
  
  'paddle properties
  As paddle_enum data_defaultstyle
  As Integer data_sticky
  As Double data_scale, data_scale_original 'original is used for resetting scale when player loses life
  as integer quantities(1 to paddle_side_enum.max)
  
  As Integer total
  
  As paddle_graphic_type graphic
  As paddle_object_type object(1 To max)
End Type

declare sub paddle_gfxchange_threadable (Byval nothing As Any Ptr = 0)

Dim Shared As paddle_type paddle
