
Enum ball_enum
  normal = 1
  fire   = 2

  max    = 2
End Enum


Type ball_graphic_type
  Const ball_sr = 120, ball_sd = 240
  const trail_alpha = 20
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr ball(1 To ball_enum.max)
  server_dummy
End Type

Type ball_trail_type
  As Double x, y
End Type

Type ball_object_type
  Const trail_max = 8
  
  declare sub aim ()
  declare sub display ()
  declare sub fixstuckposition ()
  declare sub move ()
  Declare Sub push (Byval ixv As Double, Byval iyv As Double, Byval vreset As Integer = false)
  
  As Double x, y
  As Double xv, yv
  
  As ball_enum style
  As Double scale
  
  'display only
  As Double angle
  
  'paddle interaction
  As Integer stuck 'not a boolean; either false for no, or index for yes
  As Integer instantrelease 'release on first click; don't just release one ball per frame
  as integer aimrotate 'oscillating rotation direction
  as integer mightbereleased 'will be released if user clicks (assuming there is no launch delay)
  
  'trail for fireballs
  Dim As Integer trail_current
  Dim As ball_trail_type trail(1 To trail_max)
  
  As Integer killme
End Type

Type ball_type
  Const max = 64
  
  'ball scale is data_scale * scalefactor
  const scalefactor = .2 * dsfactor
  const scalemin = .05 * dsfactor
  const scalemax = 3 * dsfactor
  
  const speedfactor = 4 * dsfactor
  const speedmin = .01 * dsfactor, speedmax = 15 * dsfactor
  const speedstablecomponent = 1 * dsfactor, speedstablevector = 2 * dsfactor
  
  const spinspeed = .01, aimrotatefactor = .02, componentratiomax = 4
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub reset2 ()
  Declare Sub add (Byval apaddle As Integer, Byval addtotal As Integer = 1, _
    Byval stuck As Integer = false)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  'add initial balls, or balls if you lost a life
  Declare Sub addgroup (Byval stuck As Integer = true)
  declare Sub duplicate (Byval aball As Integer)
  
  'defined by level file
  As Integer data_multiplier
  As Integer data_melee
  As Double data_scale
  As Integer data_speed 'multiplied by speedfactor; the default is 1
  
  'as integer aimthis(1 to setting.maxplayers) 'select a ball to rotate / aim while stuck on paddle
  
  As ball_graphic_type graphic
  
  As Integer total
  As ball_object_type object(1 To ball_type.max)
End Type

Dim Shared As ball_type ball
