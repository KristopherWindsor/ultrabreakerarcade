
Type orb_object_type
  Const scale_exploding = 2.5 * dsfactor, scale = .2 * dsfactor
  Const size = 400 'when paddle = 600px, this is the orb radius
  const brickbumpspeed = 8 * dsfactor 'moves bricks this much per frame on collision
  
  declare sub move ()
  declare sub display ()
  
  As Double x, y, xv, yv
  As Double scale_display 'scale display approaches real scale scale (or big when dying)
  As Double angle
  
  As Integer owner
  
  As Integer lives
  As Integer killme
End Type

Type orb_type
  Const max = 6, lives_max = 50
  const xslidefactor = .2 * dsfactor 'accelerates horizontal movement
  
  declare Sub reset ()
  declare Sub add ()
  declare Sub move ()
  declare Sub display ()
  
  'queue is a stack; orbs added when they can be
  As Integer queue
  
  'paddles to restore when destroyed
  As Integer paddle(1 To paddle_side_enum.max, 1 to 2)
  
  as integer total
  as orb_object_type object(1 To max)
End Type

'Dim Shared As orb_object_type orb_object(1 To orb_type.max)
Dim Shared As orb_type orb
