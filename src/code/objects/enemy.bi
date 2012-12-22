
Enum enemy_enum
  rocker    = 1
    'drops rocks and paddleshrinks
    'uses extra negative gravity
    'random targets
  speedster = 2
    'drops ball speeds
    'moves quickly and resists lasers
    'targets the first paddle
  destroyer = 3
    'fires lasers
    'creates normal bricks
    'spins while firing (no specific target; moves to random places)
  scout     = 4
    'fires lasers
    'no good defense; dies quickly
    'targets a random paddle
  max       = 4
End Enum

Enum enemy_mode_enum
  traveling = 1 'going in straight line to the target location
  aiming    = 2 'use defenses here
  firing    = 3 'pause awhile, maybe fire multiple times before moving, aim again, etc
  seeking   = 4 'turning around before moving (might move while turning)
  
  max       = 4
End Enum

Type enemy_object_type_forward As enemy_object_type

Type enemy_config_object_type
  
  'functions calculate object coords
  Declare Function coord_x (e As enemy_object_type_forward Ptr) As Double
  Declare Function coord_y (e As enemy_object_type_forward Ptr) As Double
  
  'polar coords and a rotation angle (which doesn't affect the position)
  As Double pa, pd, angle
End Type

Type enemy_config_type
  Const engine_max = 8, laser_max = 8
  
  As Integer engine_total, laser_total
  As enemy_config_object_type engine(1 To engine_max)
  As enemy_config_object_type laser(1 To laser_max)
End Type

Type enemy_graphic_type
  Const enemy_sr = 160, enemy_sd = enemy_sr * 2
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr enemy(1 To enemy_enum.max)
  server_dummy
End Type

Type enemy_particle_type
  As Double x, y, xv, yv
  As Uinteger c
End Type

Type enemy_object_type
  Const particle_max = 17 * 6
  
  Declare Sub move ()
  Declare Sub display ()
  
  declare sub damage (smashes as double)
  
  declare property missileresistance () as integer
  
  As enemy_enum style
  
  As Double x, y, xv, yv
  
  As Double scale, scale_target 'target changes, scale follows
  As Integer value 'from bricks, is 100 - 8200; used for shrinking enemy, but exponentiated for final score bonus
  As Double angle
  
  'As Integer missileresistance
  
  'spin > move to target > spin > fire > repeat
  As enemy_mode_enum ai_mode
  
  'vars for if moving
  As Integer ai_target_x, ai_target_y
  As Double ai_angle 'angle approaches this
  As Integer ai_angle_v 'spin direction
  As Integer ai_cycle_ttl 'how long until the next cycle starts?
  
  As Integer particle_current
  'each engine gets several bands, each of which has several particles
  As enemy_particle_type particle(1 To 4, 1 To particle_max)
End Type

Type enemy_type
  Const max = 8
  
  const scalefactor = dsfactor * 7 \ 5 'multiplied by some arbitrary formula based on brick value; that formula gives 1 for value = 5
  const scalefactor_particle = 5 * dsfactor
  
  'Const bonuslaunchspeed = 4 * dsfactor
  const killfactor = 2 'large number -> dies faster
  const engineparticlespeed = 3 * dsfactor
  Const destructionscale = .25 * dsfactor
  Const newbrickscale = .5 * dsfactor
  
  'this is a constant; v(0) = speed while seeking
  As Double velocities(0 To enemy_enum.max) = _
    {.06 * dsfactor, .25 * dsfactor, 1.0 * dsfactor, .5 * dsfactor, .6 * dsfactor}
  as integer missileresistance(1 to enemy_enum.max) = {6, 20, 6, 2}
  as double gravitysizefactor(1 to enemy_enum.max) = {-.05, -.05, -.03, -.02}
  
  Declare Sub start ()
  Declare Sub Reset ()
  Declare Sub gfxchange ()
  Declare Sub add (Byval x As Integer, Byval y As Integer, Byval style As enemy_enum, _
    Byval scale As Double, Byval value As Integer)
  Declare Sub move ()
  Declare Sub display ()
  Declare Sub finish ()
  
  As enemy_config_type config(1 To enemy_enum.max)
  
  As enemy_graphic_type graphic
  
  As Integer total
  As enemy_object_type object(1 To max)
End Type

Dim Shared As enemy_type enemy
