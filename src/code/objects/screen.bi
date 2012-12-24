
Type screen_type
  'contains info for the screenres, because the display has to be scaled while aspect ratio is constant
  'default is XGA, because GFX are made for that resolution, but game will be preset for VGA
  'note that default is the virtual screen size, not the preferred playing size
  Const default_sx = 1024 * dsfactor, default_sy = 768 * dsfactor
  const default_aspect = default_sx / default_sy
  
  const min_sx = 240, min_sy = 180
  const safe_sx = 640, safe_sy = 480
  const preferred_sx = 1024, preferred_sy = 768
  const max_sx = 8000, max_sy = 6000
  
  Declare Sub finish()
  Declare Function scale_x Overload (Byval x As Integer) As Integer
  Declare Function scale_y Overload (Byval y As Integer) As Integer
  Declare Function scale_x Overload (Byval x As Double) As Integer
  Declare Function scale_y Overload (Byval y As Double) As Integer
  Declare Function unscale_x (Byval x As Integer) As Integer
  Declare Function unscale_y (Byval y As Integer) As Integer
  Declare Sub set (Byval x As Integer, Byval y As Integer)
  Declare Sub start ()
  
  'note: all variables need to be set at the same time or they will have conflicting values
  As float scale 'ie on 1600 * 1200: scale = 1.5625
  As Integer corner_sx, corner_sy 'need some clipping on monitors with other aspect ratios
  As Integer screen_sx, screen_sy
  As Integer view_sx, view_sy
  
  superfluous As hwnd gamewindow
End Type

dim shared as screen_type screen
