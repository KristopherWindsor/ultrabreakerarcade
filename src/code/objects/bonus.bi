
Enum bonus_enum
  min                =  6
  
  bonus_score        =  6 'F
  bonus_time         =  7 'G
  bonus_life         =  8 'H
  levelup            =  9 'I
  gravity            = 10 'J
  ball_bonus         = 11 'K
  ball_bonus_double  = 12 'L
  ball_big           = 13 'M
  ball_small         = 14 'N
  ball_speed         = 15 'O
  ball_slow          = 16 'P
  ball_fire          = 17 'Q
  make_explode_brick = 18 'R
  make_normal_brick  = 19 'S
  paddle_grow        = 20 'T
  paddle_shrink      = 21 'U
  paddle_destroy     = 22 'V
  paddle_laser       = 23 'W
  paddle_stick       = 24 'X
  paddle_super       = 25 'Y
  paddle_rapidfire   = 26 'Z
  paddle_create      = 27 '0
  orb                = 28 '1
  
  max                = 28
End Enum

Type bonus_graphic_type
  Const bonus_sr = 32, bonus_sd = bonus_sr * 2
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub gfxreset ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr bonus(bonus_enum.min To bonus_enum.max)
  superfluous As fb.image Ptr minis(bonus_enum.min To bonus_enum.max)
  server_dummy
End Type

Type bonus_object_type
  As brick_enum style
  
  declare sub move ()
  declare sub display ()
  
  As Double x, y, xv, yv
  As Integer x_original, y_original
  
  As Double data_brickscale
  As Integer data_parentball
  
  as integer maxalpha
  
  As Integer killme
End Type

Type bonus_type
  Const max = 256
  const sizefactor = dsfactor * 1
  const speed = 5.66 * dsfactor
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub reset2 ()
  Declare Sub add (x As double, y As double, Byval style As bonus_enum, _
    Byval xv As Double, Byval yv As Double, _
    Byval brickscale As Double = 0, Byval parentball As Integer = 0)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  as string title(bonus_enum.min to bonus_enum.max) = _
    {"Score", "Time", "Life", "Levelup", "Gravity", "Extra ball", _
    "Double balls", "Scale up", "Scale down", "Speed up", "Slow down", "Fireballs", _
    "Exploding bricks", "Breakable bricks", "Large paddles", "Small paddles", "Destruction", _
    "Lasers", "Sticky", "Super paddles", "Rapidfire", "Extra paddle", "Orb token"}
  
  as bonus_graphic_type graphic
  
  As Integer total
  as bonus_object_type object(1 to max)
End Type

Dim Shared As bonus_type bonus
