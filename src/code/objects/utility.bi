
Enum utility_file_mode_enum
  for_input  = 1
  for_output = 2
  for_binary = 4
  for_append = 3
End Enum

Type utility_font_setting_type
  'c, c_back, scale, rotation, clipping, alpha
  
  Declare Constructor ()
  
  As Uinteger c, c_back 'colors; background color is needed if scaling, rotation, or alpha is used; alpha channel does affect
  As Double scale, rotation 'provided by multiput
  As Integer clipping 'clipping is string trimmming (if length specified in pixels is set)
End Type

Type utility_font_type
  'note: font height is specified here
  'note: font width is specified in the font data file (since width is variable; not needed in the menu, etc.)
  
  Const fontspacing = 1.2 'keeps consistant spacing on menus and other parts
  Const font_pt_max = 6, font_pt_default = screen_type.default_sx \ 32 'font for default font size
  
  Declare Sub start ()
  Declare Sub screenchange ()
  Declare Sub show overload (Byref t As String, Byval x As Integer, Byval y As Integer)
  Declare Sub show overload (Byref t As String, Byval x As Integer, Byval y As Integer, _
    Byval settings As utility_font_setting_type)
  Declare Sub finish ()
  
  As Integer fontheight 'scaled to work with the default scale coords
  As Integer font_pt_selected
  As Integer font_pt(1 To font_pt_max) = {10, 20, 25, 32, 40, 50}
  As utility_font_setting_type setting_default
  
  superfluous As abfont.alpha_font abf
End Type

Type utility_framerate_type
  'keeps a timer; slows to keep a constant fps; determines how frequently the program can display
  
  Const displaylog_max = 20
  
  Declare Constructor (Byval ifps_loop As Integer = 60, Byval ifps_display_min As Integer = 10, Byval ifps_display_max As Integer = 72)
  
  Declare Sub Reset ()
  Declare Sub move ()
  Declare Function candisplay () As Integer 'if this returns true, t_display is set, because the display should be updated
  Declare Sub fixtimeout () 'if game paused for 30 seconds, just call this to get the framerate working again
  
  As Integer fps_loop, fps_display_min, fps_display_max
  
  As Integer loop_total
  As Double t, t_previous, t_start 'timer, timer for previous frame and start timer
  As Double loop_lag 'time when the display was last updated; how much the game is behind the optimal frame rate
  
  'log the last display times; use this to estimate the display fps
  As Double displaylog(1 To displaylog_max)
End Type

Type utility_graphic_type
  Const ball_sx = 240, ball_sy = ball_sx
  const menubackground_sx = 800, menubackground_sy = 600
  'Const menu_sx = data_screen_type.default_sx, menu_sy = data_screen_type.default_sy
  
  Declare Sub start ()
  Declare Sub screenchange ()
  Declare Sub finish ()
  
  declare sub clearpreviews () 'destroy all previews
  declare sub loadpreview () 'load next preview (needs to be called repeatedly)
  declare sub savepreview () 'save a png level preview
  
  declare sub loadlevelpackpreview () 'load next preview (needs to be called repeatedly)
  declare sub reloadlevelpackpreview (index as integer)
  
  superfluous As fb.image Ptr ball, menubackground
  'window size (like screenshot, but only for level previews); 320 * 240
  superfluous as fb.image ptr previewshot, previewshot_thumb
  'window size, always; x * 240
  superfluous As fb.image Ptr screenshot, screenshot_thumb
  superfluous As fb.image Ptr font_temp
  
  superfluous as integer levelpreview_total
  superfluous as fb.image ptr levelpreview(1 to 256) 'max levels per pack
  
  superfluous as integer levelpackpreview_total
  superfluous as fb.image ptr levelpackpreview(1 to 32) 'max levelpacks
  
  As Integer totalimages 'total number of images loaded
End Type

type utility_type
  
  declare sub start ()
  declare sub screenchange ()
  declare sub finish ()
  declare sub consmessage (Byref e As String)
  declare function formattime (Byval t As Integer) As String
  declare function getclipboard () As String
  declare function gettext (byref title as string = "") As String
  declare sub logerror (Byref e As String)
  declare function openfile (Byref filename As String, _
    Byval mode As Integer, Byval ignoreerrors As Integer = false) As Integer
  declare function percentage (p as double) as string
  declare sub showloading (Byref text As String)
  
  #ifndef server_validator
  declare sub loadimage (Byref filename As String, Byref graphic As fb.image Ptr)
  #ifdef debug
    declare Function createimage (Byval x As Integer, Byval y As Integer, Byref s As String, _
      Byval c As Uinteger = color_enum.transparent) As fb.image Ptr
    declare Sub deleteimage (Byref g As fb.image Ptr, Byref s As String)
  #else
    declare Function createimage (Byval x As Integer, Byval y As Integer, _
      Byval c As Uinteger = color_enum.transparent) As fb.image Ptr
    declare Sub deleteimage (Byref g As fb.image Ptr)
  #endif
  #endif
  
  As utility_font_type font
  As utility_graphic_type graphic
  
  as any ptr threadmutex
end type

dim shared as utility_type utility
