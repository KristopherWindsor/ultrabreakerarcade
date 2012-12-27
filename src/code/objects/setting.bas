
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
  Input #f, hicontrast
  Input #f, tips
  Input #f, autosave
  Input #f, keyboardspeed
  Input #f, altkeyboardspeed
  Input #f, unlockedmode
  Input #f, areyounotnew
  Close #f
  
  'do not let bad settings ruin game
  If alphavalue < 20 Or alphavalue > 255 Then alphavalue = 255
  If players < 1 Or players > 2 Then players = 1
  #Endif
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
  Print #f, hicontrast
  Print #f, tips
  Print #f, autosave
  Print #f, keyboardspeed
  Print #f, altkeyboardspeed
  Print #f, unlockedmode
  Print #f, areyounotnew
  Close #f
  #Endif
End Sub
