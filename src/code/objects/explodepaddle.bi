
Type explodepaddle_particle_type
  As Double x, y, xv, yv
  As Integer gx, gy 'the offset for accessing the graphic
End Type

Type explodepaddle_object_type
  Const particle_max = 3000
  
  'As Double x, y
  
  As Integer particle_total
  As explodepaddle_particle_type particle(1 To particle_max)
  
  superfluous As fb.image Ptr graphic
  
  As Integer ttl, killme
End Type

Type explodepaddle_type
  Const max = 8, particle_sd = 4, particlespeed = 8 * dsfactor
  
  declare sub reset ()
  declare sub add (Byval apaddle As Integer)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  As explodepaddle_object_type object(1 To explodepaddle_type.max)
  
  As Integer total
End Type

Dim Shared As explodepaddle_type explodepaddle
