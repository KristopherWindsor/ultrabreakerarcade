
Type xfx_camshake_type
  const sizefactor = 20 * dsfactor
  
  Declare Sub Reset ()
  Declare Sub add (Byval effect As double)
  Declare Sub move ()
  
  declare property x () as integer
  declare property x (xx as integer)
  as integer requestotal
  Dim As Integer _x, y 'properties accessed by shaking items
  
  Dim As Double shake, angle
End Type

Type xfx_flyingbrick_object_type
  As Double x, y, xv, yv
  As Double angle, anglev
  As Integer graphic_mini 'array index for the scaled brick graphics
  As Integer killme
End Type

Type xfx_flyingbrick_type
  Const max = 512, speed = 4
  
  Declare Sub Reset ()
  Declare Sub add (Byref brick As brick_object_type)
  Declare Sub move ()
  Declare Sub display ()
  
  As Integer total, total_previous
  
  As xfx_flyingbrick_object_type flyingbrick_object(1 To max)
End Type

Type xfx_graphic_type
  Const glow_sd = 400 * dsfactor, glow_sr = glow_sd \ 2
  Const nuke_sr = 200, nuke_sd = nuke_sr * 2
  
  Declare Sub start ()
  Declare Sub screenchange ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  Declare Sub effect_grayscale ()
  Declare Sub effect_inverse ()
  Declare Sub effect_metal ()
  Declare Sub effect_pixelation ()
  
  'note: will not use glow_start(), glow_finish(), etc; only for display
  Declare Sub glow_show (Byval x As Integer, Byval y As Integer)
  
  superfluous As fb.image Ptr glow, nuke
  server_dummy
End Type

Type xfx_nuke_object_type
  As Integer x, y
  As Double s, rotation
  As Integer ttl
End Type

Type xfx_nuke_type
  Const max = 4
  
  const scalefactor = .04 * dsfactor
  const rotationfactor = .04
  const ttl_max = 100
  
  Declare Sub add (Byval x As Integer, Byval y As Integer)
  Declare Sub display ()
  Declare Sub move ()
  Declare Sub Reset ()
  
  As Integer total
  As xfx_nuke_object_type object(1 To max)
End Type

Type xfx_particle_object_type
  As Integer x, y
  As Double d
End Type

Type xfx_particle_type
  Const max = 200
  Const velocity = 2 * dsfactor
  Const maxdist = 600 * dsfactor
  Const size = 2 * dsfactor
  
  Declare Sub add (Byval x As Integer, Byval y As Integer)
  Declare Sub display (Byval c As Uinteger = color_enum.black)
  Declare Sub move ()
  Declare Sub Reset ()
  
  As Integer total
  As xfx_particle_object_type particle_object(1 To max)
End Type

type xfx_type
  declare sub start ()
  declare sub screenchange ()
  declare sub gfxchange ()
  declare sub reset ()
  declare sub move ()
  declare sub finish ()
  
  As xfx_camshake_type camshake
  As xfx_flyingbrick_type flyingbrick
  As xfx_graphic_type graphic
  As xfx_nuke_type nuke
  As xfx_particle_type particle
end type

declare sub xfx_gfxchange_threadable (Byval nothing As Any Ptr = 0)

dim shared as xfx_type xfx
