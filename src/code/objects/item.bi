
Enum item_enum
  bonusbutton  = 1 'drop bonus when hit
  brickmachine = 2 'make bricks constantly
  portal       = 3
  portal_out   = 4
  
  max          = 4
End Enum

Type item_graphic_type
  Const item_sr = 120, item_sd = 240, frame_max = 6, frame_ratefactor = 3
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr item(1 To item_enum.max, 1 To frame_max)
  server_dummy
End Type

Type item_object_type
  
  declare sub move ()
  declare sub display ()
  
  As item_enum style
  
  As Double x, y, scale, angle
  As Integer alpha
  
  As Integer d 'all items need one variable (brick firing mode, bonus dropping timeout, portal code, portal index)
  As Integer d_temp 'frames until switching modes, bonus can be dropped
  
  As Integer killme
End Type

Type item_type
  Const max = 64
  
  const scalefactor = 1
  const rotationfactor = .004
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub reset2 ()
  declare sub add (Byval style As item_enum, Byval x As Integer, _
    Byval y As Integer, Byval scale As Double, Byval d As Integer = 0)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  As Integer total
  As Integer frame, frame_previous
  
  As item_graphic_type graphic
  As item_object_type object(1 To max)
End Type

declare sub item_gfxchange_threadable (Byval nothing As Any Ptr = 0)

Dim Shared As item_type item
