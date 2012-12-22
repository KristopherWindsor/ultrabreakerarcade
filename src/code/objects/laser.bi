
Enum laser_enum
  player = 1
  enemy  = 2
End Enum

Type laser_graphic_type
  Const bullet_sx = 20, bullet_sy = 16
  Const laser_sx = 30, laser_sy = 60
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr bullet, laser
  server_dummy
End Type

Type laser_object_type
  
  declare sub move ()
  declare sub display ()
  
  As Double x, y, xv, yv
  As Double angle
  
  As laser_enum style 'enemy or player bullet?
  
  As Integer killme
End Type

Type laser_type
  Const max = 2048
  const speed = 8 * dsfactor, sizefactor = dsfactor
  const powerbonus_shootermode = 20
  const powerbonus_cheat = 100
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange
  Declare Sub add (Byval x As Double, Byval y As Double, Byval xv As Double, Byval yv As Double, _
  Byval style As laser_enum = laser_enum.player)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  As Double power, launchload 'number of bonuses collected; the variable that lets you fire every few frames

  As laser_graphic_type graphic
  
  As laser_object_type object(1 To laser_type.max)
  As Integer total
End Type

declare sub laser_gfxchange_threadable (Byval nothing As Any Ptr = 0)

Dim Shared As laser_type laser
