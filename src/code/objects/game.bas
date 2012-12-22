
Sub game_type.start ()
  threadmutex = Mutexcreate()
  ball.start()
  bonus.start()
  enemy.start()
  gravity.start()
  item.start()
  laser.start()
  paddle.start()
  weather.start()
  xfx.start()
End Sub

Sub game_type.reset ()
  
  frametotal = 0
  delay_win = 0
  delay_lose = 0
  
  data_collected_levelup = 0
  data_rapidfire = 0
  data_rapidfire_launchload = 0
  data_isgameover = false
  data_getpreview = false
  data_masterdone = false
  
  mode_shooter = false
  mode_balltrail = false
  mode_invertedcolors = false
  mode_pixelation = false
  mode_speedfactor = fps / framerate.fps_loop '60 * 2 = 120 FPS for physics
  mode_windfactor = 1
  
  tracker_lifelost = -1E8
  tracker_bonuscollect = -1E8
  tracker_bonustitle = ""
  
  replay.reset()
  
  With setting
    .requiredscore = defaultrequiredscore
    .timelimit = timemax * fps
    .tip = ""
    .tiplose = ""
    .tipwin = ""
    
    .gfx_background_color = color_enum.white
    .gfx_background_image = ""
    .gfx_background_tile = false
    
    .special_noballlose = false
    .special_nobrickwin = false
    .special_shooter = false
  end with
  
  with result
    .didcheat = false
    .didforfeit = false
    .didwin = false
    .liveslost = 0
    .livesgained = 0
    .orbtokens = mode.orbtokens
    .savegame = false
    .instantrestart = false
    
    .scoregained = 0 'property call updates master score
  End With
  
  For i As Integer = 1 To ..setting.players
    With control(i)
      .x = screen.default_sx Shr 1
      .y = screen.default_sy Shr 1
      .click = false
      .launchdelay = 0
    End With
  Next i
  input_usemouse = false
  
  var nada = get_score() 'reset static var in this function
  
  ball.reset()
  bonus.reset()
  brick.reset()
  enemy.reset()
  explodepaddle.reset()
  gravity.reset()
  item.reset()
  laser.reset()
  orb.reset()
  paddle.reset()
  weather.reset()
  xfx.reset()
End Sub

Sub game_type.gfxchange ()
  Static As String graphics
  
  Dim As Any Ptr threads(1 To 10)
  
  If graphics = main.levelpack.gfxset Then Exit Sub
  graphics = main.levelpack.gfxset
  
  'the only threads that are related are laser / paddle (laser has to load first)
  
  threads(1) = Threadcreate(@laser_gfxchange_threadable)
  threads(2) = Threadcreate(@ball_gfxchange_threadable)
  threads(3) = Threadcreate(@bonus_gfxchange_threadable)
  threads(4) = Threadcreate(@brick_gfxchange_threadable)
  threads(5) = Threadcreate(@enemy_gfxchange_threadable)
  threads(6) = Threadcreate(@gravity_gfxchange_threadable)
  threads(7) = Threadcreate(@item_gfxchange_threadable)
  threads(8) = Threadcreate(@weather_gfxchange_threadable)
  threads(9) = Threadcreate(@xfx_gfxchange_threadable)
  
  Sleep(250, 1)
  Threadwait(threads(1))
  threads(10) = Threadcreate(@paddle_gfxchange_threadable)
  
  For i As Integer = 2 To 10
    Threadwait(threads(i))
  Next i
End Sub

Sub game_type.reset2 ()
  const frames = 40
  
  Dim As Integer f, startheight, endheight
  Dim As Double tx, ty
  Dim As utility_framerate_type framerate
  Dim As utility_font_setting_type font
  
  paddle.reset2()
  ball.reset2()
  bonus.reset2()
  brick.reset2()
  item.reset2()
  text.reset()
  
  if ucase(command(1)) = "GETSCREENS" then
    data_getpreview = true
  else
    f = utility.openfile("data/levelpacks/" + lcase(main.levelpack.title) + _
      "/" & mode.level & ".png", utility_file_mode_enum.for_input, true)
    if f = 0 then data_getpreview = true else close #f
  end if
  
  'show the intro to the level
  #ifndef server_validator
  While Len(Inkey()) > 0: Wend 'clear key buffer; IE only restart once if the R key was held down
  framerate.reset()
  
  tx = screen.default_sx * .5
  tx -= utility.font.abf.gettextwidth(utility.font.font_pt_selected, get_levelname()) / (screen.scale * 2)
  ty = screen.default_sy * .4
  
  With framerate
    For i As Integer = 1 To frames
      .move()
      
      If .candisplay() Then
        font.rotation = pi * (1 - i / frames) * .5
        Screenlock()
        Line (0, 0) - (screen.screen_sx, screen.screen_sy), color_enum.white, BF
        utility.font.show(get_levelname(), tx - (frames - i) * 15 * dsfactor, ty - (frames - i) * 12 * dsfactor, font)
        Screenunlock()
      End If
    Next i
    font.rotation = 0
    
    startheight = -((screen.screen_sy + screen.corner_sy) / screen.scale)
    endheight = -(screen.corner_sy / screen.scale)
    For d As Double = startheight To endheight Step -startheight / frames
      .move()
      
      If .candisplay() Then
        f = Int(brick_graphic_type.frame_ratefactor * .loop_total / .fps_loop + 4) Mod 6 + 1
        Screenlock()
        Put (0, screen.scale_y(d)), brick.graphic.brickset(f), _
          alpha, ..setting.alphavalue
        
        For i As Integer = 1 To brick.total
          With brick.object(i)
            If .independant Then
              Put (screen.scale_x(.x1), screen.scale_y(.y1 + d)), _
                brick.graphic.mini(.graphic_mini).b.g(f), trans
            End If
          End With
        Next i
        
        For i2 As Integer = -7 To 7 Step 2
          xfx.graphic.glow_show(screen.default_sx / 2 + i2 * 70 * dsfactor, ty)
        Next i2
        utility.font.show(get_levelname(), tx, ty, font)
        Screenunlock()
      End If
    Next d
  End With
  
  this.framerate.reset()
  #Endif
End Sub

Sub game_type.run ()
  'play one level, report progress
  
  static as string cheat
  
  Dim As Integer f, screenshot, quit
  dim as integer forcedraw, spresses 'forcedraw after pressing "s"
  Dim As Double menu_t
  Dim As String key, key2
  Dim As menu_setting_type mainmenu, info
  
  With mainmenu
    .title = "#" & mode.level & " " & get_levelname()
    .option_total = 5
    .option(1) = "Screenshot"
    .option(2) = "Info"
    .option(3) = "Cheats"
    .option(4) = "Set volume"
    .option(5) = "Quit"
    .screenshot_ison = true
  End With
  
  load()
  superfluous If ..setting.mouseclipping Then Setmouse(,,, 1)
  
  #ifndef server_validator
  Do
    key = Inkey()
    If Len(key) = 0 Then key = key2
    key2 = ""
    
    Select Case key
    Case ""
    Case "m"
      sound.audio.fire_music()
    Case "q"
      result.didforfeit = true
    Case "r"
      If mode.instantrestart Then
        result.instantrestart = true
        Exit Do
      End If
    Case "s"
      'no "slow mo" tricks allowed
      spresses += 1
      if spresses = 10 then
        sound.add(sound_enum.thud)
        result.didcheat = true
      end if
      
      While Len(Inkey()) > 0: Wend
      Do
        sound.move()
        Sleep(1000) 'may replay this much of a track before going to the next one
        key2 = Inkey()
      Loop Until Len(key2) > 0
      framerate.fixtimeout()
      forcedraw = true
    Case "v"
      If frametotal = 0 And mode.replayfile <> 0 And video.isStarted = false Then
        video.start("videos/" & utility.gettext("filename") & ".avi")
      End If
    Case Chr(255, 75)
      'FREEZE cheat, for replays only
      If mode.replayfile <> 0 Then
        If mode_speedfactor > 0 Then mode_speedfactor -= 1
      End If
    Case Chr(255, 77)
      'WARP cheat, for replays only
      If mode.replayfile <> 0 Then mode_speedfactor += 1
    Case Chr(27)
      menu_t = Timer
      Get (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), utility.graphic.screenshot
      If ..setting.mouseclipping Then Setmouse(,,, 0)
      
      mainmenu.scrolloffset = 0
      Select Case menu.show(mainmenu)
      Case 1
        'screenshot
        f = utility.openfile("data/screenshot.txt", utility_file_mode_enum.for_input)
        Input #f, screenshot
        Close #f
        screenshot += 1
        f = utility.openfile("data/screenshot.txt", utility_file_mode_enum.for_output)
        Print #f, screenshot
        Close #f
        
        f = utility.openfile("data/screenshot-captions.txt", utility_file_mode_enum.for_append)
        print #f, left(main.levelpack.title & " #" & mode.level, 16)
        Close #f
        
        With utility.graphic
          png_save24("screenshots/" & screenshot & ".png", .screenshot)
          image_scaler(.screenshot_thumb, 0, 0, .screenshot, 240 / screen.screen_sy)
          png_save24("screenshots/thumbs/" & screenshot & ".png", .screenshot_thumb)
        End With
      Case 2
        'info
        With info
          .title = "Info"
          .readonly = true
          .option_total = 32 - (((Timer() * 1000) Mod 50) = 0)
          
          .option(1) = get_levelname()
          If orb.total >= 1 Then
            var orb_power = 0
            for i as integer = 1 to orb.total
              if orb.object(i).lives > orb_power then orb_power = orb.object(i).lives
            next i
            .option(2) = "Power: " & utility.percentage(orb_power / orb.lives_max)
          Else
            .option(2) = ""
          End If
          .option(3) = "Lives: " & (mode.lives + result.livesgained - result.liveslost)
          .option(4) = get_time()
          If paddle.total >= 1 Then
            var paddle_shield_total = paddle.lives_max
            For i As Integer = 1 To paddle.total
              If paddle.object(i).lives < paddle_shield_total Then paddle_shield_total = paddle.object(i).lives
            Next i
            .option(5) = "Shields: " & utility.percentage(paddle_shield_total / paddle.lives_max)
          Else
            .option(5) = ""
          End If
          .option(6) = "" 'score shown by callback
          
          .option(8) = "Laser power: " & laser.power
          .option(9) = "Laser stock: " & Int(laser.launchload)
          
          .option(11) = "Ball total: " & ball.total
          .option(12) = "Bonus total: " & bonus.total
          .option(13) = "Brick total: " & brick.total
          .option(14) = "Enemy total: " & enemy.total
          .option(15) = "Flying brick total: " & xfx.flyingbrick.total
          .option(16) = "Gravity total: " & gravity.total
          .option(17) = "Item total: " & item.total
          .option(18) = "Laser total: " & laser.total
          .option(19) = "Orb total: " & orb.total
          .option(20) = "Paddle total: " & paddle.total
          .option(21) = "Particle total: " & xfx.particle.total
          
          'show default speed for this level, then show actual speed of a ball
          .option(23) = "Ball speed: " & utility.percentage(mode.speed * ball.data_speed)
          If ball.total > 0 Then
            var b1 = @ball.object(1)
            .option(23) += " (" & Cint(screen.scale * Sqr(b1->xv * b1->xv + b1->yv * b1->yv)) & " px/sec)"
          End If
          .option(24) = "Orb tokens: " & result.orbtokens & " / 3"
          
          .option(26) = "Ball scale: " & utility.percentage(ball.object(1).scale / ball.scalefactor)
          .option(27) = ""
          If enemy.total >= 1 Then
            .option(27) = "Enemy scale: " & utility.percentage(enemy.object(1).scale / enemy.scalefactor)
          End If
          .option(28) = "Paddle scale: " & utility.percentage(paddle.data_scale / paddle.scale_factor)
          .option(29) = "Screen scale: " & utility.percentage(screen.view_sx / screen.preferred_sx)
          
          .option(31) = "Display rate: ~" & _
            Int((framerate.displaylog_max - 1) / _
            (framerate.t - framerate.displaylog(framerate.displaylog_max)) + .5) & "FPS"
          .option(32) = "Ultrabreaker v" & ultrabreaker_version_major & "." & ultrabreaker_version_minor
          .option(33) = "Kristopher <3 pizza!!!"
          .callback = @menu_callback_info()
        End With
        menu.show(info)
      Case 3
        'cheats
        cheat = Ucase(utility.gettext(cheat))
        result.didcheat Or= (cheat <> "RESUBMIT" And cheat <> "SUBMITNOW" And _
          cheat <> "DIEDIEDIE" And cheat <> "SPEAK" And cheat <> "DEV" And cheat <> "HARDCORE" and _
          cheat <> "README" and cheat <> "WELCOME")
        
        Select Case cheat
        Case "5XOMATIC"
          For i As Integer = 1 To brick.total
            With brick.object(i)
              .replication = 5
            End With
          Next i
        Case "ABUNCH"
          For i As Integer = 1 To 20
            ball.add(1)
          Next i
        Case "BAZOOKASCHOOL"
          data_rapidfire += 5
        Case "BOMBPOWER"
          with brick
            If .total < .max Then
              .add(screen.default_sx / 2, screen.default_sy / 2, _
                brick_enum.explode, .5 * dsfactor, 4,,, true)
              .graphic.set_mini(.object(.total))
              .replicate(.object(.total))
            End If
          end with
        Case "DEV"
          server.processcommands(!"OPEN http://games.freebasic.net/forum/index.php?topic=219.msg3733#msg3733\nEND")
        Case "DIEDIEDIE"
          result.liveslost = mode.lives
          result.livesgained = 0
          mode.lives = 0
          ball.total = 0
          paddle.total = 0
        Case "FIRE"
          For i As Integer = 1 To ball.total
            ball.object(i).style = ball_enum.fire
          Next i
        Case "FREEBASIC"
          orb.add()
        Case "FREEZE"
          If mode_speedfactor > 0 Then mode_speedfactor -= 1
        Case "GARFIELD"
          'more time: 5 minutes
          setting.timelimit += fps * 60 * 5
          If setting.timelimit > timemax * fps Then setting.timelimit = timemax * fps
        Case "HARDCORE"
          mode_hardcore = Not mode_hardcore
        Case "INVERSE"
          'invert all gravity (switch repel / attract effect)
          For i As Integer = 1 To gravity.total
            gravity.object(i).scale *= -1
          Next i
        Case "MASTERLASERS"
          'full-power lasers
          laser.power += laser.powerbonus_cheat
          If laser.power = laser.powerbonus_cheat Then paddle.graphic.gfxreset()
        Case "METALMAN"
          weather.add(weather_enum.metal)
        Case "NEWLIFE"
          'extra life
          result.livesgained += 10
        Case "NINJASHIELDS"
          For i As Integer = 1 To paddle.total
            paddle.object(i).lives *= 1000
          Next i
        Case "PADDLESROCK"
          'more paddles
          For i As Integer = 1 To paddle_side_enum.max
            If paddle.quantities(i) > 0 Then paddle.add(i)
          Next i
        Case "PIXEL"
          mode_pixelation = true
        Case "README"
          shell("start readme.txt")
        Case "RESUBMIT"
          'not a cheat!
          main.levelpack.resubmit()
        Case "SEASICK"
          For i As Integer = 1 To brick.total
            brick.graphic.erasebrick(brick.object(i))
            With brick.object(i)
              .bouncy = true
              .independant = true
              .xv = 1
              .yv = 0
            End With
          Next i
        Case "SKIPIT"
          'levelup
          data_collected_levelup = true
        Case "SOLARIZE"
          mode_invertedcolors = true
        Case "SPEAK"
          sound.speak("What do you want me to say?")
          sound.speak(utility.gettext("I do not know english!"))
        Case "SUBMITNOW"
          'not a cheat!
          server.sync(false)
        Case "SUPERCONTROL"
          'super paddle / normal paddle (toggle)
          For i As Integer = 1 To paddle.total
            With paddle.object(i)
              .style = 3 - .style
            End With
          Next i
        Case "THEBOSS"
          enemy.add(screen.default_sx / 2, screen.default_sy / 2, _
            enemy_enum.destroyer, 2, 1500)
        case "TORNADO"
          mode_windfactor = 50
        Case "TRAILS"
          'ball trail (even if it's not a fireball)
          mode_balltrail = true
        case "TWSS"
          for i as integer = 1 to ball.total
            ball.object(i).scale *= 2
            ball.object(i).fixstuckposition()
          next i
        Case "UNORB"
          result.orbtokens = 0 'you might want this if you are testing your new level
        Case "WALLSTREET"
          'more points
          result.scoregained = result.scoregained + 1000
        Case "WARP"
          mode_speedfactor += 1
        case "WELCOME"
          server.processcommands(!"OPEN http://ultrabreaker.com/forum/index.php?topic=16\nEND")
        case "WINDY"
          mode_windfactor = 8
        Case Else
          key = utility.gettext("Fail!", true)
          key = ""
        End Select
      Case 4
        sound.set_volume()
      Case 5
        If menu.confirm("Quit?", true) Then result.didforfeit = true
      End Select
      menu.showclosing()
      
      'display game, then pause briefly before things move again
      For i As Integer = 1 To 12
        display()
        Sleep(20, 1)
      Next i
      
      While Len(Inkey()) > 0: Wend
      If ..setting.mouseclipping Then Setmouse(,,, 1)
      
      framerate.fixtimeout()
    End Select
    If utility.quitprogram(key, @framerate) Then result.didforfeit = true
    
    'return to menu if testing mode is over
    If mode.tslave Then
      If menu_callback_test(mainmenu, 0) < 0 Then
        result.didforfeit = true
      End If
    End If
    
    framerate.move()
    
    'this is the main move() and display() stuff
    If video.isStarted Then
      'constant display rate of 30 FPS
      For i As Integer = 1 To 4
        move()
        If get_winloss() Then Exit Do
      Next i
      display()
      Sleep(5, 1)
      video.capture()
    Else
      'replay speed controlled here
      For i As Integer = 1 To mode_speedfactor
        move()
        If get_winloss() Then Exit Do
      Next i
      If framerate.candisplay() or forcedraw Then display(): forcedraw = false
    End If
    
  Loop
  #Else
  Do
    move()
  Loop Until get_winloss()
  #Endif
  
  summary()
End Sub

Sub game_type.move ()
  
  Static As Integer delayadjustment
  
  Dim As Integer oldclickstate1, oldclickstate2, ballsarestuck
  Dim As Double angle
  
  frametotal += 1
  If frametotal = 1 Then delayadjustment = 0
  
  'save preview thumbail
  #ifndef server_validator
  if data_getpreview and frametotal = fps \ 2 then
    Get (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), utility.graphic.previewshot
  end if
  #endif
  
  With utility.mouse
    .update()
    If .c.sx <> .p.sx Or .c.sy <> .p.sy Then input_usemouse = true
  End With
  
  With game
    oldclickstate1 = .control(1).click
    oldclickstate2 = (.control(2).click And ..setting.players > 1)
    
    'keyboard controls
    #ifndef server_validator
    .input_key_x = Abs(Multikey(fb.SC_RIGHT)) - Abs(Multikey(fb.SC_LEFT))
    .input_key_y = Abs(Multikey(fb.SC_DOWN)) - Abs(Multikey(fb.SC_UP))
    If .input_key_x <> 0 Or .input_key_y <> 0 Then .input_usemouse = false
    
    If ..setting.players = 1 Then
      If .input_usemouse Then
        .control(1).x = utility.mouse.c.sx
        .control(1).y = utility.mouse.c.sy
      Else
        .control(1).x += .input_key_x * ..setting.keyboardspeed
        .control(1).y += .input_key_y * ..setting.keyboardspeed
      End If
      .control(1).click = utility.mouse.c.b > 0 Or Multikey(fb.sc_space)
    Else
      With .control(1)
        .x = utility.mouse.c.sx
        .y = utility.mouse.c.sy
        .click = utility.mouse.c.b > 0
      End With
      With .control(2)
        .x += input_key_x * ..setting.keyboardspeed
        .y += input_key_y * ..setting.keyboardspeed
        .click = Multikey(fb.sc_space)
      End With
    End If
    #Endif
    
    For i As Integer = 1 To ..setting.players
      With .control(i)
        If .x < 0 Then .x = 0
        If .x >= screen.default_sx Then .x = screen.default_sx - 1
        If .y < 0 Then .y = 0
        If .y >= screen.default_sy Then .y = screen.default_sy - 1
        If .launchdelay > 0 Then .launchdelay -= 1
      End With
    Next i
    
    'replay: record control, or set it
    With replay
      If mode.replayfile = 0 Then
        .recordframe()
      Else
        'adjustment added to fix ushort limit
        If .frame_current > 0 andalso .frame_current < .header.frame_total andalso .frame(.frame_current + 1).delay < .frame(.frame_current).delay Then
          delayadjustment = &HFFFF
        End If
        
        'replay
        If ..setting.players = 1 Then
          If .frame(.frame_current + 1).delay + delayadjustment <= frametotal And .frame_current < .header.frame_total Then .frame_current += 1
          control(1) = .frame(.frame_current).to_controlstate()
        Else
          If .frame(.frame_current + 1).delay + delayadjustment <= frametotal And .frame_current < .header.frame_total Then .frame_current += 2
          control(1) = .frame(.frame_current - 1).to_controlstate
          control(2) = .frame(.frame_current).to_controlstate()
        End If
        
        'force quit if the game ended
        If frametotal = .frame(.header.frame_total).delay + delayadjustment Then
          result.didforfeit = true
        End If
      End If
    End With
    
    'allow rapid ball release from fast clicking
    If (.control(1).click And oldclickstate1 = false) Then
      .control(1).launchdelay = 0
    End If
    If (.control(2).click And ..setting.players > 1 And oldclickstate2 = false) Then
      .control(2).launchdelay = 0
    End If
    
    'rapidfire
    .data_rapidfire_launchload += .data_rapidfire
    If .data_rapidfire_launchload > framerate.fps_loop * rapidfirerate And frametotal Mod 20 = 0 Then
      .data_rapidfire_launchload -= framerate.fps_loop * rapidfirerate
      ball.addgroup(false)
    End If
    
    'ball bump
    If (.control(1).click And oldclickstate1 = false) Or _
      (.control(2).click And ..setting.players > 1 And oldclickstate2 = false) Then
      
      If laser.power = 0 Then
        For i As Integer = 1 To ball.total
          If ball.object(i).stuck Then ballsarestuck = true
        Next i
        
        If ballsarestuck = false Then
          angle = pi * 2 * Rnd()
          For i As Integer = 1 To ball.total
            With ball.object(i)
              .x += Cos(angle) * ballbumpfactor
              .y += Sin(angle) * ballbumpfactor
            End With
          Next i
          xfx.camshake.add(.2)
        End If
      End If
    End If
  End With
  
  text.move()
  
  'special modes (shooter)
  If mode_shooter Then
    'add rocks
    If Int(Rnd() * framerate.fps_loop * shootermoderockrate) = 0 Then
      bonus.add(0, 0, bonus_enum.paddle_destroy, 1 / sqr(2), 1 / sqr(2), 0, 0)
      bonus.add(screen.default_sx - 1, 0, bonus_enum.paddle_destroy, -1 / sqr(2), 1 / sqr(2), 0, 0)
    End If
    If Int(Rnd() * framerate.fps_loop * shootermoderockrate) = 0 Then
      bonus.add(0, screen.default_sy * .4, bonus_enum.paddle_destroy, 1 / sqr(2), 1 / sqr(2), 0, 0)
      bonus.add(screen.default_sx - 1, screen.default_sy * .4, bonus_enum.paddle_destroy, -1 / sqr(2), 1 / sqr(2), 0, 0)
    End If
    'add coins
    If Int(Rnd() * framerate.fps_loop * shootermodecoinrate) = 0 Then
      For d As Double = 0 To pi Step pi / shootermodecoinmax
        bonus.add(screen.default_sx / 2, 0, bonus_enum.bonus_score, Cos(d), Sin(d), 0, 0)
      Next d
    End If
    'add an enemy
    If Int(Rnd() * framerate.fps_loop * shootermodeenemyrate) = 0 Then
      If enemy.total < shootermodeenemymax Then
        enemy.add(Int(Rnd() * screen.default_sx), 0, enemy_enum.scout, Rnd() + .5, shootermodeenemyvalue)
      end if
    End If
  End If
  
  weather.move()
  paddle.move()
  orb.move()
  enemy.move()
  ball.move()
  brick.move()
  bonus.move()
  explodepaddle.move()
  gravity.move()
  laser.move()
  item.move()
  xfx.move()
  
  sound.move()
End Sub

Sub game_type.display ()
  #ifndef server_validator
  Static As Integer tx, ty
  Static As Double progress
  Static As utility_font_setting_type font
  
  Screenlock()
  brick.display()
  xfx.flyingbrick.display()
  item.display()
  gravity.display()
  bonus.display()
  enemy.display()
  ball.display()
  laser.display()
  paddle.display()
  orb.display()
  text.display()
  xfx.nuke.display()
  explodepaddle.display()
  xfx.particle.display()
  weather.display()
  
  If framerate.loop_total < framerate.fps_loop * 5 Then
    progress = framerate.loop_total / framerate.fps_loop
    
    tx = screen.default_sx * .5
    tx -= utility.font.abf.gettextwidth(utility.font.font_pt_selected, get_levelname()) / (screen.scale * 2)
    ty = screen.default_sy * .4
    
    For i2 As Integer = -7 To 7 Step 2
      xfx.graphic.glow_show(screen.default_sx / 2 + i2 * 70 * dsfactor + Sgn(i2) * progress * 200 * dsfactor, ty)
    Next i2
    
    If progress < 1 Then
      'show level name with waning opacity
      font.c = Int(255 - 255 * progress) Shl 24
      utility.font.show(get_levelname(), tx, ty, font)
    End If
  End If
  
  If weather.is_metal Then xfx.graphic.effect_metal()
  If mode_pixelation Then xfx.graphic.effect_pixelation()
  If mode_invertedcolors Then xfx.graphic.effect_inverse()
  
  Screenunlock()
  #Endif
End Sub

Sub game_type.finish ()
  ball.finish()
  bonus.finish()
  brick.finish()
  enemy.finish()
  explodepaddle.finish()
  laser.finish()
  gravity.finish()
  item.finish()
  paddle.finish()
  weather.finish()
  xfx.finish()
  Mutexdestroy(threadmutex)
End Sub

Function game_type.get_levelname () As String
  return main.levelpack.level(mode.level)
end function

Function game_type.get_score () As String
  Static As Integer ss
  
  Dim As Integer percent
  Dim As String r
  
  With result
    If ss > .scoregained Then
      ss = .scoregained
    Elseif .scoregained > ss Then
      ss += 6
      If ss > .scoregained Then ss = .scoregained
      If .scoregained - ss > 1000 Then ss += 10
      If .scoregained - ss > 5000 Then ss += 100 '111 makes 3 digits change at once
    End If
    
    r = "Score: " & ss
    If ss > .scoregained_master Then
      r += " (" & .scoregained_master & ")"
    End If
    
    percent = cInt(100 * ss / setting.requiredscore)
    If percent > 100 Then percent = 100
    If percent > 25 Then r += " (" & percent & "%)"
  End With
  
  Return r
End Function

Function game_type.get_time () As String
  Return "Time: " & utility.formattime(frametotal) + " / " & utility.formattime(setting.timelimit)
End Function

Function game_type.get_winloss () As Integer
  'set win / loss flags, handle the event where the player loses a life, etc
  
  #define is_win() ((brick.iscleared And enemy.total = 0 And setting.special_nobrickwin = false) Or _
    (.scoregained >= setting.requiredscore) Or (data_collected_levelup))
  
  #define is_loss() (is_loss_time() or is_loss_death())
  
  #define is_loss_time() (setting.timelimit < frametotal)
  
  #define is_loss_death() (ball.total = 0 And orb.total = 0 And (setting.special_noballlose = false Or _
    aretherelasers = false Or paddle.total = 0))
  
  Dim As Integer did_win, did_lose, gameover, aretherelasers
  
  aretherelasers = (laser.power > 0)
  If aretherelasers = false Then
    For i As Integer = 1 To bonus.total
      If bonus.object(i).style = bonus_enum.paddle_laser Then aretherelasers = true: Exit For
    Next i
  End If
  
  With result
    ' meet any condition
    ' WIN:
    '	- all bricks broken
    '	- level up bonus
    '	- enough points collected
    ' LOSS:
    '	- all lives lost
    '	- forfeit
    '	- time runs out
    
    'if win / loss, wait a second... then retest and apply
    
    did_win = is_win()
    did_lose = is_loss()
    
    If did_win And delay_win = 0 Then
      'sound_add(sound_enum.win)
      sound.add(sound_enum.main_levelcomplete)
      delay_win = fps
      xfx.camshake.add(1)
    End If
    If did_lose And delay_lose = 0 Then
      'sound.add(sound_enum.lose)
      sound.add(sound_enum.main_lifelost)
      delay_lose = fps
      xfx.camshake.add(1)
    End If
    
    If delay_win > 0 Then delay_win -= 1
    If delay_lose > 0 Then delay_lose -= 1
    
    If delay_win = 1 Then
      'delay is over; check for win
      If did_win Then
        .didwin = true
        gameover = true
      End If
    End If
    
    If delay_lose = 1 Then
      'delay is over; check for loss
      
      If is_loss_death() Then
        'life lost -> attempt to keep person in the game by respawning
        If mode.lives + .livesgained - .liveslost > 0 Then
          paddle.addgroup()
          If ball.total = 0 Then ball.addgroup(true)
          tracker_lifelost = frametotal
        End If
        .liveslost += 1
      End If
      
      'are you still lost? eg you have no lives left
      If is_loss() Then
        .didwin = did_win
        gameover = true
      End If
    End If
    
    'masterdone = true when you've lost a life
    'but if the game is over, don't bother setting masterdone (that way, you can get the timebonus if you won at the same time)
    If .livesgained - .liveslost < 0 And gameover = false Then data_masterdone = true
    
    'can't forfeit on the last frame, especially if game replay is over
    If gameover Then .didforfeit = false
  End With
  
  'if gameover then sound.add(sound_enum.main_levelcomplete)
  
  Return gameover Or result.didforfeit
End Function

Sub game_type.load ()
  'load level data file, show loading bar and intro, call game_gfxchange()
  
  #macro brickscaling ()
    Select Case brick_s
    Case 0: brick_s = .1
    Case 1: brick_s = .2
    Case 2: brick_s = .4
    Case 3: brick_s = .8
    Case 4: brick_s = 1
    Case 5: brick_s = 1.2
    Case 6: brick_s = 1.5
    Case 7: brick_s = 2
    Case 8: brick_s = 3
    Case 9: brick_s = 4
    End Select
  #endmacro
  
  Const arg_max = 8, version_min = 1, version_max = ultrabreaker_version_major + 1 'allowed version range
  
  Dim As Integer arg_total, f, t1, t2, layer_autoexplode
  Dim As Integer brick_c, brick_v
  Dim As Double brick_pen_x, brick_pen_y 'where to draw the brick
  Dim As Double brick_s, brick_scale '_s is typically 1; _scale typically is spacing / 200px
  Dim As Double brick_spacing_x, brick_spacing_y 'the distance between each brick (the size of the brick at the default size)
  Dim As Double brick_total_x, brick_total_y 'how many rows and cols in the field
  Dim As Double version
  Dim As String abrick, l, arg(0 To arg_max)
  
  'need a lower framerate to slow the fade
  '(can't lower the alpha because then some things wouldn't be cleared)
  Dim As utility_framerate_type framerate = utility_framerate_type(50)
  
  'fade out to white
  #ifndef server_validator
  Dim As fb.image Ptr white
  white = utility.createimage(screen.screen_sx, screen.screen_sy mop("white"), color_enum.white)
  framerate.reset()
  For i As Integer = 1 To 60
    framerate.move()
    xfx.particle.move()
    
    If framerate.candisplay() Then
      Screenlock
      If i <= 40 Then
        Put (0, 0), white, alpha, 40 + i * 3
        xfx.particle.display(Rgb(i * 6, i * 6, i * 6))
      Else
        Put (0, 0), white, alpha, i * 5 - 45
      End If
      Screenunlock
    End If
  Next i
  framerate.move()
  Put (0, 0), white, Pset
  utility.deleteimage(white mop("white"))
  #Endif
  
  this.reset()
  
  With setting
    f = utility.openfile("data/levelpacks/" & Lcase(main.levelpack.title) & "/" & _
      mode.level & ".txt", utility_file_mode_enum.for_input)
    Line Input #f, l
    While Not Eof(f)
      Line Input #f, l
      l = Trim(l)
      If Left(l, 2) = "//" Then Continue While
      
      arg_total = -1
      t1 = 0
      Do
        t2 = t1
        t1 = Instr(t1 + 1, l, Any Chr(9, 32))
        If t1 = 0 Then t1 = Len(l) + 1
        If t1 - t2 > 1 Then
          If arg_total < arg_max Then arg_total += 1
          arg(arg_total) = Mid(l, t2 + 1, t1 - t2 - 1)
        End If
      Loop Until t1 = Len(l) + 1
      If arg_total < 0 Then Continue While
      
      Select Case Ucase(arg(0))
      Case "ABRICK"
        If arg_total = 3 Then
          brick_spacing_x = (brick.field_x2 - brick.field_x1) / brick_total_x
          brick_pen_x = brick.field_x1 - brick_spacing_x * .5
          brick_pen_x += Val(arg(1)) * brick_spacing_x '(brick.field_x2 - brick.field_x1 - brick_spacing_x) * Val(arg(1)) / 100
          
          brick_spacing_y = brick_spacing_x * brick.graphic.brick_sy / brick.graphic.brick_sx
          brick_pen_y = brick.field_y1 - brick_spacing_y * .5
          brick_pen_y += Val(arg(2)) * brick_spacing_y '(brick.field_y2 - brick.field_y1 - brick_spacing_y) * Val(arg(2)) / 100
          
          abrick = arg(3)
          
          If Left(abrick, 1) = "[" And Right(abrick, 1) = "]" Then
            brick_c = Instr(brick.codes, Mid(abrick, 2, 1))
            If brick_c > 0 Then
              brick_s = Val(Mid(abrick, 3, 1))
              brickscaling()
              brick_v = Val(Mid(abrick, 4, 1))
              brick.add(brick_pen_x, brick_pen_y, brick_c, brick_s * brick_scale, brick_v,,,,, layer_autoexplode)
            End If
          End If
        End If
      Case "BACKGROUND"
        If arg_total >= 1 And arg_total <= 3 Then
          .gfx_background_color = Val("&H" & arg(1))
          If arg_total >= 2 Then
            .gfx_background_image = arg(2)
            .gfx_background_tile = false
            If arg_total = 3 And arg(3) = "tile" Then .gfx_background_tile = true
          End If
        End If
      Case "BALLMULTIPLIER"
        If arg_total = 1 Or arg_total = 2 Then
          with ball
            .data_multiplier = Val(arg(1))
            if .data_multiplier < 1 then .data_multiplier = 1
            .data_melee = ((arg(2) = "melee") And arg_total = 2)
          end with
        End If
      Case "BALLSIZE"
        If arg_total = 1 Then
          With ball
            .data_scale = Val(arg(1))
            If .data_scale * .scalefactor > .scalemax Then .data_scale = .scalemax / .scalefactor
            If .data_scale * .scalefactor < .scalemin Then .data_scale = .scalemin / .scalefactor
          End With
        End If
      Case "BALLSPEED"
        with ball
          If arg_total = 1 Then
            .data_speed = Val(arg(1))
            if .data_speed * .speedfactor < .speedmin then .data_speed = .speedmin / .speedfactor
            if .data_speed * .speedfactor > .speedmax then .data_speed = .speedmax / .speedfactor
          end if
        end with
      Case "BONUSLIVES"
        If arg_total = 1 Then result.livesgained += Val(arg(1))
      Case "BRICKSET"
        with brick
          If arg_total >= 2 And arg_total <= 4 Then
            brick_total_x = Val(arg(1))
            brick_total_y = Val(arg(2))
            
            brick_spacing_x = (.field_x2 - .field_x1) / brick_total_x
            If arg_total >= 3 And arg(3) = "ycollapse" Then
              brick_spacing_y = brick_spacing_x * .graphic.brick_sy / .graphic.brick_sx
            Else
              brick_spacing_y = (.field_y2 - .field_y1) / brick_total_y
            End If
            
            layer_autoexplode = 0
            If arg_total = 4 Then layer_autoexplode = Val(arg(4))
            
            'global variable is the scale of bricks set to size '4'
            If brick_spacing_x * .graphic.brick_sy < brick_spacing_y * .graphic.brick_sx Then
              brick_scale = brick_spacing_x / .graphic.brick_sx
            Else
              brick_scale = brick_spacing_y / .graphic.brick_sy
            End If
            
            'the coords of the first brick (top left coords of first brick will be (x, y))
            brick_pen_x = .field_x1 + brick_spacing_x * .5
            brick_pen_y = .field_y1 + brick_spacing_y * .5
            
            'add set
            For y As Integer = 1 To brick_total_y
              Line Input #f, l
              For x As Integer = 1 To brick_total_x
                abrick = Mid(l, x * 5 - 4, 5)
                If Left(abrick, 1) = "[" And Right(abrick, 1) = "]" Then
                  brick_c = Instr(.codes, Mid(abrick, 2, 1))
                  If brick_c > 0 Then
                    brick_s = Val(Mid(abrick, 3, 1))
                    brickscaling()
                    brick_v = Val(Mid(abrick, 4, 1))
                    .add(brick_pen_x, brick_pen_y, brick_c, _
                      brick_s * brick_scale, brick_v,,,,, layer_autoexplode)
                  End If
                End If
                brick_pen_x += brick_spacing_x 'move coords to the right
              Next x
              brick_pen_x = .field_x1 + brick_spacing_x * .5 'reset coords to the left
              brick_pen_y += brick_spacing_y 'move coords down
            Next y
          End If
        end with
      Case "ITEM"
        'bonus gravity size -> item gravity size -> other item size
        
        If arg_total = 3 Or arg_total = 4 Then
          t1 = 0
          If arg_total = 4 Then t1 = Val(arg(4)) Else t1 = 0
          
          with brick
            brick_spacing_x = (.field_x2 - .field_x1) / brick_total_x
            brick_pen_x = .field_x1 - brick_spacing_x * .5
            brick_pen_x += Val(arg(1)) * brick_spacing_x
            
            brick_spacing_y = brick_spacing_x * .graphic.brick_sy / .graphic.brick_sx
            brick_pen_y = .field_y1 - brick_spacing_y * .5
            brick_pen_y += Val(arg(2)) * brick_spacing_y
          end with
          
          with item
            Select Case lcase(arg(3))
            Case "bonusbutton"
              .add(item_enum.bonusbutton, brick_pen_x, brick_pen_y, brick_scale, t1)
            Case "brickmachine"
              .add(item_enum.brickmachine, brick_pen_x, brick_pen_y, brick_scale, t1)
            Case "portal"
              .add(item_enum.portal, brick_pen_x, brick_pen_y, brick_scale, t1)
            Case "portal_out"
              .add(item_enum.portal_out, brick_pen_x, brick_pen_y, brick_scale, t1)
            Case "gravity"
              brick_s = t1
              brickscaling()
              brick_s *= brick_scale * gravity.scalefactor_item
              gravity.add(brick_pen_x, brick_pen_y, brick_s)
            End Select
          end with
        End If
      Case "MINSCORE"
        If arg_total = 1 Then .requiredscore = Val(arg(1))
      Case "MOUSEGRAVITY"
        If arg_total = 1 Then
          brick_s = val(arg(1)) * gravity.scalefactor_item
          brick_s *= screen.default_sx / 12 / brick.graphic.brick_sx 'default brick_scale factor
          gravity.add(screen.default_sx * .5, screen.default_sy * .5, _
            brick_s, gravity_enum.mouse)
        End If
      Case "PADDLESIZE"
        If arg_total = 1 Then
          With paddle
            .data_scale_original = Val(arg(1)) * .scale_factor / ..setting.players
            .set_scale(.data_scale_original)
          End With
        End If
      Case "PADDLESIDES"
        If arg_total >= 1 And arg_total <= 5 Then
          With paddle
            For i As Integer = 1 To arg_total
              Select Case arg(i)
              Case "top"
                .quantities(paddle_side_enum.top) += 1
              Case "bottom"
                .quantities(paddle_side_enum.bottom) += 1
              Case "left"
                .quantities(paddle_side_enum.left) += 1
              Case "right"
                .quantities(paddle_side_enum.right) += 1
              Case "center"
                .quantities(paddle_side_enum.center) += 1
              End Select
            Next i
            'don't put bricks near the sides if the paddles are there
            brick.field_x1 = Sgn(.quantities(paddle_side_enum.left)) * screen.default_sx * .2
            brick.field_y1 = Sgn(.quantities(paddle_side_enum.top)) * screen.default_sy * .2
            brick.field_x2 = screen.default_sx - 1 - Sgn(.quantities(paddle_side_enum.right)) * screen.default_sx * .2
            brick.field_y2 = screen.default_sy - 1 - Sgn(.quantities(paddle_side_enum.bottom)) * screen.default_sy * .2
          End With
        End If
      Case "PADDLESTYLE"
        If arg_total = 1 Then
          Select Case arg(1)
          Case "normal"
            paddle.set_defaultstyle(paddle_enum.normal)
          Case "super"
            paddle.set_defaultstyle(paddle_enum.super)
          End Select
        End If
      Case "SPECIAL"
        If arg_total >= 1 And arg_total <= 3 Then
          For i As Integer = 1 To arg_total
            Select Case arg(i)
            Case "noballlose"
              .special_noballlose = true
            Case "nobrickwin"
              .special_nobrickwin = true
            Case "shooter"
              .special_shooter = true
            End Select
          Next i
        End If
      Case "TIMELIMIT"
        If arg_total = 1 Or arg_total = 2 Then
          .timelimit = Val(arg(1)) * fps * 60 '60 is seconds per minute
          If arg_total = 2 Then .timelimit += Val(arg(2)) * fps
          If .timelimit > timemax * fps Then .timelimit = timemax * fps
        End If
      Case "TIP"
        .tip = Mid(l, 5)
      Case "TIPLOSE"
        .tiplose = Mid(l, 9)
      Case "TIPWIN"
        .tipwin = Mid(l, 8)
      Case "VERSION"
        If arg_total = 1 Then version = Val(arg(1))
      End Select
    Wend
    Close #f
  End With
  
  If version < version_min Then menu.notify("Level Too Old (v" & version & ", supports >= v" & version_min & ")")
  If version >= version_max Then menu.notify("Level Too New (v" & version & ", supports < v" & version_max & ")")
  
  If Len(setting.tip) > 0 Then
    If ..setting.tips And mode.replayfile = 0 And mode.tslave = false Then
      setting.tip = utility.gettext(setting.tip, true)
    End If
  End If
  
  gfxchange()
  reset2()
End Sub

sub game_type.summary ()
  'called when a game is finished (quit, completed, etc)
  
  dim as integer timebonus
  Dim As menu_setting_type mainmenu
  
  data_isgameover = true 'in particular, used for not allowing score > required
  replay.recordframe() 'make sure last frame is always recorded, for determining when game is over
  
  #ifndef server_validator
  'split-second animation
  If video.isStarted Then video.finish()
  If ..setting.mouseclipping Then Setmouse(,,, 0)
  
  If result.instantrestart Then Exit Sub
  
  With ball.object(1)
    If ball.total = 0 Then
      ball.total = 1
      
      .style = ball_enum.normal
      .scale = 1
      .stuck = 0
      .instantrelease = false
      
      .killme = false
    End If
    
    If .scale < ball.scalemin * 2 Then .scale = ball.scalemin * 2
    
    While .scale < 3 * ball.scalemax
      framerate.move()
      .scale += ball.scalemax / 30
      If framerate.candisplay() Then display()
      
      'instant restart after game over
      If Inkey() = "r" Then
        If mode.instantrestart Then
          result.instantrestart = true
          Exit Sub
        End If
      End If
    Wend
  End With
  
  'save level preview
  if data_getpreview and frametotal >= fps \ 2 then utility.graphic.savepreview()
  #Endif
  
  If result.didforfeit Or mode.tslave Then Exit Sub
  
  'not shown for testing because you don't want the game to get stuck (it wouldn't focus when testing starts)
  If ..setting.tips And mode.replayfile = 0 Then
    If result.didwin Then
      If Len(setting.tipwin) > 0 Then
        setting.tipwin = utility.gettext(setting.tipwin, true)
      End If
    Else
      If Len(setting.tiplose) > 0 Then
        setting.tiplose = utility.gettext(setting.tiplose, true)
      End If
    End If
  End If
  
  timebonus = Int(timebonusmax * ((setting.timelimit - frametotal) / setting.timelimit) ^ timebonusexponent + .5)
  If timebonus < 0 Or result.didwin = false Then timebonus = 0
  result.scoregained = result.scoregained + timebonus
  
  'hardcore cheat / repeat
  If mode_hardcore And mode.instantrestart Then
    If result.scoregained <= main.levelpack.master_score(mode.level).score Then
      result.instantrestart = true
      Exit Sub
    End If
  End If
  
  'read-only stats menu; do not show on forfeit
  With mainmenu
    If result.didwin Then .title = "Level Complete" Else .title = "Level Lost"
    .option_total = 4
    
    .option(1) = "" 'updated by callback
    
    .option(2) = "Lives: " & Abs(result.livesgained - result.liveslost)
    If result.livesgained > result.liveslost Then
      .option(2) += " won"
    Else
      .option(2) += " lost"
    End If
    If (mode.lives + result.livesgained - result.liveslost) < 0 Then
      .option(2) += " (lost)"
    Else
      .option(2) += ", " & (mode.lives + result.livesgained - result.liveslost) & " remaining"
    End If
    
    .option(3) = get_time()
    'the one-second delay might make the time go beyond the time limit even if player won
    If frametotal - fps <= setting.timelimit Then
      If timebonus > 0 Then .option(3) += " (+" & timebonus & ")"
    Else
      .option(3) += " (lost)"
    End If
    
    If mode.replayfile = 0 Then
      If ..setting.autosave Then
        .option(4) = "(Replay auto-saved)"
      Else
        .option(4) = "(Click to save game)"
      End If
    Else
      .option(4) = "(Replay complete)"
    End If
    
    .readonly = true
    .screenshot_ison = false
    .callback = @menu_callback_postgame()
  End With
  
  result.savegame = (menu.show(mainmenu) = 4 And ..setting.autosave = false)
end sub

Sub game_replay_type.reset ()
  'called when game is being set; after data_game is set
  
  Randomize()
  
  If game.mode.replayfile = 0 Then
    'going to save recording
    
    With header
      .submitted = false
      .player = ""
      .timestamp = Date() + Time()
      
      .levelpack = main.levelpack.title
      .levelnumber = game.mode.level
      
      .seed = Rnd() * 10000
      'score set at end of game
      
      'pull some settings from data_game
      .lives = game.mode.lives
      .orbtokens = game.mode.orbtokens
      .players = setting.players
      .speed = game.mode.speed
      
      .frame_total = 0
    End With
  Else
    'load from file, then replay
    'note: the levelpack and levelnumber don't matter here
    
    Dim As Integer f
    
    'mode.replayfile = true
    frame_current = 0 'if frame(frame_current).delay = frame_total then load state: frame_current ++
    
    'load replay from file
    If game.mode.replayfile = -1 Then
      Dim As String temp = Trim(Command(2))
      If Right(temp, 4) <> ".ubr" Then temp += ".ubr"
      f = utility.openfile(temp, utility_file_mode_enum.for_binary)
    Else
      f = utility.openfile("data/levelpacks/" & main.levelpack.title & "/recordings/" & _
        game.mode.level & "/" & game.mode.replayfile & ".ubr", utility_file_mode_enum.for_binary)
    End If
    Get #f, 1, header
    
    For i As Integer = 1 To header.frame_total
      Get #f, Sizeof(game_replay_header_type) + (i - 1) * Sizeof(game_replay_frame_type) + 1, frame(i)
    Next i
    Close #f
    
    'put some settings into data_game
    With header
      game.mode.lives = .lives
      game.mode.orbtokens = .orbtokens
      setting.players = .players
      game.mode.speed = .speed
    End With
  End If
  
  Randomize(header.seed)
End Sub

Sub game_replay_type.recordframe ()
  'save one frame to memory
  
  If header.frame_total + 2 > frame_max Then Exit Sub
  
  If setting.players = 1 Then
    If game.data_isgameover orelse _
      (header.frame_total = 0 orelse frame(header.frame_total).equals(game.control(1)) = false) Then
      header.frame_total += 1
      frame(header.frame_total).set(game.frametotal, game.control(1))
    End If
  Else
    If game.data_isgameover orelse _
      (header.frame_total = 0 orelse _
      frame(header.frame_total - 1).equals(game.control(1)) = false orelse _
      frame(header.frame_total).equals(game.control(2)) = false) Then
      
      header.frame_total += 2
      frame(header.frame_total - 1).set(game.frametotal, game.control(1))
      frame(header.frame_total).set(game.frametotal, game.control(2))
    End If
  End If
End Sub

Sub game_replay_type.save ()
  'save replay
  
  Dim As Integer f, temp
  dim as string levelpackrecordingspath = "data/levelpacks/" & main.levelpack.title & "/recordings/"
  Dim As String totalfile = levelpackrecordingspath & game.mode.level & "/total.txt"
  
  'get player name
  header.player = Left(main.player.lastplayer & Space(16), 16)
  header.score = game.result.scoregained
  
  'create replay folder and total.txt for level, add level to list (if needed)
  f = utility.openfile(totalfile, utility_file_mode_enum.for_input, true)
  If f = false Then
    'this is the first recording for this level, so add it to the list of levels that have recordings
    Dim As Integer numbers(1 To menu_setting_type.option_max), number_total, didaddnumber
    
    f = utility.openfile(levelpackrecordingspath & "list.txt", utility_file_mode_enum.for_input)
    While Eof(f) = false
      number_total += 1
      Input #f, numbers(number_total)
    Wend
    Close #f

    f = utility.openfile(levelpackrecordingspath & "list.txt", utility_file_mode_enum.for_output)
    If number_total = 0 Then
      Print #f, game.mode.level
    Else
      For i As Integer = 1 To number_total
        If game.mode.level < numbers(i) And didaddnumber = false Then Print #f, game.mode.level: didaddnumber = true
        Print #f, numbers(i)
      Next i
      If didaddnumber = false Then Print #f, game.mode.level
    End If
    Close #f
    
    Mkdir(levelpackrecordingspath & game.mode.level)
    f = utility.openfile(totalfile, utility_file_mode_enum.for_output)
    Print #f, 1
    Close #f
    temp = 1 'replay number (for filename)
  Else
    Close #f
    
    f = utility.openfile(totalfile, utility_file_mode_enum.for_input)
    Input #f, temp
    Close #f
    temp += 1
    
    f = utility.openfile(totalfile, utility_file_mode_enum.for_output)
    Print #f, temp
    Close #f
  End If
  
  'save file
  With game.replay
    .header.hash()
    f = utility.openfile(levelpackrecordingspath & _
      game.mode.level & "/" & temp & ".ubr", utility_file_mode_enum.for_binary)
    Put #f, 1, .header
    For i As Integer = 1 To .header.frame_total
      Put #f, Sizeof(game_replay_header_type) + (i - 1) * Sizeof(game_replay_frame_type) + 1, .frame(i)
    Next i
    Close #f
    
    server.addrecording(levelpackrecordingspath & game.mode.level & "/" & temp & ".ubr")
  End With
End Sub

Function game_replay_frame_type.equals (Byref c As game_control_type) As Integer
  Return x = c.x And y = c.y And b = c.click
End Function

Sub game_replay_frame_type.set (Byval frame As Integer, Byref c As game_control_type)
  delay = frame And &HFFFF 'ushort -> integer conversion
  x = c.x
  y = c.y
  b = c.click
End Sub

Function game_replay_frame_type.to_controlstate () As game_control_type
  Return Type(x, y, b)
End Function

Function game_replay_header_type.checkhash () As Integer
  Dim As Integer h1 = hash1, h2 = hash2, result
  
  'recalculate hash to test it
  hash()
  result = ((h1 = hash1) And (h2 = hash2))
  hash1 = h1
  hash2 = h2
  
  Return result
End Function

Sub game_replay_header_type.hash ()
  'hash1 based on player name, score, seed
  'hash2 based on orbtokens, players, speed, lives, levelnumber
  'the formula here is arbitrary and independent of the other code
  
  Dim As Integer d1
  
  d1 = 0
  For i As Integer = 0 To Len(Trim(player)) - 1
    d1 += player[i] Shl i
  Next i
  hash1 = ((d1 Xor score) + Len(Trim(player))) Xor (*(cast(Integer Ptr, @seed) + 1))
  
  d1 = orbtokens * 7 + players * 11 + lives * 23 + levelnumber * 43
  hash2 = d1 Xor Cint(speed * 100000)
End Sub

property game_result_type.scoregained () As Integer
  Return _scoregained
End property

property game_result_type.scoregained (Byval newscore As Integer)
  If game.data_isgameover = false And newscore > game.setting.requiredscore Then newscore = game.setting.requiredscore
  _scoregained = newscore
  
  If game.data_masterdone Then Exit property
  scoregained_master = _scoregained
End property

Sub game_text_type.reset ()
  #ifndef server_validator
  selected = game_text_enum.leveltitle
  changedelay = game.fps * 3 'only show level title 3 seconds
  
  For i As Integer = 1 To game_text_enum.max
    With text(i)
      .ison = (i = selected)
      .text = ""
      .x = 0
      If .ison Then
        .x = -Cdbl(utility.font.abf.gettextwidth(utility.font.font_pt_selected, _
          game.get_levelname()))
        .x /= screen.scale
      End If
    End With
  Next i
  #Endif
End Sub

Sub game_text_type.move ()
  #ifndef server_validator
  Dim As Integer paddle_shield_total, orb_power, ok
  Dim As game_text_enum s
  
  If game.framerate.loop_total < 2 * game.fps Then Exit Sub
  
  paddle_shield_total = paddle.lives_max
  For i As Integer = 1 To paddle.total
    If paddle.object(i).lives < paddle_shield_total Then paddle_shield_total = paddle.object(i).lives
  Next i
  
  orb_power = 0
  for i as integer = 1 to orb.total
    if orb.object(i).lives > orb_power then orb_power = orb.object(i).lives
  next i
  
  'set the texts
  text(game_text_enum.leveltitle).text = game.get_levelname()
  text(game_text_enum.orblife).text = "Power: " & utility.percentage(orb_power / orb.lives_max)
  text(game_text_enum.lives).text = "Lives: " & (game.mode.lives + game.result.livesgained - game.result.liveslost)
  text(game_text_enum.timeleft).text = "Time left: " & utility.formattime(game.setting.timelimit - game.frametotal)
  text(game_text_enum.shields).text = "Shields: " & utility.percentage(paddle_shield_total / paddle.lives_max)
  text(game_text_enum.bonus).text = "Bonus: " & game.tracker_bonustitle
  text(game_text_enum.score).text = game.get_score()
  
  'which text to display
  s = selected
  If game.frametotal - game.tracker_lifelost <= 1 Then '5 * fps then
    s = game_text_enum.lives
    changedelay = game.fps * 5
  Elseif game.frametotal - game.tracker_bonuscollect <= 1 Then
    'show bonus for five seconds; or if a bonus is already shown, only show for 2 seconds
    s = game_text_enum.bonus
    If selected = game_text_enum.bonus Then
      If changedelay < game.fps * 2 Then changedelay = game.fps * 2
    Else
      changedelay = game.fps * 5
    End If
  Else
    changedelay -= 1
    If changedelay = 0 Then
      changedelay = game.fps * 5
      s = selected
      Do
        s += 1 'enum iterations
        If s > game_text_enum.max Then s = 1
        
        Select Case s
        Case game_text_enum.leveltitle
          ok = false 'shown only at beginning
        Case game_text_enum.orblife
          ok = (orb.total >= 1)
        Case game_text_enum.lives
          ok = false 'not set here
        Case game_text_enum.timeleft
          ok = (game.setting.timelimit - game.frametotal < 120 * game.fps)
        Case game_text_enum.shields
          ok = (paddle.total >= 1 And enemy.total >= 1 And paddle.lives_max >= paddle_shield_total * 2)
        Case game_text_enum.bonus
          ok = false 'not set here
        Case game_text_enum.score
          ok = true 'main / default
        End Select
      Loop Until ok
    End If
  End If
  
  'turn new text on
  If s <> selected Then
    selected = s 
    With text(selected)
      .ison = true
      .x = -Cdbl(utility.font.abf.gettextwidth(utility.font.font_pt_selected, .text))
      .x /= screen.scale
    End With
  End If
  
  For i As Integer = 1 To game_text_enum.max
    With text(i)
      If .ison Then
        If i = selected Then
          .xt = (screen.default_sx - utility.font.abf.gettextwidth(_
            utility.font.font_pt_selected, .text) / screen.scale) * .5
        Else
          .xt = screen.default_sx * 1.01
        End If
        
        .x += (.xt - .x) * .03
        If .x > screen.default_sx Then .ison = false
      End If
    End With
  Next i
  #Endif
End Sub

Sub game_text_type.display ()
  #ifndef server_validator
  Static As utility_font_setting_type fontstyle
  
  If game.framerate.loop_total < 2 * game.fps Then Exit Sub
  
  fontstyle.c = &H88000000
  fontstyle.c_back = &H66FFFFFF
  
  For i As Integer = 1 To game_text_enum.max
    With text(i)
      If .ison and .x <= screen.default_sx Then
        utility.font.show(.text, .x + xfx.camshake.x, xfx.camshake.y, fontstyle)
      End If
    End With
  Next i
  #Endif
End Sub
