
Enum brick_enum
  normal             =  1 'A
  invincible         =  2 'B
  explode            =  3 'C
  replicating        =  4 'D
  invincible_bouncy  =  5 'E
  
  'same as bonus enum values
  first_bonus        =  6 'F
  last_bonus         = 28 '1
  
  first_enemy        = 29 '2
  last_enemy         = 32 '5
  
  first_weather      = 33 '6
  last_weather       = 36 '9
  
  first_extended     = 37 'a
  last_extended      = 62 'z
  
  max                = 62
End Enum

Type brick_graphic_brick_type
  Const frame_max = 6
  
  Declare Sub cleanup () 'delete
  
  As Integer total '1, 2, 3, 6, -1
  superfluous As fb.image Ptr g(1 To frame_max)
End Type

Type brick_graphic_mini_type
  Const frame_max = brick_graphic_brick_type.frame_max
  
  'this stores scaled graphics for the bricks (to be directly put() to the screen)
  'there will be one of these types for each different brick, so it needs to identify the brick
  As brick_enum brick_style
  As Double brick_scale
  
  As brick_graphic_brick_type b
End Type

Type brick_object_type
  
  declare Sub move ()
  declare sub cleanup ()
  Declare Function is_explodable () As Integer
  Declare Function is_normal () As Integer
  
  As Integer x, y
  As Integer value, awardpoints
  As Double scale 'does not account for the screen scale
  As brick_enum style
  
  As Integer hit_bonusball
  'for making brickshadows if the brick is killed
  As Double hit_shadow_xv
  As Double hit_shadow_yv
  As Integer hit_shadow_spin
  
  'more settings
  As Integer delay_explode 'brick will self destruct when this reaches 0; delay used for exploding chain
  As Integer bouncy, replication 'properties set by certain styles, but could be used by all bricks
  As Integer graphic_mini 'index for the array of scaled graphics for quick display
  
  'movement
  As Integer xv, yv
  As Integer independant 'a display / movement flag
  
  'these are used for fast collision calculations (based on x, y, and scale)
  As Integer x1, y1, x2, y2

  As Integer killme
End Type

Type brick_graphic_type
  Const brick_sx = 200, brick_sy = 80
  Const frame_max = 6, mini_max = 2000, frame_ratefactor = 6
  
  Declare Sub screenchange ()
  Declare Sub gfxchange ()
  Declare Sub gfxreset ()
  Declare Sub finish ()
  Declare Sub erasebrick (Byref ibrick as brick_object_type)
  Declare Sub redrawbrick (Byref ibrick as brick_object_type)
  Declare Sub set_mini (byref ibrick As brick_object_type)
  
  superfluous As fb.image Ptr background 'the background has to be used in the game to erase broken bricks; size: scaled screen size
  superfluous As fb.image Ptr brickset(1 To frame_max) 'displayed in game; size: window size
  As brick_graphic_brick_type brick(1 To brick_enum.max) 'size: constant
  
  As Integer mini_total
  As brick_graphic_mini_type mini(1 To mini_max)
End Type

Type brick_type
  Const max = 2048
  Const codes = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz" 'file parsing
  
  const value_enemyfired = 10 'bricks fired by enemies
  const value_convertedtonormal = 25 'invincible bricks turned normal to clear for shooter mode
  const value_brickmachine = 15
  const value_wind = 10
  
  'launched / moving bricks
  const speed_enemyfired = 4 * dsfactor
  const speed_brickmachine = 4 * dsfactor
  const speed_moving = 1 * dsfactor
  
  const damage_enemyexplosion = 20
  
  const scrollspeed = 1 * dsfactor
  
  declare Sub screenchange ()
  declare Sub reset ()
  declare Sub gfxchange ()
  declare Sub reset2 ()
  declare Sub add (Byval x As Double, Byval y As Double, Byval style As brick_enum, _
    Byval scale As Double, Byval value As Integer, _
    Byval xv As Integer = 0, Byval yv As Integer = 0, _
    Byval independant As Integer = false, Byval replicating As Integer = false, _
    Byval autoexplode As Integer = 0)
  declare Sub move ()
  declare Sub display ()
  declare Sub finish ()
  declare Sub replicate (Byref ibrick as brick_object_type)
  
  As Integer iscleared 'are all the breakable bricks destroyed?
  As Integer field_x1, field_y1, field_x2, field_y2
  As Integer ballspeedup 'when brick total drops to this, speed balls up
  As Integer total
  
  As brick_graphic_type graphic
  As brick_object_type object(1 To max)
End Type

Dim Shared As brick_type brick
