
Sub main_type.run ()
  start()
  
  while intro()
    if choose_world() then gameover(play())
  wend
  
  finish()
End Sub

Sub main_type.start ()
  'initialize program: load data, gfx, sfx
  
  #ifndef server_validator
  setenviron("fbgfx=GDI")
  If CreateMutex(NULL, TRUE, "_UltraBreakerGame") = 0 orelse GetLastError() = ERROR_ALREADY_EXISTS Then
    utility.logerror("Cannot create named mutex (no worries, another instance of the game is prolly already running)")
    System()
  End If
  #Endif
  
  Chdir(Exepath)
  
  sound.start()
  screen.start()
  setting.start()
  utility.start()
  game.start()
  
  main.controls.load()
  main.levelpack.start()
  main.programstarted = true
  
  screenchange()
End Sub

Sub main_type.screenchange ()
  'redraw gfx on screensize change
  'x_start() may call x_screenchange(), but main_screenchange() is not called at startup
  
  utility.screenchange()
  
  xfx.screenchange()
  brick.screenchange()
End Sub

Sub main_type.finish ()
  superfluous sound.speak("", true)
  
  main.levelpack.finish()
  
  game.finish()
  screen.finish()
  setting.finish ()
  sound.finish()
  utility.finish()
End Sub

function main_type.choose_world() as integer
  #ifndef server_validator
  
  #define text1 "Ultrabreaker"
  #define text1x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text1) / screen.scale) / 2

  #define text2 "Press START to play"
  #define text2x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text2) / screen.scale) / 2

  dim as integer selected = 1, previewsize, rowtotal
  dim as string key
  Dim As utility_framerate_type framerate = utility_framerate_type()

  previewsize = 240
  rowtotal = 3
  
  do
    framerate.move()
    
    key = inkey()
    if key = controls.ink(controls.forcequit) then return false
    if key = controls.ink(controls.p1_start) or key = controls.ink(controls.p2_start) then
      setting.players = iif(key = controls.ink(controls.p1_start), 1, 2)
      levelpack.load(selected)
      return true
    end if
    if key = controls.ink(controls.p1_left) and selected > 1 then selected -= 1
    if key = controls.ink(controls.p1_right) and selected < levelpack.list_total and selected < rowtotal then selected += 1
    
    if framerate.candisplay() then
      screenlock()
      if screen.screen_sx = 800 and screen.screen_sy = 600 then
        put (0, 0), utility.graphic.menubackground, pset
      else
        multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.menubackground, screen.scale * screen.default_sx / utility.graphic.menubackground_sx)
      end if
      for i as integer = 1 to rowtotal
        if i <= main.levelpack.list_total then
          multiput( _
            0, _
            (i - .5) * (screen.view_sx / rowtotal) + screen.corner_sx, _
            screen.scale_y(screen.default_sy * .5), _
            utility.graphic.levelpackpreview(i), _
            previewsize / 320, _
            0, _
            0, _
            iif(selected = i, 255, 50))
        end if
      next i
      utility.font.show(text1, text1x, screen.default_sy * .83)
      if framerate.loop_total mod 18 >= 9 then
        utility.font.show(text2, text2x, screen.default_sy * .90)
      end if
      screenunlock()
    end if
  loop
  
  return false
  
  #endif
end function

sub main_type.gameover(score as integer)
  #ifndef server_validator
  
  #define text1 "World " & levelpack.indexOf & " Single Player High Scores"
  #define text1x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text1) / screen.scale) / 2

  dim as string key
  dim as integer rank = levelpack.addscore(score), temp
  Dim As utility_framerate_type framerate = utility_framerate_type()
  
  do
    framerate.move()
    
    key = inkey()
    if key = controls.ink(controls.p1_fire) or key = controls.ink(controls.p1_start) then exit do
    
    if framerate.candisplay() then
      screenlock()
      if screen.screen_sx = 800 and screen.screen_sy = 600 then
        put (0, 0), utility.graphic.menubackground, pset
      else
        multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.menubackground, screen.scale * screen.default_sx / utility.graphic.menubackground_sx)
      end if
      
      utility.font.show(text1, text1x, screen.default_sy * .1)
      for i as integer = 1 to levelpack.highscore_max
        if i = rank and framerate.loop_total mod 18 < 9 then continue for
        temp = screen.default_sx * .45 - utility.font.abf.gettextwidth(utility.font.font_pt_selected, str(levelpack.highscore_value(i))) / screen.scale / 2
        utility.font.show(str(levelpack.highscore_value(i)), temp, screen.default_sy * (.15 + i * .1))
        utility.font.show(levelpack.highscore_name(i), screen.default_sx * .55, screen.default_sy * (.15 + i * .1))
      next i
      screenunlock()
    end if
    
  loop
  
  #endif
end sub

function main_type.intro() as integer
  #ifndef server_validator
  
  #define text1 "Ultrabreaker"
  #define text1x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text1) / screen.scale) / 2

  #define text2 "Press START to play"
  #define text2x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text2) / screen.scale) / 2

  dim as integer rotatecountdown = 20000
  dim as double angle, backgroundangle
  dim as string key
  Dim As utility_framerate_type framerate = utility_framerate_type()

  framerate.reset()
  
  do
    framerate.move()
    
    key = inkey()
    if key = controls.ink(controls.forcequit) then return false
    if key = controls.ink(controls.p1_start) then return true
    if key = controls.ink(controls.p2_start) then return true
    
    angle += .02
    if backgroundangle > 0 then
      backgroundangle += .02
      if backgroundangle > 2 * pi then backgroundangle = 0
    else
      rotatecountdown -= 1
      if rotatecountdown <= 0 then
        rotatecountdown = 20000
        backgroundangle = .0001
      end if
    end if
    
    If framerate.candisplay() Then
      screenlock()
      if backgroundangle > 0 then cls
      if backgroundangle = 0 and screen.screen_sx = 800 and screen.screen_sy = 600 then
        put (0, 0), utility.graphic.menubackground, pset
      else
        multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.menubackground, screen.scale * screen.default_sx / utility.graphic.menubackground_sx, 0, backgroundangle)
      end if
      if backgroundangle = 0 then
        utility.font.show(text1, text1x, screen.default_sy * .83)
        if framerate.loop_total mod 18 >= 9 then
          utility.font.show(text2, text2x, screen.default_sy * .90)
        end if
      end if
      multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.ball, 1, 0, angle)
      screenunlock()
    end if
  loop
  
  return false
  
  #endif
end function

function main_type.play() as integer
  dim as integer score
  
  With game.mode
    .level = 1
    .lives = arcadelives
    .speed = sqr(2)
    .orbtokens = 0
  end with
  
  do
    game.run()
    
    with game.result
      score += .scoregained
      if not .didwin then exit do
      
      if game.mode.level = levelpack.level_total then
        game.mode.level = 1
        game.mode.speed *= sqr(2)
      else
        game.mode.level += 1
      end if
      game.mode.lives += .livesgained - .liveslost
      game.mode.orbtokens = .orbtokens
    end with
  loop
  
  utility.graphic.reloadlevelpackpreview(levelpack.indexOf)
  
  return score
end function

sub main_controls_type.load ()
  dim as integer f
  
  f = utility.openfile("data/controls.txt", utility_file_mode_enum.for_input)
  input #f, p1_up
  input #f, p1_down
  input #f, p1_left
  input #f, p1_right
  input #f, p1_start
  input #f, p1_fire
  input #f, p1_alt
  input #f, p2_up
  input #f, p2_down
  input #f, p2_left
  input #f, p2_right
  input #f, p2_start
  input #f, p2_fire
  input #f, p2_alt
  input #f, forcequit
  close #f
end sub

function main_controls_type.ink(multikey_code as integer) as string
  'function is complete enough for our purposes
  'converts multikey code to inkey result string
  
  if multikey_code >= fb.SC_1 and multikey_code <= fb.SC_9 then return chr(asc("1") + multikey_code - fb.SC_1)
  
  select case multikey_code
  case fb.SC_ESCAPE: return chr(27)
  case fb.SC_UP: return chr(255, 72)
  case fb.SC_DOWN: return chr(255, 80)
  case fb.SC_LEFT: return chr(255, 75)
  case fb.SC_RIGHT: return chr(255, 77)
  case fb.SC_W: return "w"
  case fb.SC_A: return "a"
  case fb.SC_S: return "s"
  case fb.SC_D: return "d"
  case fb.SC_F: return "f"
  case fb.SC_C: return "c"
  case fb.SC_K: return "k"
  case fb.SC_COMMA: return ","
  end select
  
  return ""
end function

Sub main_levelpack_type.start ()
  Dim As Integer f
  Dim As String l
  
  if threadmutex = 0 then threadmutex = mutexcreate()
  
  f = utility.openfile("data/levelpacks/list.txt", utility_file_mode_enum.for_input)
  While Eof(f) = false
    Line Input #f, l
    addlp(l)
  Wend
  Close #f
End Sub

Sub main_levelpack_type.finish ()
  Dim As Integer f
  
  'the leveler may have added some packs to the list, so need to re-read the file, add new lps
  start()
  
  f = utility.openfile("data/levelpacks/list.txt", utility_file_mode_enum.for_output)
  For i As Integer = 1 To list_total
    Print #f, list(i).title
  Next i
  Close #f
  
  mutexdestroy(threadmutex)
End Sub

Sub main_levelpack_type.addlp (Byref t As String)
  Dim As Integer f, a, b, exists
  Dim As Integer l
  
  If list_total = list_max Then Exit Sub
  
  For i As Integer = 1 To list_total
    If list(i).title = t Then exists = i
  Next i
  
  'update iscompleted even if pack was already in list
  f = utility.openfile("data/levelpacks/" & Lcase(t) & "/data.txt", utility_file_mode_enum.for_input)
  if f = 0 then
    utility.logerror("List contains missing levelpack: " & t)
    return
  end if
  Input #f, a
  Input #f, b
  Close #f
  
  If exists = 0 Then
    list_total += 1
    list(list_total).title = t
    list(list_total).iscompleted = (a = b)
    utility.graphic.loadlevelpackpreview()
  Else
    list(exists).iscompleted = (a = b)
  End If
End Sub

Sub main_levelpack_type.load Overload (index As Integer)
  Dim As Integer f
  Dim As String ngfxset
  
  indexOf = index
  utility.graphic.clearpreviews()
  
  f = utility.openfile("data/levelpacks/" & Lcase(list(index).title) & "/data.txt", _
    utility_file_mode_enum.for_input)
  Input #f, level_total
  Line Input #f, ngfxset: gfxset = ngfxset
  For i as integer = 1 to highscore_max
    input #f, highscore_value(i)
    line input #f, highscore_name(i)
  next i
  Close #f
  
  'load titles for each level
  For i As Integer = 1 To level_total
    f = utility.openfile("data/levelpacks/" & Lcase(list(index).title) & "/" & i & ".txt", _
      utility_file_mode_enum.for_input)
    Line Input #f, level(i)
    Close #f
  Next i
End Sub

Sub main_levelpack_type.load Overload (t As String)
  For i As Integer = 1 To list_total
    If list(i).title = t Then load(i)
  Next i
End Sub

Sub main_levelpack_type.save ()
  'does not save the level titles, even though they are loaded
  
  Dim As Integer f
  
  f = utility.openfile("data/levelpacks/" & Lcase(title) & "/data.txt", _
    utility_file_mode_enum.for_output)
  Print #f, level_total
  Print #f, gfxset
  For i as integer = 1 to highscore_max
    print #f, highscore_value(i)
    print #f, highscore_name(i)
  next i
  Close #f
End Sub

function main_levelpack_type.addscore (score as integer) as integer
  if score <= highscore_value(highscore_max) then return 0
  
  for i as integer = highscore_max to 1 step -1
    if i = 1 orelse score <= highscore_value(i - 1) then
      highscore_name(i) = utility.gettext("New High Score!!")
      highscore_value(i) = score
      function = i
      exit for
    else
      highscore_name(i) = highscore_name(i - 1)
      highscore_value(i) = highscore_value(i - 1)
    end if
  next i
  
  save()
end function

property main_levelpack_type.gfxset () As String
  Mutexlock(threadmutex)
  property = _gfxset
  Mutexunlock(threadmutex)
End property

property main_levelpack_type.gfxset (Byref igfxset As String)
  Mutexlock(threadmutex)
  _gfxset = igfxset
  Mutexunlock(threadmutex)
End property

property main_levelpack_type.showname () As String
  Return list(indexOf).showname
End property

property main_levelpack_type.title () As String
  Return list(indexOf).title
End property

property main_levelpack_onepack_type.showname () As String
  Dim As String prefix
  If iscompleted = false Then prefix = "* "
  Return prefix & title
End property
