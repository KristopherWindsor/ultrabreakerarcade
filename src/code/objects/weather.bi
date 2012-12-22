
Enum weather_enum
  min        = 33
  
  wind       = 33 '6 sliding bricks
  rain       = 34 '7 rain gravity
  fireworks  = 35 '8 random fireworks explode random bricks
  metal      = 36 '9 gfx effect only
  
  max        = 36
End Enum

Type weather_fireworks_object_type
  
  Declare Sub display ()
  Declare Sub move ()
  
  As Double x, y, xv, yv, scale, angle
  As Integer alpha
End Type

Type weather_graphic_type
  Const fireworks_sr = 60, fireworks_sd = fireworks_sr * 2
  
  Declare Sub start ()
  Declare Sub gfxchange ()
  Declare Sub finish ()
  
  superfluous As fb.image Ptr fireworks
  server_dummy
End Type

Type weather_type
  Const fireworks_max = 8
  
  const fireworks_scale_initial = .5 * dsfactor
  const fireworks_scale_max = 2 * dsfactor
  const fireworks_scale_step = .025 * dsfactor
  
  const fireworks_startoffset = 100 * dsfactor
  const fireworks_speed_x = 5 * dsfactor
  const fireworks_speed_y_min = -14 * dsfactor
  const fireworks_speed_y_max = -7 * dsfactor
  const fireworks_speed_y_explode = 5 * dsfactor
  
  const fireworks_rotationspeed = .016
  
  const rain_speed_x_min = -1 * dsfactor
  const rain_speed_x_max = 1 * dsfactor
  
  const rain_speed_y_min = 2 * dsfactor
  const rain_speed_y_max = 4 * dsfactor
  
  const rain_startoffset = -80 * dsfactor
  
  const wind_speed_min = 1 * dsfactor
  const wind_speed_max = 4 * dsfactor
  
  const wind_shape_size = 200 * dsfactor
  const wind_brick_size = screen_type.default_sx / (12 * brick.graphic.brick_sx)
  const wind_brick_value = 5
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub add (Byval climate As weather_enum)
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  
  As Integer is_wind, is_rain, is_fireworks, is_metal ', is_unknown
  
  'weather moves the objects because they don't know the velocity
  
  As Integer wind_xv
  As Double rain_xv, rain_yv
  
  As Integer fireworks_total
  As weather_fireworks_object_type fireworks(1 To fireworks_max)
  
  As weather_graphic_type graphic
End Type

declare sub weather_gfxchange_threadable (Byval nothing As Any Ptr = 0)

Dim Shared As weather_type weather
