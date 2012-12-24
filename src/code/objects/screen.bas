
Sub screen_type.start ()
  #ifndef server_validator
  Dim As Integer f, x, y
  
  f = utility.openfile("data/screen.txt", utility_file_mode_enum.for_input)
  Input #f, x, y
  Close #f
  
  set(x, y)
  #Endif
End Sub

Sub screen_type.set (Byval x As Integer, Byval y As Integer)
  #ifndef server_validator
  Dim As Double aspect
  
  If x = screen_sx And y = screen_sy Then Exit Sub 'no change
  
  aspect = x / y
  screen_sx = x
  screen_sy = y
  
  Select Case Sgn(default_aspect - aspect)
  Case -1
    'monitor is widescreen
    scale = y / default_sy
    corner_sx = (x - (scale * default_sx)) / 2
    corner_sy = 0
  Case 0
    'monitor is normal aspect ratio (4:3)
    scale = x / default_sx
    corner_sx = 0
    corner_sy = 0
  Case 1
    'monitor is anti-widescreen (1280 * 1024)
    scale = x / default_sx
    corner_sx = 0
    corner_sy = (y - (scale * default_sy)) / 2
  End Select
  
  view_sx = default_sx * scale
  view_sy = default_sy * scale
  
  Screenres x, y, 32,, fb.gfx_high_priority
  Windowtitle("Ultrabreaker")
  gamewindow = FindWindow(NULL, "UltraBreaker")
  
  If Screenptr() = 0 Then
    If x = safe_sx And y = safe_sy Then
      utility.logerror("Cannot initialize screen: VGA")
      System() 'crash!
    Else
      'attempt the most compatible size
      utility.logerror("Cannot initialize screen: " & x & ", " & y)
      set(safe_sx, safe_sy)
    End If
  End If
  
  'rescale gfx
  If main.programstarted Then main.screenchange()
  #Endif
End Sub

Function screen_type.scale_x Overload (Byval x As Integer) As Integer
  'convert a coord in the 1024 * 768 window to a pixel coord for displaying
  Return x * scale + corner_sx
End Function

Function screen_type.scale_y Overload (Byval y As Integer) As Integer
  Return y * scale + corner_sy
End Function

Function screen_type.scale_x Overload (Byval x As Double) As Integer
  'convert a coord in the 1024 * 768 window to a pixel coord for displaying
  Return x * scale + corner_sx
End Function

Function screen_type.scale_y Overload (Byval y As Double) As Integer
  Return y * scale + corner_sy
End Function

Function screen_type.unscale_x (Byval x As Integer) As Integer
  'ie convert getmouse() coords to simulate the coords that would be given if using default resolution
  Dim As Integer r = (x - corner_sx) / scale
  If r >= default_sx Then r = default_sx - 1
  If r < 0 Then r = 0
  Return r
End Function

Function screen_type.unscale_y (Byval y As Integer) As Integer
  Dim As Integer r = (y - corner_sy) / scale
  If r >= default_sy Then r = default_sy - 1
  If r < 0 Then r = 0
  Return r
End Function

Sub screen_type.finish ()
  #ifndef server_validator
  Dim As Integer f
  
  f = utility.openfile("data/screen.txt", utility_file_mode_enum.for_output)
  Print #f, screen_sx, screen_sy
  Close #f
  #Endif
End Sub
