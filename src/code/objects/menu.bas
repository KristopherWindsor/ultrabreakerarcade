
'callbacks

Function menu_callback_info (Byref menu As menu_setting_type, oselected as integer) As Integer
  menu.option(6) = game.get_score()
  
  Return -1
End Function

Function menu_callback_selectlevel (Byref menu As menu_setting_type, oselected as integer) As Integer
  'sets previewimage for both master and replay menus
  #ifndef server_validator
  
  static as integer frametotal
  
  'set correct preview
  menu.previewimage = 0
  if oselected <= utility.graphic.levelpreview_total then
    menu.previewimage = utility.graphic.levelpreview(oselected)
  end if
  
  frametotal += 1
  if frametotal mod 15 = 0 then utility.graphic.loadpreview()
  
  return -1
  #else
  Return -1
  #endif
End Function

Function menu_callback_play (Byref menu As menu_setting_type, oselected as integer) As Integer
  'show previewimage only when hovering on "arcade mode"
  #ifndef server_validator
  
  static as integer frametotal
  
  'set correct preview
  menu.previewimage = 0
  if oselected = 1 and main.levelpack.level_total = main.levelpack.unlockedtotal then
    var index = (main.levelpack.arcade_save.level mod main.levelpack.level_total) + 1
    if index <= utility.graphic.levelpreview_total then
      menu.previewimage = utility.graphic.levelpreview(index)
    end if
  end if
  
  frametotal += 1
  if frametotal mod 15 = 0 then utility.graphic.loadpreview()
  #endif
  
  Return -1
End Function

Function menu_callback_postgame (Byref menu As menu_setting_type, oselected as integer) As Integer
  With menu
    .option(1) = game.get_score()
    If game.result.scoregained >= game.setting.requiredscore Then .option(1) += " (won)"
  End With
  
  Return -1
End Function

Function menu_callback_test (Byref menu As menu_setting_type, oselected as integer) As Integer
  'return 10 if in testing mode, else return -1
  'also focus on window if in testing mode
  #ifndef server_validator
  
  Dim As Integer r
  Dim As handle mytex
  
  'select first option if the mutex exists (cannot be created)
  mytex = CreateMutex(NULL, TRUE, "_UltraBreakerTest")
  If mytex = 0 Then Return -1 'unplanned error
  
  r = -1
  If GetLastError() = ERROR_ALREADY_EXISTS Then r = 10
  
  CloseHandle(mytex)
  Return r
  
  #Else
  Return -1
  #Endif
End Function

'main stuff

Function menu_type.confirm (Byref title As String, _
  Byval getscreenshot As Integer = false) As Integer
  
  Dim As menu_setting_type menu
  
  With menu
    .title = title
    .option_total = 2
    .screenshot_ison = getscreenshot
    .screenshot_disable_intro = true
    .disablecancel = true
    .xoption = 2
    .option(1) = "Yes"
    .option(2) = "No"
  End With
  
  Return show(menu) = 1
End Function

Function menu_type.show (menu as menu_setting_type) As Integer
  'returns choice index, or false on cancel
  #ifndef server_validator
  
  Const option_perpage = 10, margin = 50 * dsfactor
  
  Enum object_hover_enum
    ball = 1 'the big ball in the background (click and drag to scroll)
    Option 'something in the menu
    arrow_up
    arrow_down
    arrow_back
    scroll
    screenshot
  End Enum
  
  Dim As object_hover_enum object_hover
  Dim As Integer quit, callback_choice, cancel, option_alphavalue
  Dim As Integer ball_alpha, option_hover, option_selected, option_displaytotal, option_tx, option_ty
  Dim As Integer scroll_top, scroll_bottom, scroll_mouse, scroll_use
  dim as integer screenshot_tx, screenshot_ty, screenshot_startx, screenshot_starty, screenshot_x, screenshot_y, screenshot_ishovered
  Dim As Integer usemouse 'disables mouse onhover events if keyboard arrow keys are used; does not disable clicks, scrolls, etc.
  Dim As Double ball_angle, ball_angle_target, ball_angle_change, ball_angle_scrollvalue, idletime
  Dim As Double screenshot_tscale, screenshot_scale, screenshot_hoverscale, screenshot_doneintro 'tscale = scale when loaded; hoverscale is extra multiplier
  Dim As String clearbuffer, key
  Dim As fb.image Ptr background, screenshot_graphic
  Dim As utility_font_setting_type fontsetting_title, fontsetting_option
  Dim As utility_framerate_type framerate = utility_framerate_type()
  
  With menu
    If .option_total <= 0 Then Return false
    
    If .disablecancel = false And .readonly = false Then
      .option_total += 1
      .option(.option_total) = "<< Back"
    End If
    
    option_selected = .scrolloffset + 1
  End With
  
  Dim As Double slideout(1 To menu.option_total)
  
  option_tx = screen.default_sx / 2
  option_ty = margin + utility.font.fontheight * utility.font.fontspacing
  option_displaytotal = Int((screen.default_sy - margin * 4) / _
    (utility.font.fontheight * utility.font.fontspacing))
  scroll_use = option_displaytotal < menu.option_total
  usemouse = true
  
  With fontsetting_title
    .clipping = screen.default_sx - margin * 4
    .c_back = color_enum.white
  End With
  
  With screen
    If .screen_sx = utility.graphic.menu -> Width And .screen_sy = utility.graphic.menu -> height Then
      background = utility.graphic.menu
    Else
      background = utility.createimage(.screen_sx, .screen_sy mop("menu background"), color_enum.black)
      'using the 800 * 600 graphic even though (.scale = 1) -> 1024 * 768
      multiput(background, .screen_sx Shr 1, .screen_sy Shr 1, utility.graphic.menu, .scale * (screen.default_sx / utility.graphic.menu->width))
    End If
  End With
  
  'screenshot setup
  screenshot_doneintro = iif(menu.screenshot_ison = false or menu.screenshot_disable_intro, 1, 0)
  screenshot_tscale = .25 * (screen.view_sx / screen.screen_sx) / screen.scale 'will be reset in loop for previewimage
  screenshot_hoverscale = 1 'scales graphic on hover but doesn't affect position
  
  'change option from hover on first frame
  With utility.mouse.c
    If .sx > option_tx And .sx < option_tx + fontsetting_title.clipping Then
      option_hover = Int((.sy - margin * 2 - utility.font.fontheight * (utility.font.fontspacing - 1) Shr 1) _
        / (utility.font.fontheight * utility.font.fontspacing)) + menu.scrolloffset + 1
      
      If option_hover > menu.scrolloffset And option_hover <= menu.option_total And option_hover <= menu.scrolloffset + option_displaytotal Then
        option_selected = option_hover
      End If
    End If
  End With
  
  'clear key buffer
  clearbuffer = Inkey() & Inkey()
  While Inkey() > ""
    While Inkey() > "": Wend
    Sleep(200, 1)
  Wend
  
  idletime = Timer()
  
  Do
    framerate.move()
    sound.move()
    
    'idle -> go into "wait for input" mode if no input detected in a few seconds
    'if callback (leveling or updating score), don't idle instantly
    If Timer() - idletime > 10 + Abs(menu.callback > 0) * 290 Then
      Do
        sound.move()
        
        With utility.mouse
          var temp = .p
          .update()
          If (.c = .p) = false Then
            'restore mouse as if we never looked at it
            .c = .p
            .p = temp
            Exit Do
          End If
        End With
        
        Sleep(18)
        key = Inkey()
      Loop Until Len(key) > 0
      framerate.fixtimeout()
      idletime = Timer()
    End If
    
    With utility.mouse
      .update()
      If (.c = .p) = false Then idletime = Timer()
    End With
    
    'callback
    If menu.callback > 0 Then
      callback_choice = menu.callback(menu, option_selected)
      If callback_choice >= 0 Then
        option_selected = callback_choice
        quit = true
      End If
    End If
    
    'ball fading
    If ball_alpha > 0 Then ball_alpha -= 15
    
    'adjust / calculate screenshot
    with screen
      screenshot_graphic = iif(menu.screenshot_ison, utility.graphic.screenshot, menu.previewimage)
      if menu.screenshot_ison = false and menu.previewimage > 0 then
        'scale multiplied by screenshot dimensions is the dimensions in default size
        screenshot_tscale = (.25 * .view_sx / screenshot_graphic->width) / screen.scale
      end if
      
      if screenshot_graphic > 0 then
        'positions for graphic
        screenshot_startx = .default_sx / 2
        screenshot_starty = .default_sy / 2
        screenshot_tx = margin * 2 + screenshot_graphic->width * screenshot_tscale * .5
        screenshot_ty = .default_sy - margin * 2 - screenshot_graphic->height * screenshot_tscale * .5
        
        'transition variable (for zoom in)
        if screenshot_doneintro < 1 then screenshot_doneintro += .03
        if screenshot_doneintro > 1 then screenshot_doneintro = 1
        
        'position and scale; use transition variable as weight for weighted average
        var d1 = screenshot_doneintro, d2 = 1 - d1
        var d1b = screenshot_doneintro ^ 2, d2b = 1 - d1b
        screenshot_x = screenshot_tx * d1b + screenshot_startx * d2b
        screenshot_y = screenshot_ty * d1b + screenshot_starty * d2b
        screenshot_scale = (screenshot_tscale * screenshot_hoverscale * d1 + (1 / .scale) * d2)
        
        'if done transitioning, see if mouse is hovering over shot, and adjust hoverscale
        if screenshot_doneintro = 1 then
          var dx = abs(screenshot_x - utility.mouse.c.sx), dy = abs(screenshot_y - utility.mouse.c.sy)
          var mdx = screenshot_graphic->width * screenshot_scale * screenshot_hoverscale * .5
          var mdy = screenshot_graphic->width * screenshot_scale * screenshot_hoverscale * .5 * (screenshot_graphic->height / screenshot_graphic->width)
          
          screenshot_ishovered = (dx < mdx and dy < mdy)
          
          if screenshot_ishovered then
            if screenshot_hoverscale < 1.1 then screenshot_hoverscale *= 1.01
          else
            if screenshot_hoverscale > 1 then screenshot_hoverscale *= .98
          end if
        end if
      end if
    end with
    
    'mouse control
    With utility.mouse.c
      'scroll wheel
      If scroll_use Then
        menu.scrolloffset += utility.mouse.p.w - .w
        If menu.scrolloffset < 0 Then menu.scrolloffset = 0
        If menu.scrolloffset + option_displaytotal > menu.option_total Then menu.scrolloffset = menu.option_total - option_displaytotal
      End If
      
      If (utility.mouse.p.x <> .x Or utility.mouse.p.y <> .y) Then usemouse = true
      
      'find out what the mouse is hovering over
      If .b = 0 And usemouse Then
        'see what the mouse is hovering over
        object_hover = object_hover_enum.ball 'this is default hover object
        
        If .sx > screen.default_sx - margin * 3 And .sy < margin * 3 Then
          object_hover = object_hover_enum.arrow_up
        Elseif .sx > screen.default_sx - margin * 3 And .sy > screen.default_sy - margin * 3 Then
          object_hover = object_hover_enum.arrow_down
        Elseif .sx < margin * 3 And .sy > screen.default_sy - margin * 3 Then
          object_hover = object_hover_enum.arrow_back
        Elseif .sx > screen.default_sx - margin * 2 And .sx < screen.default_sx - margin Then
          object_hover = object_hover_enum.scroll
        Elseif screenshot_ishovered then
          object_hover = object_hover_enum.screenshot
        Elseif .sx < option_tx + fontsetting_option.clipping Then
          option_hover = Int((.sy - margin * 2 - utility.font.fontheight * (utility.font.fontspacing - 1) Shr 1) _
            / (utility.font.fontheight * utility.font.fontspacing)) + menu.scrolloffset + 1
          
          If option_hover > menu.scrolloffset And option_hover <= menu.option_total And option_hover <= menu.scrolloffset + option_displaytotal Then
            If .sx > option_tx - slideout(option_hover) Then
              object_hover = object_hover_enum.option
              If option_hover <> option_selected Then
                sound.add(sound_enum.menu_changeselected)
                xfx.particle.add(.sx, .sy)
                option_selected = option_hover
              End If
            End If
          End If
        End If
      End If
      
      'do something on click
      If .b > 0 And utility.mouse.p.b = 0 Then
        Select Case object_hover
        Case object_hover_enum.ball
          ball_angle = 0
          ball_angle_target = 0
        Case object_hover_enum.option
          If Len(menu.option(option_selected)) > 0 Then quit = true
        Case object_hover_enum.arrow_up
          If menu.readonly Then
            If menu.scrolloffset > 0 Then
              menu.scrolloffset -= 1
              sound.add(sound_enum.menu_changeselected)
              xfx.particle.add(.sx, .sy)
            End If
          Else
            If option_selected > 1 Then
              option_selected -= 1
              If option_selected <= menu.scrolloffset Then menu.scrolloffset -= 1
              sound.add(sound_enum.menu_changeselected)
              xfx.particle.add(.sx, .sy)
            End If
          End If
        Case object_hover_enum.arrow_down
          If menu.readonly Then
            If menu.scrolloffset + option_displaytotal < menu.option_total Then
              menu.scrolloffset += 1
              sound.add(sound_enum.menu_changeselected)
              xfx.particle.add(.sx, .sy)
            End If
          Else
            If option_selected < menu.option_total Then
              option_selected += 1
              If option_selected > menu.scrolloffset + option_displaytotal Then menu.scrolloffset += 1
              sound.add(sound_enum.menu_changeselected)
              xfx.particle.add(.sx, .sy)
            End If
          End If
        Case object_hover_enum.arrow_back
          If menu.disablecancel = false Then
            quit = true
            cancel = true
          End If
        Case object_hover_enum.screenshot
          quit = true
          cancel = menu.screenshot_ison '(not on) -> clicked preview -> select, not cancel
        End Select
      End If
      
      'do something if mouse button is down (but not just pressed)
      If .b > 0 Then
        Select Case object_hover
        Case object_hover_enum.ball
          ball_alpha = 255
          ball_angle_change = Atan2(.sy - 384 * dsfactor, .sx - 364 * dsfactor) - _
            Atan2(utility.mouse.p.sy - 384 * dsfactor, utility.mouse.p.sx - 364 * dsfactor)
          If ball_angle_change > pi Then ball_angle_change -= pi * 2
          If ball_angle_change < -pi Then ball_angle_change += pi * 2
          ball_angle_target += ball_angle_change
          ball_angle += (ball_angle_target - ball_angle) * .1
          
          'menu scrolling
          ball_angle_scrollvalue += ball_angle_change
          While ball_angle_scrollvalue > .1
            If menu.scrolloffset + option_displaytotal < menu.option_total Then
              menu.scrolloffset += 1
              if option_selected <= menu.scrolloffset then option_selected = menu.scrolloffset + 1
            End If
            ball_angle_scrollvalue -= .1
          Wend
          While ball_angle_scrollvalue < -.1
            ball_angle_scrollvalue += .1
            If menu.scrolloffset > 0 Then
              menu.scrolloffset -= 1
              if option_selected > menu.scrolloffset + option_displaytotal then
                option_selected = menu.scrolloffset + option_displaytotal
              end if
            end if
          Wend
        Case object_hover_enum.scroll
          If scroll_use Then
            scroll_mouse = utility.mouse.c.sy
            If scroll_mouse < scroll_top Then
              If menu.scrolloffset > 0 Then menu.scrolloffset -= 1
            Elseif scroll_mouse > scroll_bottom Then
              If menu.scrolloffset + option_displaytotal < menu.option_total Then
                menu.scrolloffset += 1
              End If
            End If
          End If
        End Select
      End If
    End With
    
    'key control; += inkey to get the key from idle mode
    key += Inkey()
    If Len(key) > 0 Then idletime = Timer()
    Select Case key
    Case Chr(13), " "
      If Len(menu.option(option_selected)) > 0 Then quit = true
    Case Chr(255, 72)
      If option_selected > 1 Then
        option_selected -= 1
        If option_selected <= menu.scrolloffset Then menu.scrolloffset -= 1
        sound.add(sound_enum.menu_changeselected)
        xfx.particle.add(screen.default_sx - margin * 2, option_ty + (option_selected - menu.scrolloffset - 1) * _
          utility.font.fontheight * utility.font.fontspacing + utility.font.fontheight * .5)
        usemouse = false
      End If
    Case Chr(255, 80)
      If option_selected < menu.option_total Then
        option_selected += 1
        If option_selected > menu.scrolloffset + option_displaytotal Then menu.scrolloffset += 1
        sound.add(sound_enum.menu_changeselected)
        xfx.particle.add(screen.default_sx - margin * 2, option_ty + (option_selected - menu.scrolloffset - 1) * _
          utility.font.fontheight * utility.font.fontspacing + utility.font.fontheight * .5)
        usemouse = false
      End If
    End Select
    If utility.quitprogram(key, @framerate) orelse key = Chr(27) Then
      'same code for escape and X button, but note that quitprogram() can return true if set previously
      If menu.disablecancel = false Then
        quit = true
        cancel = true
      Elseif menu.xoption > 0 Then
        option_selected = menu.xoption
        quit = true
      End If
    End If
    key = ""
    
    'scroll bar
    If scroll_use Then
      scroll_top = (menu.scrolloffset / menu.option_total) * (screen.default_sy - margin * 4) + margin * 2
      If menu.scrolloffset + option_displaytotal < menu.option_total Then
        scroll_bottom = ((menu.scrolloffset + option_displaytotal) / menu.option_total) * (screen.default_sy - margin * 4) + margin * 2
      Else
        scroll_bottom = screen.default_sy - margin * 2
      End If
    End If
    
    xfx.particle.move()
    
    'slideout
    If menu.readonly Then
      For i As Integer = 1 To menu.option_total
        slideout(i) = screen.default_sx / 4 - margin
      Next i
    Else
      For i As Integer = 1 To menu.option_total
        If option_selected = i Then
          If slideout(i) < screen.default_sx / 2 - margin * 2 Then
            slideout(i) += (screen.default_sx / 2 - margin * 2 - slideout(i)) / 12
          End If
        Else
          If slideout(i) > 0 Then slideout(i) -= slideout(i) / 12
        End If
      Next i
    End If
    
    'start displaying
    If framerate.candisplay() And quit = false Then
      Screenlock()
      Put (0, 0), background, alpha, setting.alphavalue
      
      'ball
      If ball_alpha > 0 Then
        multiput(, screen.scale_x(bigball_x), screen.scale_y(bigball_y), _
          utility.graphic.ball, screen.scale * (19 / 6) * dsfactor,, ball_angle, ball_alpha)
      End If
      
      'screenshot or preview
      'var screeng = iif(menu.screenshot_ison, utility.graphic.screenshot, menu.previewimage)
      If screenshot_graphic > 0 then
        multiput(, screen.scale_x(screenshot_x), screen.scale_y(screenshot_y), _
          screenshot_graphic, screenshot_scale * screen.scale)
      End If
      
      'scroll bar
      If scroll_use Then
        Line (screen.scale_x(screen.default_sx - margin * 2), screen.scale_y(scroll_top)) - _
          (screen.scale_x(screen.default_sx - margin), screen.scale_y(scroll_bottom)), color_enum.white, B'black, BF
      End If
      
      With menu
        utility.font.show(.title, margin * 2, margin, fontsetting_title)
        For i As Integer = 1 To option_displaytotal
          'empty menu options are delimiters
          If Len(.option(i + menu.scrolloffset)) = 0 Then Continue For
          
          If i + menu.scrolloffset <= menu.option_total Then
            'default style
            fontsetting_option.c = color_enum.black
            fontsetting_option.c_back = 0
            
            'selected option for settings menus
            If menu.option_preselected = i + menu.scrolloffset Then
              fontsetting_option.c = color_enum.gray
            Else
              fontsetting_option.c = color_enum.black
            End If
            
            'selected option
            option_alphavalue = 255 * slideout(i + menu.scrolloffset) / (screen.default_sx - margin Shl 2)
            If option_alphavalue > 0 Then
              fontsetting_option.c_back = Rgba(255, 255, 255, option_alphavalue)
            Else
              fontsetting_option.c_back = 0
            End If
            
            fontsetting_option.clipping = screen.default_sx / 2 - margin * 2 + slideout(i + menu.scrolloffset)
            
            utility.font.show(.option(i + menu.scrolloffset), option_tx - slideout(i + menu.scrolloffset), option_ty + (i - 1) * _
              utility.font.fontheight * utility.font.fontspacing, fontsetting_option)
          End If
        Next i
      End With
      
      'large arrows
      Select Case object_hover
      Case object_hover_enum.arrow_up
        Dim As Integer c, x, y1, y2
        
        If utility.mouse.c.b > 0 Then c = color_enum.gray Else c = color_enum.black
        x = screen.scale_x(screen.default_sx - margin * 1.5)
        y1 = screen.scale_y(margin * .5)
        y2 = screen.scale_y(margin * 2.5)
        
        For y As Integer = y1 To y2
          Line (x - (y - y1) Shr 1, y) - (x + (y - y1) Shr 1, y), c
        Next y
      Case object_hover_enum.arrow_down
        Dim As Integer c, x, y1, y2
        
        If utility.mouse.c.b > 0 Then c = color_enum.gray Else c = color_enum.black
        x = screen.scale_x(screen.default_sx - margin * 1.5)
        y1 = screen.scale_y(screen.default_sy - margin * 2.5)
        y2 = screen.scale_y(screen.default_sy - margin * .5)
        
        For y As Integer = y1 To y2
          Line (x - (y - y2) Shr 1, y) - (x + (y - y2) Shr 1, y), c
        Next y
      Case object_hover_enum.arrow_back
        If menu.disablecancel = false Then
          Dim As Integer c, x1, x2, y
          
          If utility.mouse.c.b > 0 Then c = color_enum.gray Else c = color_enum.black
          x1 = screen.scale_x(margin * .5)
          x2 = screen.scale_x(margin * 2.5)
          y = screen.scale_y(screen.default_sy - margin * 1.5)
          
          For x As Integer = x1 To x2
            Line (x, y - (x - x1) Shr 1) - (x, y + (x - x1) Shr 1), c
          Next x
        End If
      End Select
      
      xfx.graphic.glow_show(utility.mouse.c.sx, utility.mouse.c.sy)
      
      xfx.particle.display()
      Screenunlock()
    End If
  Loop Until quit
  
  sound.add(sound_enum.menu_select)
  If background <> utility.graphic.menu Then utility.deleteimage(background mop("menu background"))
  showclosing(screenshot_doneintro)
  
  With menu
    If cancel Then .returnvalue = false Else .returnvalue = option_selected
    
    If .readonly = false andalso .disablecancel = false Then
      If .returnvalue = .option_total Then .returnvalue = false
      .option_total -= 1
    End If
  End With
  
  utility.mouse.update() 'when program returns, it won't think mouse has just been pressed
  Return menu.returnvalue
  
  #Else
  Return 0
  #Endif
End Function

Sub menu_type.showclosing (setprogress as double = -1)
  'zoom back to the screenshot
  #ifndef server_validator
  
  Const margin = 50
  
  static as double screenshot_doneintro
  
  dim as integer screenshot_tx, screenshot_ty, screenshot_startx, screenshot_starty, screenshot_x, screenshot_y, screenshot_ishovered
  Dim As Double screenshot_tscale, screenshot_scale, screenshot_hoverscale
  dim as fb.image ptr screenshot_graphic
  
  Dim As utility_framerate_type framerate
  Dim As fb.image Ptr background
  
  If utility.quitprogram() Then Return
  
  'this sets the doneintro variable everytime before this codes runs
  if setprogress >= 0 then
    screenshot_doneintro = setprogress
    return
  end if
  
  With screen
    background = utility.createimage(.screen_sx, .screen_sy mop("menu showclosing"), color_enum.black)
    Get (0, 0) - (.screen_sx - 1, .screen_sy - 1), background
  End With
  
  'screenshot setup
  'screenshot_doneintro = 1
  screenshot_tscale = .25 * (screen.view_sx / screen.screen_sx) / screen.scale 'will be reset in loop for previewimage
  screenshot_hoverscale = 1.1 'scales graphic on hover but doesn't affect position
  
  Do
    framerate.move()
    
    'adjust / calculate screenshot
    with screen
      screenshot_graphic = utility.graphic.screenshot
      
      if screenshot_graphic > 0 then
        'positions for graphic
        screenshot_startx = .default_sx / 2
        screenshot_starty = .default_sy / 2
        screenshot_tx = margin * 2 + screenshot_graphic->width * screenshot_tscale * .5
        screenshot_ty = .default_sy - margin * 2 - screenshot_graphic->height * screenshot_tscale * .5
        
        'transition variable (for zoom in)
        screenshot_doneintro -= .03
        if screenshot_doneintro < 0 then screenshot_doneintro = 0
        
        'position and scale; use transition variable as weight for weighted average
        var d1 = screenshot_doneintro, d2 = 1 - d1
        var d1b = screenshot_doneintro ^ 2, d2b = 1 - d1b
        screenshot_x = screenshot_tx * d1b + screenshot_startx * d2b
        screenshot_y = screenshot_ty * d1b + screenshot_starty * d2b
        screenshot_scale = (screenshot_tscale * screenshot_hoverscale * d1 + (1 / .scale) * d2)
        
        'if done transitioning, see if mouse is hovering over shot, and adjust hoverscale
        if screenshot_doneintro = 1 then
          var dx = abs(screenshot_x - utility.mouse.c.sx), dy = abs(screenshot_y - utility.mouse.c.sy)
          var mdx = screenshot_graphic->width * screenshot_scale * screenshot_hoverscale * .5
          var mdy = screenshot_graphic->width * screenshot_scale * screenshot_hoverscale * .5 * (screenshot_graphic->height / screenshot_graphic->width)
          
          screenshot_ishovered = (dx < mdx and dy < mdy)
          
          if screenshot_ishovered then
            if screenshot_hoverscale < 1.1 then screenshot_hoverscale *= 1.01
          else
            if screenshot_hoverscale > 1 then screenshot_hoverscale *= .98
          end if
        end if
      end if
    end with
    
    If framerate.candisplay() Then
      Screenlock()
      Put (0, 0), background, alpha, setting.alphavalue
      multiput(, screen.scale_x(screenshot_x), screen.scale_y(screenshot_y), _
          screenshot_graphic, screenshot_scale * screen.scale)
      Screenunlock()
    End If
  Loop Until screenshot_doneintro = 0
  
  utility.deleteimage(background mop("menu showclosing"))
  #Endif
End Sub

Sub menu_type.notify (Byref title As String, Byval getscreenshot As Integer = false)
  Dim As menu_setting_type menu
  
  With menu
    .title = title
    .option_total = 1
    .option(1) = "OK"
    
    .disablecancel = true
    .xoption = 1
    
    .screenshot_ison = getscreenshot
    .screenshot_disable_intro = true
  End With
  
  show(menu)
End Sub
