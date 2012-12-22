
Enum gravity_enum
  normal     = 1
  mouse      = 2
  rain       = 3
  enemypower = 4
  orbpower   = 5
End Enum

Type gravity_graphic_type
  Const orb_sr = 120, orb_sd = orb_sr * 2
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr orb
  server_dummy
End Type

Type gravity_object_type
  As gravity_enum style
  
  declare sub move ()
  declare sub display ()
  
  As Double x, y
  As Double scale, scale_display 'scale can be negative for antigravity; scale_display grows up to scale in the first few frames
  As Double angle
  
  'special data only used by some styles
  As Integer special_enemy 'index
  
  As Integer killme
End Type

Type gravity_type
  Const max = 20
  const power = 30 * dsfactor
  
  'scale for bonus and item should match the scale for actual items (= 1)
  const scalefactor_bonus = 1 'multiplied by brick size
  const scalefactor_enemy = 2 / 3 * dsfactor 'multiplied by enemy size and type (but not enemy scalefactor)
  const scalefactor_orb = 10 / 3 * dsfactor
  const scalefactor_item = 1 'multiplied by size specified in file
  const scalefactor_rain = .175 * dsfactor
  
  Declare Sub start ()
  Declare Sub reset ()
  Declare Sub gfxchange (Byval nothing As Any Ptr = 0)
  Declare Sub add (Byval x As Integer, Byval y As Integer, Byval scale As Double, _
    Byval style As gravity_enum = gravity_enum.normal, Byval enemy As Integer = 0)
  Declare Sub move ()
  Declare Sub display ()
  Declare Sub finish ()
  
  As Integer total
  
  As gravity_graphic_type graphic
  As gravity_object_type object(1 To max)
End Type

declare sub gravity_gfxchange_threadable (Byval nothing As Any Ptr = 0)

Dim Shared As gravity_type gravity
