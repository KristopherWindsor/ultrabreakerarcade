
Enum sound_enum
  ball_collide              = 01
  
  bonus_collect             = 02
  
  brick_explode             = 03
  
  'create bricks or gravity (rain only)
  brickgravity_create       = 04
  
  enemyorb_create           = 05
  enemyorb_destroy          = 06
  
  fireworks_create          = 07
  fireworks_destroy         = 08
  
  laser_create              = 09
  
  main_levelcomplete        = 10
  main_lifelost             = 11
  
  menu_changeselected       = 12
  menu_select               = 13
  
  paddle_destroy            = 14
  
  portal_collide            = 15
  
  shootermode               = 16
  
  'thud: when ball or laser collides with enemy, it sounds like a brick breaking
'  ball_destroy              = 18
'  bonusbutton_collide       = 18
'  brick_destroy             = 18
'  enemy_collide             = 18
  thud                      = 17
  
  weather_create            = 18
  
  max                       = 18
End Enum

Type sound_type
  const volumestep = 15
  const volumequiet = 3
  
  As Integer volume_music 'levels 1 - 4
  As Integer volume_sfx
  
  Declare Sub start ()
  Declare Sub add (Byval s As sound_enum)
  Declare Sub move ()
  Declare Sub finish ()
  declare sub commit_volume_music (level as integer = -1)
  declare sub commit_volume_sfx (level as integer = -1)
  Declare Sub speak (Byref _text As String, Byval dowait As Integer = false)
  
  As Sub(Byval text As Any Ptr) Ptr speakthread
  as any ptr threadmutex
  
  superfluous As audio.object audio
End Type

Dim Shared As sound_type sound
