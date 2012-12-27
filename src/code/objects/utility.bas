
Sub utility_type.start ()
  graphic.start()
  font.start()
End Sub

Sub utility_type.screenchange ()
  font.screenchange()
  graphic.screenchange()
End Sub

Sub utility_type.finish ()
  graphic.finish()
  font.finish()
  
  if utility.graphic.totalimages <> 0 then
    utility.logerror("Total undestroyed images: " & utility.graphic.totalimages)
  end if
End Sub

Sub utility_type.consmessage (Byref e As String)
  Dim As Integer f = Freefile()
  Open cons For Output As #f
  Print #f, e
  Close #f
End Sub

#ifndef server_validator
#ifdef debug
  Function utility_type.createimage (Byval x As Integer, Byval y As Integer, Byref s As String, _
    Byval c As Uinteger = color_enum.transparent) As fb.image Ptr
    
    If x < 1 Then x = 1
    If y < 1 Then y = 1
    
    graphic.totalimages += 1
    logerror("image new " & graphic.totalimages & " " & s)
    
    Return imagecreate(x, y, c)
  End Function
  
  Sub utility_type.deleteimage (Byref g As fb.image Ptr, Byref s As String)
    If g = 0 Then
      logerror("cannot destroy null image")
      Exit Sub
    End If
    
    imagedestroy(g)
    g = 0
    
    graphic.totalimages -= 1
    logerror("image die " & graphic.totalimages & " " & s)
  End Sub
#else
  Function utility_type.createimage (Byval x As Integer, Byval y As Integer, _
    Byval c As Uinteger = color_enum.transparent) As fb.image Ptr
    
    If x < 1 Then x = 1
    If y < 1 Then y = 1
    
    graphic.totalimages += 1
    
    Return imagecreate(x, y, c)
  End Function
  
  Sub utility_type.deleteimage (Byref g As fb.image Ptr)
    If g = 0 Then
      logerror("cannot destroy null image")
      Exit Sub
    End If
    
    imagedestroy(g)
    g = 0
    
    graphic.totalimages -= 1
  End Sub
#endif
#endif

Function utility_type.formattime (Byval t As Integer) As String
  Dim As Integer m, s
  
  If t <= 0 Then Return "0"
  
  m = Int(t / (game.fps * 60))
  s = Int(t / game.fps) Mod 60
  
  If s = 0 Then Return m & ":00"
  If s < 10 Then Return m & ":0" & s
  Return m & ":" & s
End Function

Function utility_type.getclipboard () As String
  #ifndef server_validator
  Dim As Zstring Ptr s_ptr
  Dim As HANDLE hglb
  Dim As String s = ""

  If (IsClipboardFormatAvailable(CF_TEXT) = 0) Then Return ""

  If OpenClipboard( NULL ) <> 0 Then
    hglb = GetClipboardData(cf_text)
    s_ptr = GlobalLock(hglb)
    If (s_ptr <> NULL) Then
      s = *s_ptr
      GlobalUnlock(hglb)
    End If
    CloseClipboard()
  End If

  Return s
  
  #Else
  Return ""
  #Endif
End Function

Function utility_type.gettext (Byref default As String = "", _
  Byval readonly As Integer = false, byref title as string = "") As String
  'ask the user to type a cheat / highscore entry player name
  #ifndef server_validator
  
  #define text_width(t) font.abf.gettextwidth(font.font_pt_selected, t)
  
  Const margin = 50 * dsfactor, char_max = 16
  Const fieldwidth = screen.default_sx - margin * 4, fieldheight = screen.default_sy / 2 - margin * 3
  Const char_disallowed = Chr(9, 10)
  Const whitelist = "qwertyuiopasdfghjklzxcvbnm1234567890() !?:$-+_="
  
  Enum object_hover_enum
    none        = 0
    closebutton = 1
    textfield   = 2
  End Enum
  
  Dim As Integer quit
  Dim As Integer text_cursor, text_cursor_x, text_selected, text_sy, text_y
  Dim As Double animate_drop, animate_drop_start, animate_curve, tx, ty
  Dim As String key, text
  
  Dim As object_hover_enum object_hover
  
  Dim As utility_font_setting_type fonttype
  Dim As utility_framerate_type framerate = utility_framerate_type()
  
  If readonly And Len(default) = 0 Then Return ""
  
  Screenlock()
  xfx.graphic.effect_grayscale()
  Get (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), graphic.screenshot
  Screenunlock()
  
  framerate.reset()
  
  animate_drop_start = -(margin * 4 + fieldheight + screen.corner_sy / screen.scale)
  animate_drop = animate_drop_start
  text = default
  If readonly = false Then text_cursor = Len(text)
  text_selected = (Len(text) > 0) And (readonly = false)
  text_sy = this.font.abf.gettextheight(this.font.font_pt_selected)
  text_y = margin * 4 + fieldheight / 2 - text_sy / screen.scale
  
  Do
    framerate.move()
    sound.move()
    
    With mouse
      .update()
      
      'set object hover
      If .c.b = 0 Then
        object_hover = object_hover_enum.none
        
        tx = .c.sx - (margin + fieldwidth + animate_curve)
        ty = .c.sy - (margin * 3 + fieldheight + animate_drop)
        If Sqr(tx * tx + ty * ty) < margin Then
          
          object_hover = object_hover_enum.closebutton
        Elseif .c.sx > margin * 3 And .c.sx < margin * 3 + text_width(text) / screen.scale And .c.sy > text_y + animate_drop And _
          .c.sy < text_y + animate_drop + text_sy / screen.scale Then
          
          object_hover = object_hover_enum.textfield
        End If
      End If
      
      'action when mouse button is down
      If .c.b > 0 Then
        Select Case object_hover
        Case object_hover_enum.closebutton
          If readonly Or Len(text) > 0 Then quit = true: sound.add(sound_enum.menu_select)
        Case object_hover_enum.textfield
          'find the closest two cursor positions to the mouse, then see which one is closer
          If Len(text) > 0 And readonly = false Then
            tx = .c.sx - margin * 3
            For i As Integer = 0 To Len(text)
              If text_width(Left(text, i)) / screen.scale < tx Then ty = i
            Next i
            If Abs(text_width(Left(text, ty)) / screen.scale - tx) < Abs(text_width(Left(text, ty + 1)) / screen.scale - tx) Then
              text_cursor = ty
            Else
              text_cursor = ty + 1
            End If
            text_selected = false
          End If
        End Select
      End If
    End With
    
    key = Inkey()
    Select Case key
    Case ""
    Case Chr(13), Chr(27)
      'close
      If readonly Or Len(text) > 0 Then quit = true: sound.add(sound_enum.menu_select)
    Case Else
      'unless closing function, play a sound
      sound.add(sound_enum.menu_changeselected)
    End Select
    
    If readonly = false Then
      Select Case key
      Case Chr(13), Chr(27)
        'these events handled above (even if readonly)
      Case Chr(8)
        'backspace
        If text_selected Then
          text = ""
          text_cursor = 0
        Elseif Len(text) > 0 And text_cursor > 0 Then
          text_cursor -= 1
          text = Left(text, text_cursor) & Mid(text, text_cursor + 2)
        End If
      Case Chr(255, 83)
        'delete
        If text_selected Then
          text = ""
          text_cursor = 0
        Elseif text_cursor < Len(text) Then
          text = Left(text, text_cursor) & Mid(text, text_cursor + 2)
        End If
      Case Chr(255, 75)
        'left
        text_selected = false
        If text_cursor > 0 Then text_cursor -= 1
      Case Chr(255, 77)
        'right
        text_selected = false
        If text_cursor < Len(text) Then text_cursor += 1
      Case Chr(255, 71)
        'home
        text_cursor = 0
      Case Chr(255, 79)
        'end
        text_cursor = Len(text)
      Case Chr(22)
        'paste
        text_selected = true
        text = getclipboard()
        For i As Integer = Len(text) To 1 Step -1
          If Instr(whitelist, Mid(text, i, 1)) = 0 Then text = Left(text, i - 1) & Mid(text, i + 1)
        Next i
        If Len(text) > char_max Then text = Left(text, char_max)
        text_cursor = Len(text)
      Case Else
        If Len(key) = 1 Then
          If text_selected Then
            text_selected = false
            text = ""
            text_cursor = 0
          End If
          If Len(text) < char_max And Instr(whitelist, Lcase(key)) > 0 Then
            text = Left(text, text_cursor) & key & Mid(text, text_cursor + 1)
            text_cursor += 1
          End If
        End If
      End Select
    End If
      
    If quit Then
      animate_drop -= 12 * dsfactor
      If animate_curve > 0 Then animate_curve -= 1
    Else
      animate_drop += 12 * dsfactor
      If animate_drop > 0 Then animate_drop = 0
      If animate_drop = 0 And animate_curve < margin Then animate_curve += dsfactor
    End If
    
    text_cursor_x = text_width(Left(text, text_cursor))
    If text_selected Then fonttype.c_back = &H66FFFFFF Else fonttype.c_back = 0
    
    If framerate.candisplay() Then
      Screenlock()
      Put (0, 0), graphic.screenshot, Pset
      'support
      Line (screen.scale_x(margin + fieldwidth), 0) - _
        (screen.scale_x(margin * 2 + fieldwidth), screen.scale_y(margin * 4 + animate_drop)), color_enum.green, BF
      'info box
      Line (screen.scale_x(margin * 2), screen.scale_y(margin * 4 + animate_drop)) - _
        (screen.scale_x(margin * 2 + fieldwidth), screen.scale_y(margin * 4 + fieldheight + animate_drop)), _
        color_enum.green, BF
      'curved edges
      If animate_curve Then
        'curved edge on left
        Line (screen.scale_x(margin * 2 - animate_curve), screen.scale_y(margin * 5 + animate_drop)) - _
          (screen.scale_x(margin * 3 - animate_curve), screen.scale_y(margin * 3 + fieldheight + animate_drop)), _
          color_enum.green, BF
        Circle (screen.scale_x(margin * 3 - animate_curve) + 1, screen.scale_y(margin * 5 + animate_drop)), _
          screen.scale * margin, color_enum.green,,, 1, F
        Circle (screen.scale_x(margin * 3 - animate_curve) + 1, screen.scale_y(margin * 3 + fieldheight + animate_drop)), _
          screen.scale * margin, color_enum.green,,, 1, F
        'curved edge on right (includes close button)
        Line (screen.scale_x(margin + fieldwidth + animate_curve), screen.scale_y(margin * 5 + animate_drop)) - _
          (screen.scale_x(margin * 2 + fieldwidth + animate_curve), screen.scale_y(margin * 3 + fieldheight + animate_drop)), _
          color_enum.green, BF
        Circle (screen.scale_x(margin + fieldwidth + animate_curve) - 1, screen.scale_y(margin * 5 + animate_drop)), _
          screen.scale * margin, color_enum.green,,, 1, F
        'close button
        Circle (screen.scale_x(margin + fieldwidth + animate_curve) - 1, screen.scale_y(margin * 3 + fieldheight + animate_drop)), _
          screen.scale * margin * Iif(object_hover = object_hover_enum.closebutton, 2, 1), _
          Iif(animate_curve = margin Or object_hover = object_hover_enum.closebutton, color_enum.black, color_enum.green),,, 1, F
      End If
      
      'text
      if len(title) > 0 then
        line (screen.scale_x(0), screen.scale_y(screen.default_sy - _
          font.abf.gettextheight(font.font_pt_selected) / screen.scale)) - _
          (screen.scale_x(screen.default_sx), screen.scale_y(screen.default_sy)), _
          color_enum.white, BF
        font.show(title, margin * 3, screen.default_sy - _
          font.abf.gettextheight(font.font_pt_selected) / screen.scale)
      end if
      If Len(text) > 0 Then
        this.font.show(text, margin * 3, text_y + animate_drop, fonttype)
      End If
      
      'cursor
      If ((framerate.loop_total Mod framerate.fps_loop) > framerate.fps_loop * .5 Or _
        object_hover = object_hover_enum.textfield) And readonly = false Then
        
        Line (screen.scale_x(margin * 3) + text_cursor_x, screen.scale_y(text_y + animate_drop)) - _
          Step(0, text_sy), color_enum.black
      End If
      
      xfx.graphic.glow_show(mouse.c.sx, mouse.c.sy)
      
      Screenunlock()
    End If
  Loop Until quit And animate_drop < animate_drop_start
  
  Return Trim(text)
  
  #Else
  Return ""
  #Endif
End Function

#ifndef server_validator
Sub utility_type.loadimage (Byref filename As String, Byref graphic As fb.image Ptr)
  
  Dim As Integer f
  Dim As fb.image Ptr temp
  
  temp = png_load("data/graphics/" & filename & ".png", PNG_TARGET_FBNEW)
  If temp = 0 Then
    logerror("Cannot load image: " & filename)
    Exit Sub
  End If
  
  if graphic->width <> temp->width or graphic->height <> temp->height then
    line graphic, (0, 0) - step(graphic->width - 1, graphic->height - 1), color_enum.transparent, BF
    Put graphic, (0, 0), temp, Pset
    imagedestroy(temp)'png_destroy(temp)
  else
    imagedestroy(graphic)
    graphic = temp
  end if
End Sub
#endif

Sub utility_type.logerror (Byref e As String)
  Dim As Integer f = Freefile()
  
  Open "errorlog.txt" For Append As #f
  Print #f, Date & Chr(9) & Time & Chr(9) & e
  Close #f
End Sub

Function utility_type.openfile (Byref filename As String, Byval mode As Integer, Byval ignoreerrors As Integer = false) As Integer
  #define se If ignoreerrors = false Then
  
  Dim As Integer f
  
  Mutexlock(threadmutex)
  
  f = Freefile()
  Select Case mode
  Case utility_file_mode_enum.for_input
    If Open(filename For Input As #f) Then
      se logerror("File cannot be opened for input: " & filename)
      Function = false
    Else
      Function = f
    End If
  Case utility_file_mode_enum.for_output
    If Open(filename For Output As #f) Then
      se logerror("File cannot be opened for output: " & filename)
      Function = false
    Else
      Function = f
    End If
  Case utility_file_mode_enum.for_binary
    If Open(filename For Binary As #f) Then
      se logerror("File cannot be opened for binary: " & filename)
      Function = false
    Else
      Function = f
    End If
  Case utility_file_mode_enum.for_append
    If Open(filename For Append As #f) Then
      se logerror("File cannot be opened for append: " & filename)
      Function = false
    Else
      Function = f
    End If
  End Select
  
  Mutexunlock(threadmutex)
End Function

function utility_type.percentage (p as double) as string
  return cint(100 * p) & "%"
end function

Sub utility_type.showloading (Byref text As String)
  #ifndef server_validator
  Dim As utility_font_setting_type font
  
  Screenlock()
  xfx.graphic.effect_grayscale()
  Line (screen.scale_x(0), _
    screen.scale_y(screen.default_sy * .391)) - _
    (screen.scale_x(screen.default_sx), _
    screen.scale_y(screen.default_sy * .442 + this.font.fontheight)), _
    color_enum.white, BF
  this.font.show(text, _
    screen.default_sx * .0097, _
    screen.default_sy * .417, font)
  Screenunlock()
  Screensync()
  #Endif
End Sub

Sub utility_font_type.start ()
  #ifndef server_validator
  For i As Integer = 1 To font_pt_max
    abf.loadfont("data/font/font" & font_pt(i) & ".abf", i)
  Next i
  #Endif
End Sub

Sub utility_font_type.screenchange ()
  'select the correct font slot by seeing which font is closest to the right value
  #ifndef server_validator
  
  Dim As Double e, e_current
  
  e_current = 1E8
  
  For i As Integer = 1 To font_pt_max
    e = Abs(font_pt_default * screen.scale - font_pt(i))
    If e < e_current Then
      e_current = e
      font_pt_selected = i
    End If
  Next i
  
  fontheight = abf.gettextheight(font_pt_selected) / screen.scale
  #Endif
End Sub

Constructor utility_font_setting_type ()
  c = color_enum.black
  c_back = 0
  scale = 1
  rotation = 0
  clipping = 0
End Constructor

Sub utility_font_type.show overload (Byref t As String, Byval x As Integer, Byval y As Integer)
  dim as utility_font_setting_type settings
  show(t, x, y, settings)
end sub

Sub utility_font_type.show overload (Byref t As String, Byval x As Integer, Byval y As Integer, _
  Byval settings As utility_font_setting_type)
  #ifndef server_validator
  
  'length and height are based on the screen scale, because each screen size uses a different font size
  #define font_length abf.gettextwidth(font_pt_selected, text)
  #define font_height abf.gettextheight(font_pt_selected)
  
  Dim As Integer thefont, displaylength
  Dim As String text = t
  Dim As fb.image Ptr graphic
  
  'text color alpha channel matters, but background color alpha channel does not
  'set the alpha value in the text color for direct blending (text on screen); use the alpha param to blend background onto screen
  'displaylength will be for the font at its normal size, so the clipping has to be divided by the scaling factor
  'if clipping is set, then show the background for that length, not the length of the text
  '2px padding is always 2px regardless of screen scale; larger for scaled text
  
  'colors can be set for direct display mode
  'alpha requires indirect buffer
  'scaling and / or clipping require multiput() (and an indirect buffer)
  'use of an indirect buffer requires a background color
  
  if len(t) = 0 then return
  
  With settings 'c, c_back, scale, rotation, clipping, alpha
    displaylength = font_length
    
    'clip string
    If .clipping > 0 Then
      .clipping = .clipping * screen.scale / .scale  - 4
      If displaylength > .clipping Then
        'shorten based on the overflow and the average width of each character
        text = Left(text, Len(text) - (displaylength - .clipping) / (displaylength / Len(text)))
        displaylength = font_length
        
        While displaylength > .clipping
          text = Left(text, Len(text) - 1)
          displaylength = font_length
        Wend
      End If
      
      displaylength = .clipping
    End If
    
    If .scale = 1 And .rotation = 0 Then
      'direct mode (fast and supports alpha blending of font onto screen)
      
      'draw the background (do not let abf do this because we want the background to be longer)
      If .c_back > 0 Then
        If .c_back Shr 24 = &HFF Then
          Line (screen.scale_x(x), screen.scale_y(y)) - _
            Step(displaylength, abf.gettextheight(font_pt_selected) - 1), .c_back, BF
        Else
          'alpha blending for the background (not available with the multiput version)
          Line utility.graphic.font_temp, (0, 0) - (displaylength - 1, font_height - 1), .c_back, BF
          Put (screen.scale_x(x), screen.scale_y(y)), utility.graphic.font_temp, _
            (0, 0) - (displaylength - 1, font_height - 1), alpha, .c_back Shr 24
        End If
      End If
      
      abf.draw(font_pt_selected, screen.scale_x(x), screen.scale_y(y), text, .c)
    Else
      'draw to a buffer, then display with multiput()
      
      'if you are going to display via an image buffer, you need a background color
      If .c_back = 0 Then .c_back = .c Xor &HFFFFFF
      
      graphic = utility.createimage(displaylength, font_height mop("font temp"), .c_back)
      
      abf.draw(graphic, font_pt_selected, 0, 0, text, .c)
      
      'multiput transformation
      multiput(, _
        screen.scale_x(x + .scale / screen.scale * (graphic -> Width) Shr 1), _
        screen.scale_y(y + .scale / screen.scale * (graphic -> height) Shr 1), _
        graphic, .scale,, .rotation)
      
      utility.deleteimage(graphic mop("font temp"))
    End If
  End With
  #Endif
End Sub

Constructor utility_framerate_type (Byval ifps_loop As Integer = 60, Byval ifps_display_min As Integer = 10, _
  Byval ifps_display_max As Integer = 72)
  fps_loop = ifps_loop
  fps_display_min = ifps_display_min
  fps_display_max = ifps_display_max
  Reset()
End Constructor

Sub utility_font_type.finish ()
  #ifndef server_validator
  For i As Integer = 1 To font_pt_max
    abf.unloadfont(i)
  next i
  #endif
end sub

Sub utility_framerate_type.reset ()
  loop_total = 0
  loop_lag = 0
  t_start = Timer()
  t = t_start
  For i As Integer = 1 To displaylog_max
    displaylog(i) = 0
  Next i
End Sub

Sub utility_framerate_type.move ()
  'use this at the beginning of the frame
  
  t_previous = t
  t = Timer
  loop_lag += t - t_previous
  If loop_lag > .2 Then loop_lag = .2 'never "catch up" for more than a fifth of a second
  
  'idle after previous frame (logically this would be at the end of the loop, not the beginning)
  While loop_lag < 0
    If setting.cpuhog >= 2 Then Sleep(1, 1)
    t_previous = t
    t = Timer
    loop_lag += t - t_previous
  Wend
  
  'begin new frame
  loop_total += 1
  
  t_previous = t
  t = Timer
  loop_lag += t - t_previous - 1 / fps_loop
End Sub

Function utility_framerate_type.candisplay () As Integer
  Dim As Integer r, testpoint
  Dim As Double fps 'estimated rate of display based on time since last display update
  
  If displaylog(displaylog_max) = 0 Then
    'don't have all the data to calculate the display FPS (frames just starting)
    testpoint = displaylog_max
    While testpoint > 1 And displaylog(testpoint) = 0
      testpoint -= 1
    Wend
    If testpoint > 1 Then fps = testpoint / (t - displaylog(testpoint)) Else fps = fps_display_min
  Else
    fps = displaylog_max / (t - displaylog(displaylog_max))
  End If
  
  If fps <= fps_display_min Then
    'it's been so long since the last display, display even though it will slow down the game
    'note that fps_display_min is the literal min fps; if the rate drops below this value, the program is displaying every frame
    r = true
  Elseif fps >= fps_display_max Then
    'don't even bother getting more than the max fps
    r = false
  Else
    r = loop_lag < 0
  End If
  
  If r Then
    'will display
    If setting.cpuhog = 3 Then Sleep(4, 1)
    If setting.cpuhog = 4 Then Sleep(6, 1)
    For i As Integer = displaylog_max - 1 To 1 Step -1
      Swap displaylog(i), displaylog(i + 1)
    Next i
    displaylog(1) = t
    'vsync
    If setting.vsync Then screensync()
  End If
  
  Return r
End Function

Sub utility_framerate_type.fixtimeout ()
  t_previous = t
  t = Timer
  
  For i As Integer = 1 To displaylog_max
    If displaylog(i) > 0 Then displaylog(i) += t - t_previous
  Next i
End Sub

Sub utility_graphic_type.start ()
  #ifndef server_validator
  ball = utility.createimage(ball_sx, ball_sy mop("utility ball"))
  utility.loadimage("ball", ball)
  menubackground = utility.createimage(menubackground_sx, menubackground_sy mop("utility menubackground"))
  utility.loadimage("menubackground", menubackground)
  font_temp = utility.createimage(1000, 100 mop("utility font temp"))
  #Endif
End Sub

Sub utility_graphic_type.screenchange ()
  #ifndef server_validator
  
  If previewshot > 0 Then utility.deleteimage(previewshot mop("utility previewshot"))
  previewshot = utility.createimage(screen.screen_sx, screen.screen_sy mop("utility previewshot"))
  
  If previewshot_thumb > 0 Then utility.deleteimage(previewshot_thumb mop("utility previewshot thumb"))
  previewshot_thumb = utility.createimage(320, 240 mop("utility previewshot thumb"))
  
  If screenshot > 0 Then utility.deleteimage(screenshot mop("utility screenshot"))
  screenshot = utility.createimage(screen.screen_sx, screen.screen_sy mop("utility screenshot"))
  
  If screenshot_thumb > 0 Then utility.deleteimage(screenshot_thumb mop("utility screenshot thumb"))
  screenshot_thumb = utility.createimage(240 * screen.screen_sx / screen.screen_sy, 240 mop("utility screenshot thumb"))
  #Endif
End Sub

Sub utility_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(ball mop("utility ball"))
  utility.deleteimage(menubackground mop("utility menubackground"))
  utility.deleteimage(previewshot mop("utility previewshot"))
  utility.deleteimage(previewshot_thumb mop("utility previewshot thumb"))
  utility.deleteimage(screenshot mop("utility screenshot"))
  utility.deleteimage(screenshot_thumb mop("utility screenshot thumb"))
  utility.deleteimage(font_temp mop("utility font_temp"))
  clearpreviews()
  
  for i as integer = 1 to levelpackpreview_total
    utility.deleteimage(levelpackpreview(i) mop("utility levelpackpreview"))
  next i
  levelpackpreview_total = 0
  #Endif
End Sub

Sub utility_graphic_type.clearpreviews ()
  'destroy all previews, because game is ending or levelpack changed
  
  #ifndef server_validator
  for i as integer = 1 to levelpreview_total
    utility.deleteimage(levelpreview(i) mop("utility levelpreview"))
  next i
  levelpreview_total = 0
  #endif
end sub

sub utility_graphic_type.loadlevelpackpreview ()
  #ifndef server_validator
  
  #define lppt utility.graphic.levelpackpreview_total
  
  if lppt >= main.levelpack.list_total then return
  
  lppt += 1
  
  dim as integer f
  dim as string filename
  
  filename = "levelpacks/" & lcase(main.levelpack.list(lppt).title) & "/1"
  var g = utility.createimage(320, 240 mop("utility levelpackpreview"), color_enum.black)
  line g, (9, 9) - (310, 230), color_enum.transparent, BF
  draw string g, (72, 100), "[No preview available]", color_enum.black
  f = utility.openfile("data/" & filename & ".png", utility_file_mode_enum.for_input, true)
  if f > 0 then
    close #f
    utility.loadimage("../" & filename, g)
  end if
  
  utility.graphic.levelpackpreview(lppt) = g
  
  #endif
end sub

sub utility_graphic_type.reloadlevelpackpreview (index as integer)
  #ifndef server_validator
  
  dim as integer f
  dim as string filename
  
  if utility.graphic.levelpackpreview(index) = 0 then return
  
  filename = "levelpacks/" & lcase(main.levelpack.list(index).title) & "/1"
  f = utility.openfile("data/" & filename & ".png", utility_file_mode_enum.for_input, true)
  if f > 0 then
    close #f
    utility.loadimage("../" & filename, utility.graphic.levelpackpreview(index))
  end if
  
  #endif
end sub

Sub utility_graphic_type.loadpreview ()
  'load next level preview
  #ifndef server_validator
  
  dim as integer f
  dim as string filename
  
  if levelpreview_total >= main.levelpack.level_total or levelpreview_total > main.levelpack.unlockedtotal then return
  levelpreview_total += 1
  
  var g = utility.createimage(320, 240 mop("utility levelpreview"), color_enum.black)
  levelpreview(levelpreview_total) = g
  line g, (9, 9) - (310, 230), color_enum.transparent, BF
  'draw string g, (72, 100), "[No preview available]", color_enum.black
  draw string g, (120, 100), "New Level!", color_enum.black
  
  filename = "levelpacks/" + lcase(main.levelpack.title) + _
    "/" & levelpreview_total
  f = utility.openfile("data/" & filename & ".png", utility_file_mode_enum.for_input, true)
  if f > 0 then
    close #f
    utility.loadimage("../" & filename, levelpreview(levelpreview_total))
  end if
  
  #endif
end sub

Sub utility_graphic_type.savepreview ()
  'scale the screenshot in previewshot, then saves as level preview (png)
  'also puts image in levelpreviews array, if it was supposed to be loaded already
  'assumes images exist in memory and not on disk; only call in this case
  #ifndef server_validator
  
  dim as double s
  
  'get screens for website
  if ucase(command(1)) = "GETSCREENS" then
    var nada = mkdir("levelshots")
    png_save24("levelshots/" + lcase(main.levelpack.title) + "---" & game.mode.level & ".png", previewshot)
  end if
  
  s = 240 / screen.screen_sy
  image_scaler(previewshot_thumb, -screen.corner_sx * s, 0, previewshot, s)
  png_save24("data/levelpacks/" + lcase(main.levelpack.title) + _
    "/" & game.mode.level & ".png", previewshot_thumb)
  
  if levelpreview_total >= game.mode.level then
    put levelpreview(game.mode.level), (0, 0), previewshot_thumb, pset
  end if
  #endif
end sub

Sub utility_mouse_type.update ()
  p = c
  
  With c
    If Getmouse(.x, .y, .w, .b) Then
      c = p
      .b = false
    Else
      .sx = screen.unscale_x(.x)
      .sy = screen.unscale_y(.y)
    End If
  End With
End Sub
