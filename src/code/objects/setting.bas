
Sub setting_type.start ()
  #ifndef server_validator
  Dim As Integer f
  Dim As String l
  
  f = utility.openfile("data/settings.txt", utility_file_mode_enum.for_input)
  Input #f, alphavalue
  Input #f, ballglow
  Input #f, extras
  Input #f, flyingbricks
  Input #f, particles
  Input #f, cpuhog
  Input #f, bullettextures
  Input #f, players
  Input #f, vsync
  Input #f, mouseclipping
  Input #f, hicontrast
  Input #f, tips
  Input #f, autosave
  Input #f, keyboardspeed
  Input #f, unlockedmode
  Input #f, areyounotnew
  Close #f
  
  'do not let bad settings ruin game
  If alphavalue < 20 Or alphavalue > 255 Then alphavalue = 255
  If players < 1 Or players > 2 Then players = 1
  #Endif
End Sub

Sub setting_type.set_controls ()
  #ifndef server_validator
  
  Dim As menu_setting_type menumajor, menuminor
  
  With menumajor
    .title = "Controls"
    .option_total = 2
    .option(1) = "Keyboard speed"
    .option(2) = "Mouse clipping"
  End With
  
  Do
    menu.show(menumajor)
    
    menuminor.scrolloffset = 0
    Select Case menumajor.returnvalue
    Case 1
      With menuminor
        .title = "Keyboard Speed"
        .option_total = 3
        .option(1) = "Slow"
        .option(2) = "Normal"
        .option(3) = "Fast"
      End With
  
      Do
        menuminor.option_preselected = keyboardspeed \ keyboardspeedstep
        
        menu.show(menuminor)
        
        If menuminor.returnvalue > 0 Then keyboardspeed = menuminor.returnvalue * keyboardspeedstep
      Loop Until menuminor.returnvalue = false
    Case 2
      With menuminor
        .title = "Mouse Clipping"
        .option_total = 2
        .option(1) = "Clip to window"
        .option(2) = "No clipping"
      End With
      Do
        menuminor.option_preselected = 2 - Abs(mouseclipping)
        
        menu.show(menuminor)
        
        If menuminor.returnvalue > 0 Then mouseclipping = (menuminor.returnvalue = 1)
      Loop Until menuminor.returnvalue = false
    End Select
  Loop Until menumajor.returnvalue = false
  #Endif
End Sub

Sub setting_type.set_graphics ()
  'settings menu
  '(universal menu will support the things in the original settings menu)
  
  Dim As menu_setting_type menumajor, menuminor
  
  With menumajor
    .title = "Adjust the Settings"
    .option_total = 7
    .option(1) = "Alpha blurring"
    .option(2) = "Ball glow"
    .option(3) = "Explosions"
    .option(4) = "High contrast"
    .option(5) = "Flying (broken) bricks"
    .option(6) = "Lasers"
    .option(7) = "Particles"
  End With
  
  Do
    menu.show(menumajor)
    
    If menumajor.returnvalue > 0 Then
      Do
        'set up minor menu
        menuminor.scrolloffset = 0
        Select Case menumajor.returnvalue
        Case 1
          With menuminor
            .title = "Alpha Blurring"
            .option_total = 4
            .option_preselected = 5 - (alphavalue + 1) / 64
            .option(1) = "Off"    '255
            .option(2) = "Low"    '191
            .option(3) = "Medium" '127
            .option(4) = "High"   '63
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then alphavalue = 319 - menuminor.returnvalue * 64
        Case 2
          With menuminor
            .title = "Ball Glow"
            .option_total = 2
            If ballglow Then
              .option_preselected = 1
            Else
              .option_preselected = 2
            End If
            .option(1) = "On"
            .option(2) = "Off"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then ballglow = (menuminor.returnvalue = 1)
        Case 3
          With menuminor
            .title = "Explosions"
            .option_total = 2
            If extras Then
              .option_preselected = 1
            Else
              .option_preselected = 2
            End If
            .option(1) = "On"
            .option(2) = "Off"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then extras = (menuminor.returnvalue = 1)
        Case 4
          With menuminor
            .title = "High Contrast"
            .option_total = 2
            If hicontrast Then
              .option_preselected = 1
            Else
              .option_preselected = 2
            End If
            .option(1) = "On"
            .option(2) = "Off"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then hicontrast = (menuminor.returnvalue = 1)
        Case 5
          With menuminor
            .title = "Flying (Broken) Bricks"
            .option_total = 3
            .option_preselected = flyingbricks + 1
            .option(1) = "Off"
            .option(2) = "Shadows"
            .option(3) = "Textures"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then flyingbricks = menuminor.returnvalue - 1
          
        Case 6
          With menuminor
            .title = "Lasers"
            .option_total = 2
            If bullettextures Then
              .option_preselected = 1
            Else
              .option_preselected = 2
            End If
            .option(1) = "Textures"
            .option(2) = "Shadows"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then bullettextures = (menuminor.returnvalue = 1)
        Case 7
          With menuminor
            .title = "Particles"
            .option_total = 2
            If particles Then
              .option_preselected = 1
            Else
              .option_preselected = 2
            End If
            .option(1) = "On"
            .option(2) = "Off"
          End With
          
          menu.show(menuminor)
          If menuminor.returnvalue > 0 Then particles = (menuminor.returnvalue = 1)
        End Select
      Loop Until menuminor.returnvalue = false
    End If
  Loop Until menumajor.returnvalue = false
End Sub

Sub setting_type.set_multiplayer ()
  Dim As menu_setting_type mainmenu
  
  Do
    With mainmenu
      .title = "Multiplayer"
      .option_total = 2
      .option_preselected = players
      .option(1) = "1 player"
      .option(2) = "2 players"
    End With
    
    menu.show(mainmenu)
    If mainmenu.returnvalue > 0 Then players = mainmenu.returnvalue
  Loop Until mainmenu.returnvalue = false
End Sub

Sub setting_type.set_performance ()
  Dim As menu_setting_type menumajor, menuminor
  
  With menumajor
    .title = "Performance"
    .option_total = 2
    .option(1) = "CPU usage"
    .option(2) = "Vsync"
  End With
  
  Do
    menu.show(menumajor)
    
    menuminor.scrolloffset = 0
    Select Case menumajor.returnvalue
    Case 1
      With menuminor
        .title = "CPU Usage"
        .option_total = 4
        .option(1) = "Win 2000 style"
        .option(2) = "Win XP style"
        .option(3) = "Win Vista style"
        .option(4) = "Win 7 style"
      End With
      
      Do
        menuminor.option_preselected = cpuhog
        
        menu.show(menuminor)
        
        If menuminor.returnvalue > 0 Then cpuhog = menuminor.returnvalue
      Loop Until menuminor.returnvalue = false
    Case 2
      With menuminor
        .title = "Vsync"
        .option_total = 2
        .option(1) = "On"
        .option(2) = "Off"
      End With
      
      Do
        menuminor.option_preselected = 2 + vsync
        
        menu.show(menuminor)
        
        If menuminor.returnvalue > 0 Then vsync = (menuminor.returnvalue = 1)
      Loop Until menuminor.returnvalue = false
    End Select
  Loop Until menumajor.returnvalue = false
End Sub

Sub setting_type.set_recordings ()
  Dim As menu_setting_type mainmenu
  
  Do
    With mainmenu
      .title = "Recordings"
      .option_total = 2
      If autosave Then
        .option_preselected = 1
      Else
        .option_preselected = 2
      End If
      .option(1) = "Auto-save all replays"
      .option(2) = "Manual-save only"
    End With
    
    menu.show(mainmenu)
    If mainmenu.returnvalue > 0 Then autosave = (mainmenu.returnvalue = 1)
  Loop Until mainmenu.returnvalue = false
End Sub

Sub setting_type.set_tips ()
  Dim As menu_setting_type mainmenu
  
  Do
    With mainmenu
      .title = "Tips"
      .option_total = 2
      If tips Then
        .option_preselected = 1
      Else
        .option_preselected = 2
      End If
      .option(1) = "On"
      .option(2) = "Off"
    End With
    
    menu.show(mainmenu)
    If mainmenu.returnvalue > 0 Then tips = (mainmenu.returnvalue = 1)
  Loop Until mainmenu.returnvalue = false
End Sub

Sub setting_type.finish ()
  #ifndef server_validator
  Dim As Integer f
  
  f = utility.openfile("data/settings.txt", utility_file_mode_enum.for_output)
  Print #f, alphavalue
  Print #f, ballglow
  Print #f, extras
  Print #f, flyingbricks
  Print #f, particles
  Print #f, cpuhog
  Print #f, bullettextures
  Print #f, players
  Print #f, vsync
  Print #f, mouseclipping
  Print #f, hicontrast
  Print #f, tips
  Print #f, autosave
  Print #f, keyboardspeed
  Print #f, unlockedmode
  Print #f, areyounotnew
  Close #f
  #Endif
End Sub
