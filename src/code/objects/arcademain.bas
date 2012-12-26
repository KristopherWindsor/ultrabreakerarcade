
Sub main_type.run ()
  Const intro_length = 1
  
  Dim As Integer quit
  Dim As utility_framerate_type framerate
  
  start()
  
  while intro()
    choose_world()
    play()
    gameover()
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
  main.player.start()
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
  
  main.player.finish()
  main.levelpack.finish()
  
  game.finish()
  screen.finish()
  setting.finish ()
  sound.finish()
  utility.finish()
End Sub

sub main_type.choose_world()
  levelpack.load(1)
end sub

sub main_type.gameover()
  cls
  print "enter your name..."
  sleep 500,1
  
  cls
  print "show highscores now"
  sleep
end sub

function main_type.intro() as integer
  #define text1 "Ultrabreaker"
  #define text1x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text1) / screen.scale) / 2

  #define text2 "Press button to play"
  #define text2x (screen.default_sx - utility.font.abf.gettextwidth(utility.font.font_pt_selected, text2) / screen.scale) / 2

  dim as integer rotatecountdown = 20000
  dim as double angle, backgroundangle
  Dim As utility_framerate_type framerate = utility_framerate_type()

  framerate.reset()
  
  while true
    framerate.move()
    
    if multikey(controls.forcequit) then return false
    if multikey(controls.p1_start) then setting.players = 1: return true
    if multikey(controls.p2_start) then setting.players = 2: return true
    
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
      if backgroundangle > 0 then
        cls()
        multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.menubackground, 1, 0, backgroundangle)
      else
        multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.menubackground, 1, 0, backgroundangle , 100)
        if framerate.loop_total mod 18 >= 2 then
          utility.font.show(text1, text1x, screen.default_sy * .85)
          utility.font.show(text2, text2x, screen.default_sy * .90)
        end if
      end if
      multiput(0, screen.screen_sx \ 2, screen.screen_sy \ 2, utility.graphic.ball, 1, 0, angle)
      screenunlock()
    end if
  wend
  
  return false
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
      
      if game.mode.level + 1 = levelpack.level_total then
        game.mode.level = 1
        game.mode.speed *= sqr(2)
      else
        game.mode.level += 1
      end if
      game.mode.lives += .livesgained - .liveslost
      game.mode.orbtokens = .orbtokens
    end with
  loop
  
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
  Input #f, unlockedtotal
  Line Input #f, ngfxset: gfxset = ngfxset
  Line Input #f, unlocks
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
  Print #f, unlockedtotal
  Print #f, gfxset
  Print #f, unlocks
  Close #f
End Sub

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

Sub main_player_type.start ()
  #ifndef server_validator
  Dim As Integer f
  
  f = utility.openfile("data/players.txt", utility_file_mode_enum.for_input)
  While Eof(f) = false
    If name_total < name_max Then name_total += 1
    Line Input #f, Name(name_total)
  Wend
  Close #f
  #Endif
End Sub

Sub main_player_type.finish ()
  #ifndef server_validator
  Dim As Integer f
  
  f = utility.openfile("data/players.txt", utility_file_mode_enum.for_output)
  For i As Integer = 1 To name_total
    Print #f, Name(i)
  Next i
  Close #f
  #Endif
End Sub

property main_player_type.lastplayer() as string
  if name_total < 1 then return anonymous
  return name(1)
end property

property main_player_type.lastplayer(value as string)
  dim as integer index
  
  for i as integer = 1 to name_total
    if name(i) = value then index = i
  next i
  
  if index = 0 then
    if name_total < name_max then name_total += 1
    index = name_total
    name(index) = value
  end if
  
  for i as integer = index - 1 to 1 step -1
    swap name(i), name(i + 1)
  next i
end property
