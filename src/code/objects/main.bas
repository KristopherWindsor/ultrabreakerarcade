
Sub main_type.run ()
  Const intro_length = 1
  const welcomecommand = !"OPEN http://ultrabreaker.com/forum/index.php?topic=16\nEND"
  
  Dim As Integer intro_fontwidth, quit
  Dim As Double intro_angle, intro_distance, intro_scale
  Dim As String credits(1 To 9) = _
    {"Ultrabreaker " & ultrabreaker_version_major & "." & ultrabreaker_version_minor, _
    "", _
    "Special thanks to", _
    "Kristopher Windsor - lead developer", _
    "Anders Dator Felix Dator - music", _
    "Aki Nordman - music", _
    "The FreeBasic community - support & libraries", _
    "", _
    "See the Readme for details"}
  Dim As menu_setting_type mainmenu
  Dim As utility_framerate_type framerate
  
  'initialize
  start()
  
  'show intro
  intro_distance = screen.default_sx
  framerate.reset()
  
  #ifndef server_validator
  For i As Integer = 20 To 255 Step 20
    framerate.move()
    
    If framerate.candisplay() Then
      Line (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), Rgb(i, i, i), BF
    End If
  Next i
  
  Do
    framerate.move
    intro_angle = ((framerate.t - framerate.t_start) - intro_length) * pi * 2
    intro_distance *= .95
    intro_scale = (framerate.t - framerate.t_start) / intro_length
    
    If framerate.candisplay Then
      Screenlock
      Line (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), color_enum.white, BF
      multiput(, screen.scale_x(menu.bigball_x + intro_distance), _
        screen.scale_y(menu.bigball_y), _
        utility.graphic.ball, screen.scale * intro_scale * (19 * dsfactor / 6),, intro_angle)
      Screenunlock
    End If
  Loop Until framerate.t - framerate.t_start > intro_length
  
  If setting.areyounotnew = false Then
    setting.areyounotnew = true
    sound.speak("welcome to ultrabreaker!")
    player.selectname()
  End If
  #Endif
  
  If Ucase(Command(1)) = "VALIDATE" Then
    validate()
  Else
    #ifndef server_validator
    If Ucase(Command(1)) = "TEST" Then test()
    
    'show the main menu: play, settings, test, quit
    Do
      With mainmenu
        .title = "UltraBreaker"
        .disablecancel = true
        Select Case setting.unlockedmode
        Case setting_featurelock_enum.unlocked
          .option_total = 6
          .option(1) = "Play!"
          .option(2) = "Profile"
          .option(3) = "Gallery"
          .option(4) = "Settings"
          .option(5) = "Editor"
          .option(6) = "Quit"
        Case setting_featurelock_enum.progressing
          .option_total = 5
          .option(1) = "Play!"
          .option(2) = "Profile"
          .option(3) = "Gallery"
          .option(4) = "Settings"
          .option(5) = "Quit"
        Case setting_featurelock_enum.locked
          .option_total = 4
          .option(1) = "Play!"
          .option(2) = "Profile"
          .option(3) = "Settings"
          .option(4) = "Quit"
        End Select
        .xoption = .option_total
      End With
      
      Select Case mainmenu.option(menu.show(mainmenu))
      Case "Play!"
        selectlevelpack()
      case "Profile"
        main.player.selectname()
      Case "Gallery"
        gallery()
      Case "Settings"
        settings()
      Case "Editor"
        test()
      Case "Quit"
        quit = true
      End Select
    Loop Until quit
    
    'show closing (with credits)
    framerate.reset()
    Do
      framerate.move()
      intro_angle = ((framerate.t - framerate.t_start) - intro_length) * pi * 2
      intro_distance /= .95
      intro_scale = 1 - (framerate.t - framerate.t_start) / intro_length
      
      If framerate.candisplay() Then
        Screenlock()
        Line (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), color_enum.white, BF
        For i As Integer = 1 To Ubound(credits)
          intro_fontwidth = utility.font.abf.gettextwidth(utility.font.font_pt_selected, credits(i)) / screen.scale
          utility.font.show(credits(i), (screen.default_sx - intro_fontwidth) Shr 1, _
            utility.font.fontheight * utility.font.fontspacing * i, utility.font.setting_default)
        Next i
        multiput(, screen.scale_x(menu.bigball_x + intro_distance), _
          screen.scale_y(menu.bigball_y), _
          utility.graphic.ball, screen.scale * intro_scale * (19 * dsfactor / 6),, intro_angle)
        Screenunlock()
      End If
    Loop Until framerate.t - framerate.t_start >  intro_length
    #Endif
  End If
  
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

Sub main_type.gallery ()
  #ifndef server_validator
  
  #define midx (screen.screen_sx / 2)
  #define midy (screen.screen_sy / 2)
  
  Const mosaic_scale = 4
  
  Dim As Integer f, deleted, loaded, loaded_anim, quit, tx, ty
  Dim As Integer screenshot_total, screenshot_root
  Dim As Integer screenshot_x, screenshot_y, thumb_x, thumb_y
  Dim As Integer selected, selected_previous
  Dim As Integer target_x, target_y
  Dim As Double ts, hover_scale, zoom_x, zoom_y
  Dim As String key, info, thefilename
  
  Dim As fb.image Ptr mosaic, mosaic_screen, screenshot
  
  Dim As utility_font_setting_type font
  Dim As utility_framerate_type framerate
  Dim As menu_setting_type shotmenu
  
  f = utility.openfile("data/screenshot.txt", utility_file_mode_enum.for_input)
  Input #f, screenshot_total
  Close #f
  
  If screenshot_total <= 0 Then
    menu.notify("No Screenshots Saved Yet")
    Exit Sub
  End If
  
  Dim As String captions(1 To screenshot_total)
  Dim As fb.image Ptr thumb(0 To screenshot_total)
  
  selected = -1
  selected_previous = -1
  screenshot_root = Int(Sqr(screenshot_total) + 1)
  font.c_back = &H66FFFFFF
  
  'mosaic screen
  mosaic_screen = utility.createimage(screen.screen_sx, screen.screen_sy mop("gallery mosaic screen"), color_enum.black)
  multiput(mosaic_screen, midx, midy, utility.graphic.menu, screen.screen_sx / (utility.graphic.menu -> Width))
  
  'fade out menu
  framerate.reset()
  For i As Integer = 1 To 60
    framerate.move()
    
    If framerate.candisplay() Then
      Screenlock()
      Put (0, 0), mosaic_screen, alpha, 10 + i '* 3
      Screenunlock()
    End If
  Next i
  
  'mosaic
  mosaic = utility.createimage(screen.screen_sx * mosaic_scale, screen.screen_sy * mosaic_scale mop("gallery mosaic"), color_enum.black)
  multiput(mosaic, (mosaic -> Width) Shr 1, (mosaic -> height) Shr 1, utility.graphic.menu, screen.screen_sx * mosaic_scale / (utility.graphic.menu -> Width))
  
  'menu thumb -> to mosaic
  thumb(0) = utility.graphic.menu
  tx = .5 * (mosaic -> Width) / screenshot_root
  ty = .5 * (mosaic -> height) / screenshot_root
  ts = (mosaic -> Width) / (thumb(0) -> Width)
  If ts > (mosaic -> height) / (thumb(0) -> height) Then
    ts = (mosaic -> height) / (thumb(0) -> height)
  End If
  ts /= screenshot_root
  multiput(mosaic, tx, ty, thumb(0), ts)
  
  'load captions
  f = utility.openfile("data/screenshot-captions.txt", utility_file_mode_enum.for_input)
  For i As Integer = 1 To screenshot_total
    If Eof(f) Then Exit For
    Line Input #f, captions(i)
  Next i
  Close #f
  
  framerate.reset()
  Do
    framerate.move()
    sound.move()
    
    utility.mouse.update()
    key = Inkey()
    
    'select a picture on hover
    If loaded > 0 Then
      selected_previous = selected
      With utility.mouse
        If .c.x <> .p.x Or .c.y <> .p.y Then
          tx = Int(screenshot_root * .c.x / screen.screen_sx)
          ty = Int(screenshot_root * .c.y / screen.screen_sy)
        Else
          If selected < 0 Then
            tx = -1
            ty = 0
          Else
            tx = selected Mod screenshot_root
            ty = Int(selected / screenshot_root)
          End If
          
          Select Case key
          Case Chr(255, 72)
            If ty > 0 Then ty -= 1
          Case Chr(255, 80)
            If ty < screenshot_root - 1 Then ty += 1
          Case Chr(255, 75)
            If tx > 0 Then tx -= 1
          Case Chr(255, 77)
            If tx < screenshot_root - 1 Then tx += 1
          Case Chr(27)
            quit = true
          End Select
          If utility.quitprogram(key, @framerate) Then quit = true
        End If
        selected = tx + ty * screenshot_root
        If loaded = screenshot_total Then
          If selected > screenshot_total - deleted Then selected = -1
        Else
          If selected > Int(loaded / screenshot_root) * screenshot_root Then selected = -1
        End If
      End With
      
      'reset thumb zooming
      If selected <> selected_previous Then
        hover_scale = 1
        If selected <= 0 Then info = "Return to menu" Else info = "#" & selected & ": " & captions(selected)
      End If
      
      If hover_scale < 2 Then hover_scale *= 1.05
    End If
    
    'view a screenshot
    If selected >= 0 And (key = " " Or (utility.mouse.c.b > 0 And utility.mouse.p.b = 0)) And utility.quitprogram() = false Then
      'fade out for hover
      For i As Integer = 250 To 10 Step -12
        If framerate.candisplay() Then
          Screenlock()
          Put (0, 0), mosaic_screen, Pset
          tx = ((selected Mod screenshot_root) + .5) * screen.screen_sx / screenshot_root
          ty = (Int(selected / screenshot_root) + .5) * screen.screen_sy / screenshot_root
          ts = screen.screen_sx / ((thumb(selected) -> Width) * screenshot_root)
          If ts > screen.screen_sy / ((thumb(selected) -> height) * screenshot_root) Then
            ts = screen.screen_sy / ((thumb(selected) -> height) * screenshot_root)
          End If
          multiput(, tx, ty, thumb(selected), hover_scale * ts,,, i)
          Screenunlock()
        End If
        
        framerate.move()
        sound.move()
      Next i
      
      'load screenshot for zoomed-in viewing
      if selected > 0 then
        thefilename = "screenshots/" & selected
        f = utility.openfile(thefilename & ".png", utility_file_mode_enum.for_input)
        if f > 0 then
          close #f
          png_getsize(thefilename & ".png", screenshot_x, screenshot_y)
          
          If screenshot_x = 0 Then screenshot_x = gallery_thumb_sx
          If screenshot_y = 0 Then screenshot_y = gallery_thumb_sy
          
          screenshot = utility.createimage(screenshot_x, screenshot_y mop("gallery screenshot"), color_enum.black)
          utility.loadimage("../../" & thefilename, screenshot)
          framerate.fixtimeout()
        else
          screenshot = utility.createimage(gallery_thumb_sx, gallery_thumb_sy mop("gallery screenshot"), color_enum.black)
        end if
      end if
      
      'zooming in
      tx = selected Mod screenshot_root
      ty = Int(selected / screenshot_root)
      target_x = (tx + .5) * screen.screen_sx / screenshot_root
      target_y = (ty + .5) * screen.screen_sy / screenshot_root
      
      For scale As Double = 1 / mosaic_scale To (screenshot_root + .05) / mosaic_scale Step .12 / mosaic_scale
        'move display coords
        zoom_x = midx + (midx - target_x) * ((scale - 1 / mosaic_scale) / (screenshot_root - 1))
        zoom_y = midy + (midy - target_y) * ((scale - 1 / mosaic_scale) / (screenshot_root - 1))
        'more statements needed to move places for scale
        zoom_x = midx + (zoom_x - midx) * scale * mosaic_scale * mosaic_scale
        zoom_y = midy + (zoom_y - midy) * scale * mosaic_scale * mosaic_scale

        If framerate.candisplay() Then
          Screenlock()
          multiput(, zoom_x, zoom_y, mosaic, scale)
          Screenunlock()
        End If
        
        framerate.move()
        sound.move()
      Next scale
      
      If selected = 0 Then
        quit = true
      Else
        'show full screenshot and wait for keypress (doesn't keep normal framerate but whatever)
        ts = screen.screen_sx / (screenshot -> Width)
        If ts > screen.screen_sy / (screenshot -> height) Then ts = screen.screen_sy / (screenshot -> height)
        Do
          utility.mouse.update()
          sound.move()
          
          Screenlock()
          multiput(, midx, midy, screenshot, ts)
          Screenunlock()
          
          Sleep(50, 1)
          key = Inkey()
          If utility.quitprogram(key) Then quit = true
        Loop Until key = " " Or key = Chr(27) Or quit Or (utility.mouse.c.b > 0 And utility.mouse.p.b = 0)
        utility.deleteimage(screenshot mop("gallery screenshot"))
        
        'menu for this screenshot
        If key = Chr(27) And loaded = screenshot_total Then 'can't delete while loading because loaded would give errors
          Get (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), utility.graphic.screenshot
          With shotmenu
            .title = "#" & selected & ": " & captions(selected)
            .option_total = 2
            .screenshot_ison = true
            .screenshot_disable_intro = true 'gallery has enough zooming already
            .option(1) = "Change caption"
            .option(2) = "Delete screenshot"
          End With
          Select Case menu.show(shotmenu)
          Case 1
            captions(selected) = utility.gettext(captions(selected))
          Case 2
            deleted += 1
            Kill("screenshots/" & selected & ".png")
            Kill("screenshots/thumbs/" & selected & ".png")
            For i As Integer = selected To screenshot_total - 1
              Name("screenshots/" & (i + 1) & ".png", "screenshots/" & i & ".png")
              Name("screenshots/thumbs/" & (i + 1) & ".png", "screenshots/thumbs/" & i & ".png")
              captions(i) = captions(i + 1)
            Next i
          End Select
        End If
        framerate.fixtimeout()
        
        'zoom out
        If utility.quitprogram() = false Then
          For scale As Double = (screenshot_root + .05) / mosaic_scale To 1 / mosaic_scale Step -.12 / mosaic_scale
            'move display coords
            zoom_x = midx + (midx - target_x) * ((scale - 1 / mosaic_scale) / (screenshot_root - 1))
            zoom_y = midy + (midy - target_y) * ((scale - 1 / mosaic_scale) / (screenshot_root - 1))
            'more statements needed to move places for scale
            zoom_x = midx + (zoom_x - midx) * scale * mosaic_scale * mosaic_scale
            zoom_y = midy + (zoom_y - midy) * scale * mosaic_scale * mosaic_scale
    
            If framerate.candisplay() Then
              Screenlock()
              multiput(, zoom_x, zoom_y, mosaic, scale)
              Screenunlock()
            End If
            
            framerate.move()
            sound.move()
          Next scale
        End If
      End If
    End If
    
    'load screenshots (thumb only, unless thumb is missing)
    If loaded < screenshot_total And framerate.loop_total Mod 2 = 0 Then
      loaded += 1
      
      thefilename = "screenshots/thumbs/" & loaded
      f = utility.openfile(thefilename & ".png", utility_file_mode_enum.for_input)
      If f = false Then
        'load screenshot and save as thumb, since it is missing
        var thefilename2 = "screenshots/" & loaded
        
        f = utility.openfile(thefilename2 & ".png", utility_file_mode_enum.for_input)
        if f = 0 then
          'no original image for making the thumbnail
          thumb(loaded) = utility.createimage(gallery_thumb_sx, gallery_thumb_sy mop("gallery thumb"), color_enum.black)
        else
          close #f
          png_getsize(thefilename2 & ".png", screenshot_x, screenshot_y)
        
          If screenshot_x = 0 Then screenshot_x = gallery_thumb_sx
          If screenshot_y = 0 Then screenshot_y = gallery_thumb_sy
          
          thumb_x = gallery_thumb_sy * screenshot_x / screenshot_y
          thumb_y = gallery_thumb_sy
          
          screenshot = utility.createimage(screenshot_x, screenshot_y mop("gallery screenshot"), color_enum.black)
          utility.loadimage("../../" & thefilename2, screenshot)
          
          thumb(loaded) = utility.createimage(thumb_x, thumb_y mop("gallery thumb"))
          image_scaler(thumb(loaded), 0, 0, screenshot, gallery_thumb_sy / screenshot_y)
          
          png_save24(thefilename & ".png", thumb(loaded))
          utility.deleteimage(screenshot mop("gallery screenshot"))
        end if
      Else
        Close #f
        
        png_getsize(thefilename & ".png", thumb_x, thumb_y)
        thumb(loaded) = utility.createimage(thumb_x, thumb_y mop("gallery thumb"))
        utility.loadimage("../../" & thefilename, thumb(loaded))
      End If
      
      'save a screenshot onto the mosaic
      tx = ((loaded Mod screenshot_root) + .5) * (mosaic -> Width) / screenshot_root
      ty = (Int(loaded / screenshot_root) + .5) * (mosaic -> height) / screenshot_root
      ts = (mosaic -> Width) / (thumb_x * screenshot_root)
      If ts > (mosaic -> height) / (thumb_y * screenshot_root) Then ts = (mosaic -> height) / (thumb_y * screenshot_root)
      
      multiput(mosaic, tx, ty, thumb(loaded), ts)
      multiput(mosaic_screen, midx, midy, mosaic, 1 / mosaic_scale) 'copy whole mosaic to smaller pic
      framerate.fixtimeout()
    End If
    
    If framerate.candisplay() And quit = false Then
      Screenlock()
      Put (0, 0), mosaic_screen, Pset
      If selected >= 0 Then
        tx = ((selected Mod screenshot_root) + .5) * screen.screen_sx / screenshot_root
        ty = (Int(selected / screenshot_root) + .5) * screen.screen_sy / screenshot_root
        ts = screen.screen_sx / ((thumb(selected) -> Width) * screenshot_root)
        If ts > screen.screen_sy / ((thumb(selected) -> height) * screenshot_root) Then
          ts = screen.screen_sy / ((thumb(selected) -> height) * screenshot_root)
        End If
        multiput(, tx, ty, thumb(selected), hover_scale * ts)
        
        tx = utility.mouse.c.sx
        ty = utility.mouse.c.sy
        ts = utility.font.abf.gettextwidth(utility.font.font_pt_selected, info) / screen.scale
        If tx + ts > screen.default_sx Then tx = screen.default_sx - ts
        ts = utility.font.abf.gettextheight(utility.font.font_pt_selected) / screen.scale
        If ty + ts > screen.default_sy Then ty = screen.default_sy - ts
        
        utility.font.show(info, tx, ty, font)
      End If
      Screenunlock()
    End If
  Loop Until quit
  
  If deleted > 0 Then
    f = utility.openfile("data/screenshot.txt", utility_file_mode_enum.for_output)
    Print #f, screenshot_total - deleted 'subtract menu icon + delete total
    Close #f
  End If
  
  'save captions (append whitespace if lines missing, change captions, adjust for removed photos)
  f = utility.openfile("data/screenshot-captions.txt", utility_file_mode_enum.for_output)
  For i As Integer = 1 To screenshot_total
    Print #f, captions(i)
  Next i
  Close #f
  
  'if selected_previous > 0 then utility.deleteimage(hover mop("gallery hover"))
  utility.deleteimage(mosaic mop("gallery mosaic"))
  utility.deleteimage(mosaic_screen mop("gallery mosaic screen"))
  
  For i As Integer = 1 To loaded
    utility.deleteimage(thumb(i) mop("gallery thumb"))
  Next i
  #Endif
End Sub

Sub main_type.highscore ()
  'show the high scores for a levelpack
  
  Dim As menu_setting_type mainmenu
  
  With mainmenu
    .title = "Highscores: " & levelpack.showname
    .readonly = true
    
    .option_total = 1
    .option(1) = "-- Arcade --"
    
    For i As Integer = 1 To levelpack.scorespermode
      With levelpack.arcade_score(i)
        If .score > 0 Then
          mainmenu.option_total += 1
          mainmenu.option(mainmenu.option_total) = .score & " " & .player & " (#" & .level & ")"
        End If
      End With
    Next i
    
    .option_total += 2
    .option(.option_total) = "-- Master --"
    
    For i As Integer = 1 To levelpack.level_total
      With levelpack.master_score(i)
        If .score > 0 Then
          mainmenu.option_total += 1
          mainmenu.option(mainmenu.option_total) = .score & " " & .player & " (" & levelpack.level(i) & ")"
        End If
      End With
    Next i
    
    .option_total += 2
    .option(.option_total) = "-- Mission --"
    
    For i As Integer = 1 To levelpack.scorespermode
      With levelpack.mission_score(i)
        If .score > 0 Then
          mainmenu.option_total += 1
          mainmenu.option(mainmenu.option_total) = .score & " " & .player
        End If
      End With
    Next i
  End With
  
  menu.show(mainmenu)
End Sub

Sub main_type.play ()
  'select a game mode, after a levelpack has been selected
  
  Dim As Integer e, f, expired, ranking, instaplay
  Dim As menu_setting_type mainmenu
  
  with levelpack.arcade_save
    If .level < 1 Or .lives < 0 or .score < 0 or _
      .orbtokens < 0 or .orbtokens > game.orbprice Then expired = true
  end with
  
  With levelpack
    If .level_total = 0 Then Exit Sub
    
    Do
      'arcade: this detects a bad game save, or the end of a game
      If expired Then
        expired = false
        
        'save high score
        If .arcade_save.score > .arcade_score(.scorespermode).score Then
          sound.speak("high score. epic win!")
          menu.notify("Arcade: High Score (" & .arcade_save.score & ")!")
          
          'shift lesser scores down the chart
          ranking = 1
          While .arcade_save.score <= .arcade_score(ranking).score
            ranking += 1
          Wend
          For i As Integer = .scorespermode To ranking + 1 Step -1
            .arcade_score(i) = .arcade_score(i - 1)
          Next i
          
          With .arcade_score(ranking)
            .player = player.lastplayer
            .level = levelpack.arcade_save.level + 1
            .score = levelpack.arcade_save.score
          End With
          
          highscore()
        End If
        
        'reset the progress variables
        With .arcade_save
          .level = 0
          .lives = arcadelives
          .score = 0
          .orbtokens = 0
        End With
      Else
        'if you quit before you did anything (giving you -1 lives and +0 points), start over
        'level = 0 <-> score = 0
        With .arcade_save
          If .level = 0 Then .lives = arcadelives
        End With
      End If
      
      mainmenu.title = .showname
      mainmenu.option_total = 4
      mainmenu.option(1) = "Arcade (round " & _
        Int(.arcade_save.level / .level_total + 1) & ", level " & _
        ((.arcade_save.level Mod .level_total) + 1) & ", " & _
        .arcade_save.lives & " lives, " & .arcade_save.score & " points)"
      mainmenu.option(2) = "Select Level"
      mainmenu.option(3) = "Highscores"
      mainmenu.option(4) = "Replays"
      mainmenu.callback = @menu_callback_play()
      
      if instaplay then
        instaplay = false
        mainmenu.returnvalue = 1
      else
        menu.show(mainmenu)
      end if
      Select Case mainmenu.returnvalue
      Case 1
        'play arcade mode
        'lost -> add arcade score
        'finished round one -> add mission score
        'beat the record for a certain level -> add master score
        With game.mode
          .level = (levelpack.arcade_save.level Mod levelpack.level_total) + 1
          .lives = levelpack.arcade_save.lives
          .speed = arcadespeedfactor ^ Int(levelpack.arcade_save.level / levelpack.level_total)
          .orbtokens = levelpack.arcade_save.orbtokens
          .tslave = false
          .replayfile = 0
          .instantrestart = false
        end with
        
        game.run()
        
        with game.result
          'unlock level
          If .didwin And .didcheat = false Then
            If game.mode.level > levelpack.unlockedtotal Then levelpack.unlockedtotal = game.mode.level
          End If
          
          'master score
          If .didcheat = false And _
            .scoregained_master > levelpack.master_score(game.mode.level).score Then
            
            'save high score
            sound.speak("high score. you mastered this level!") 'avoid notify(high score)
            
            With levelpack.master_score(game.mode.level)
              .player = player.lastplayer
              .score = game.result.scoregained_master
              .level = 0
            End With
            
            game.replay.save()
          Else
            If .savegame Or setting.autosave Then game.replay.save()
          End If
          
          'mission score
          If .didwin And .didcheat = false And _
            levelpack.arcade_save.level + 1 = levelpack.level_total Then
            
            var masterscore = levelpack.arcade_save.score + .scoregained
            
            If masterscore > levelpack.mission_score(levelpack.scorespermode).score Then
              sound.speak("high score. mission complete!")
              menu.notify("Mission: High Score (" & masterscore & ")!")
              
              With levelpack
                'shift lesser scores down the chart
                ranking = 1
                While masterscore <= .mission_score(ranking).score
                  ranking += 1
                Wend
                For i As Integer = .scorespermode To ranking + 1 Step -1
                  .mission_score(i) = .mission_score(i - 1)
                Next i
                
                With .mission_score(ranking)
                  .player = player.lastplayer
                  .score = masterscore
                  .level = 0
                End With
                
                'news: levelpack is now complete
                .list(.indexOf).iscompleted = true
              End With
              
              'unlock a levelpack (prolly nothing)
              'assumed that if you didn't get a highscore, you've beat master mode before
              levelpack.unlock()
            End If
          End If
          
          'arcade score
          'cheat or quit -> lose one life, no progress
          If .didcheat Or .didforfeit Then
            'lose a life, don't change anything else
            If levelpack.arcade_save.lives >= 0 Then levelpack.arcade_save.lives -= 1
          Else
            If .didwin Then
              'you win the level, but there is more to play (no notification needed)
              levelpack.arcade_save.level += 1
            Else
              'you lose x_X
              menu.notify("Arcade Mode Lost")
              expired = true
            End If
            
            levelpack.arcade_save.lives += .livesgained - .liveslost
            levelpack.arcade_save.score += .scoregained
            levelpack.arcade_save.orbtokens = .orbtokens
          End If
          
          If levelpack.arcade_save.lives < 0 Then expired = true
        End With
      Case 2
        playmaster()
      Case 3
        highscore()
      Case 4
        playreplay()
      End Select
    Loop Until mainmenu.returnvalue = false
  End With
End Sub

Sub main_type.playmaster ()
  'master mode: select a level, try to get a high score
  
  Dim As menu_setting_type mainmenu
  
  Do
    With mainmenu
      .title = "Master: " & levelpack.showname
      .option_total = levelpack.unlockedtotal
      If .option_total < levelpack.level_total Then .option_total += 1
      For i As Integer = 1 To .option_total
        .option(i) = "#" & i & " " & levelpack.level(i) & " (" & _
          levelpack.master_score(i).score & ")" 'player name looks messy here
      Next i
      .callback = @menu_callback_selectlevel()
    End With
    
    If menu.show(mainmenu) Then
      'play a level
      Do
        With game.mode
          .level = mainmenu.returnvalue
          .lives = 0
          .speed = 1
          .orbtokens = game.orbprice - 1
          .tslave = false
          .replayfile = 0
          .instantrestart = true
        end with
        
        game.run()
      Loop Until game.result.instantrestart = false
      
      with game.result
        'cheat -> no high score
        If .didcheat = false And _
          .scoregained_master > levelpack.master_score(game.mode.level).score Then
          
          sound.speak("high score. you mastered this level!")
          
          With levelpack.master_score(game.mode.level)
            .player = player.lastplayer
            .score = game.result.scoregained_master
            .level = 0
          End With
          
          game.replay.save()
        Else
          If .savegame Or setting.autosave Then game.replay.save()
        End If
      End With
    End If
  Loop Until mainmenu.returnvalue = false
End Sub

Sub main_type.playreplay ()
  'select level, select replay, replay it
  
  Dim As Integer f
  Dim As menu_setting_type mainmenu
  
  Do
    With mainmenu
      .title = "Replay: " & levelpack.showname
      
      .option_total = 0
      f = utility.openfile("data/levelpacks/" & levelpack.title & "/recordings/list.txt", utility_file_mode_enum.for_input)
      While Eof(f) = false
        var i = 0
        Input #f, i
        .option_total += 1
        .option(.option_total) = "#" & i & " " & levelpack.level(i)
      Wend
      Close #f
      
      .callback = @menu_callback_selectlevel()
    End With
    
    If menu.show(mainmenu) Then
      playreplay_selectrecording(Val(Mid(mainmenu.option(mainmenu.returnvalue), 2)))
    end if
  Loop Until mainmenu.returnvalue = false
End Sub

Sub main_type.playreplay_selectrecording (Byval levelnumber As Integer)
  
  Dim As Integer f, replaytotal, multiplayer
  Dim As game_replay_header_type header 'load this to get info from the replay files
  Dim As game_replay_frame_type lastframe
  Dim As menu_setting_type mainmenu
  
  multiplayer = setting.players
  
  f = utility.openfile("data/levelpacks/" & levelpack.title & "/recordings/" & levelnumber & "/total.txt", utility_file_mode_enum.for_input)
  Input #f, replaytotal
  Close #f
  
  With mainmenu
    .title = "Replay: " & levelpack.showname & ": " & levelpack.level(levelnumber)
    
    For i As Integer = 1 To replaytotal
      f = utility.openfile("data/levelpacks/" & levelpack.title & "/recordings/" & _
        levelnumber & "/" & i & ".ubr", utility_file_mode_enum.for_binary)
      Get #f, 1, header
      Get #f, Sizeof(game_replay_header_type) + (header.frame_total - 1) * Sizeof(game_replay_frame_type) + 1, lastframe
      Close #f
      With header
        mainmenu.option(i) = Trim(.player) & " (" & .score & ", " & utility.formattime(lastframe.delay) & ")"
      End With
    Next i
    .option_total = replaytotal
  End With
  
  Do
    If menu.show(mainmenu) Then
      With game.mode
        .level = levelnumber
        .tslave = false
        .replayfile = mainmenu.returnvalue
        .instantrestart = false
        '.mode_lives, .mode_speed, .mode_orbtokens are set by replay file
      End With
        
      game.run()
    End If
  Loop Until mainmenu.returnvalue = false
  
  setting.players = multiplayer
End Sub

Sub main_type.selectlevelpack ()
  'select a levelpack
  
  Dim As Integer selection, testIndex = 1E4
  Dim As menu_setting_type mainmenu
  
  levelpack.start() 'will load new LPs from leveler
  
  With mainmenu
    .title = "Select a Levelpack"
    
    Do
      'read LP list, but hide test pack
      .option_total = levelpack.list_total - 1
      if .option_total <= 0 then
        utility.logerror("No levelpacks! Is the Test pack in the list?")
        return
      end if
      
      For i As Integer = 1 To levelpack.list_total
        If levelpack.list(i).title = "Test" Then
          testIndex = i
        Else
          .option(i - Abs(testIndex < i)) = levelpack.list(i).showname
        End If
      Next i
      
      .scrolloffset = 0
      selection = menu.show(mainmenu)
      If selection >= testIndex Then selection += 1
      
      If selection > 0 Then
        'sort list; selected item goes to the top
        For i As Integer = selection - 1 To 1 Step -1
          Swap levelpack.list(i), levelpack.list(i + 1)
        Next i
        
        'user selects levelpack -> go to game mode selector
        levelpack.load(1)
        If levelpack.level_total < 1 Then
          menu.notify("Pack Has No Levels")
        Else
          play()
          levelpack.save()
        End If
      End If
    Loop Until selection = false 'user cancels => back to main menu
  End With
End Sub

Sub main_type.settings ()
  'this is the settings main menu; it links to other settings menus, such as setting and screen
  
  Dim As menu_setting_type mainmenu
  
  With mainmenu
    .title = "Settings"
    .option_total = 8
    .option(1) = "Controls"
    .option(2) = "Graphics"
    .option(3) = "Multiplayer"
    .option(4) = "Performance"
    .option(5) = "Recordings"
    .option(6) = "Screen size"
    .option(7) = "Tips"
    .option(8) = "Volume"
  End With
  
  Do
    Select Case menu.show(mainmenu)
    Case 1
      setting.set_controls()
    Case 2
      setting.set_graphics()
    Case 3
      setting.set_multiplayer()
    Case 4
      setting.set_performance()
    Case 5
      setting.set_recordings()
    Case 6
      screen.set()
    Case 7
      setting.set_tips()
    Case 8
      sound.set_volume()
    End Select
  Loop Until mainmenu.returnvalue = false
end sub

Sub main_type.test ()
  'spawn the level editor and show the test option
  'menu > test > loop
  #ifndef server_validator
  
  Dim As Integer letsplay
  Dim As menu_setting_type mainmenu
  
  With mainmenu
    .title = "Level Editing"
    .option_total = 2
    .option(1) = "Test play"
    .option(2) = "Start editor"
    .callback = @menu_callback_test()
  End With
  
  Do
    letsplay = false
    Select Case menu.show(mainmenu)
    Case 1, 10 'option 10 selected by callback
      letsplay = true
    Case 2
      Shell("start leveler.exe")
      Sleep(400, 1)
      SetForegroundWindow(FindWindow(NULL, "Leveler"))
    End Select
    
    If letsplay Then
      'special levelpack has one level, for testing
      
      Do
        levelpack.load("Test") 'saving not necessary; no changes made
        
        With game.mode
          .level = 1
          .lives = 100
          .speed = 1
          .orbtokens = game.orbprice - 1
          .tslave = (mainmenu.returnvalue = 10)
          .replayfile = 0
          .instantrestart = true
        End With
        
        SetForegroundWindow(screen.gamewindow)
        game.run()
      Loop Until game.result.instantrestart = false
    End If
  Loop Until mainmenu.returnvalue = false
  #Endif
End Sub

Sub main_type.validate ()
  
  #define terminate() Exit Sub
  #define badmessage(m) utility.consmessage(m): terminate()
  
  Const hexchars = "0123456789ABCDEF"
  Const validchars_base = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890-"
  Const validchars_extended = validchars_base & "()[] !?$,=+"
  
  Dim As Ubyte u
  Dim As Integer f, valid
  Dim As String file, errormessage, l
  Dim As game_replay_header_type header
  
  'get replay info
  
  file = Trim(Command(2))
  If Len(file) < 4 Then terminate()
  
  'convert a hex file to normal
  If Right(file, 4) <> ".ubr" Then
    f = utility.openfile(file, utility_file_mode_enum.for_input)
    Line Input #f, l
    Close #f
    Kill(file)
    file += ".ubr"
    f = utility.openfile(file, utility_file_mode_enum.for_binary)
    For i As Integer = 1 To Len(l) Step 2
      u = ((Instr(hexchars, Mid(l, i, 1)) - 1) Shl 4) + Instr(hexchars, Mid(l, i + 1, 1)) - 1
      Put #f, (i + 1) Shr 1, u
    Next i
    Close #f
  End If
  
  f = utility.openfile(file, utility_file_mode_enum.for_binary)
  If f = 0 Then terminate()
  Get #f, 1, header
  Close #f
  
  'validate, load levelpack, set flags, call game_run(), read results, quit
  'error message is printed to console, a php script echoes it back to the client, who then speaks the message and continues
  'things to validate: orbtokens, speed, player, levelpack, levelnumber, frame_total, hashes
  
  setting.players = 1 'don't allow multiplayer records
  With header
    If .checkhash() = false Then badmessage("hash fail, hacker!")
    If .orbtokens < 0 Or .orbtokens > 2 Or .players <> 1 Or .speed < 1 Then badmessage("bad game settings")
    For i As Integer = 1 To Len(Trim(.player))
      If Instr(validchars_extended, Mid(.player, i, 1)) = 0 Then badmessage("bad player name")
    Next i
    
    For i As Integer = 1 To Len(Trim(.levelpack))
      If Instr(validchars_base, Mid(.levelpack, i, 1)) = 0 Then badmessage("bad level pack name")
    Next i
    For i As Integer = 1 To levelpack.list_total
      If levelpack.list(i).title = Trim(.levelpack) Then valid = true
    Next i
    If valid = false Then badmessage("level pack does not exist")
    levelpack.load(Trim(header.levelpack))
    
    If .levelnumber < 0 Or .levelnumber > levelpack.level_total Then badmessage("bad level number")
    If .frame_total <= 0 Or .frame_total > game.replay.frame_max Then badmessage("bad frame total")
  End With
  
  With game.mode
    .level = header.levelnumber
    .lives = 0
    .speed = header.speed
    .orbtokens = header.orbtokens
    .replayfile = -1 'special value
    .instantrestart = false
  End With
  game.run()
  
  f = Freefile()
  Open cons For Output As #f
  Print #f, levelpack.title
  Print #f, game.mode.level
  Print #f, game.result.scoregained_master
  Print #f, Trim(header.player)
  Close #f
  
  terminate()
End Sub

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
  For i As Integer = 1 To scorespermode
    With mission_score(i)
      Input #f, .score, .level
      Line Input #f, .player
    End With
  Next i
  For i As Integer = 1 To scorespermode
    With arcade_score(i)
      Input #f, .score, .level
      Line Input #f, .player
    End With
  Next i
  With arcade_save
    Input #f, .level, .lives, .score, .orbtokens
  End With
  For i As Integer = 1 To level_total
    With master_score(i)
      Input #f, .score
      Line Input #f, .player
    End With
  Next i
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
  For i As Integer = 1 To scorespermode
    With mission_score(i)
      Print #f, .score, .level
      Print #f, .player
    End With
  Next i
  For i As Integer = 1 To scorespermode
    With arcade_score(i)
      Print #f, .score, .level
      Print #f, .player
    End With
  Next i
  With arcade_save
    Print #f, .level, .lives, .score, .orbtokens
  End With
  For i As Integer = 1 To level_total
    With master_score(i)
      Print #f, .score
      Print #f, .player
    End With
  Next i
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

Sub main_levelpack_type.unlock ()
  'unlocks whatever pack the current levelpack is supposed to unlock
  'called when pack is beat in arcade / mission mode
  
  Dim As Integer f
  Dim As Integer unlocks_separator = Instr(unlocks, ";")
  Dim As String unlocks_pack = unlocks, unlocks_message
  
  'won't unlock anything
  If Len(unlocks) = 0 Then Return
  
  'there is some message to show
  If unlocks_separator > 0 Then
    unlocks_pack = Left(unlocks, unlocks_separator - 1)
    unlocks_message = Mid(unlocks, unlocks_separator + 1)
  End If
  
  'return if levelpack does not exist
  f = utility.openfile("data/levelpacks/" & Lcase(unlocks_pack) & "/data.txt", _
    utility_file_mode_enum.for_input, true)
  If f = false Then Return
  Close #f
  
  'return if levelpack is already listed
  For i As Integer = 1 To list_total
    If list(i).title = unlocks_pack Then Return
  Next i
  
  addlp(unlocks_pack)
  sound.speak("yay. more levels to play. i'm a poet, and you didn't even know it")
  
  If Len(unlocks_message) > 0 Then menu.notify(unlocks_message)
  menu.notify("Levelpack Unlocked: " & unlocks_pack)
  
  If unlocks_pack = "Supernatural" Then
    setting.unlockedmode = setting_featurelock_enum.progressing
    menu.notify("Gallery and Level Downloads Unlocked")
  End If
  
  If unlocks_pack = "FinalChapter" Then
    setting.unlockedmode = setting_featurelock_enum.unlocked
    menu.notify("Level Editor Unlocked")
  End If
End Sub

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

sub main_player_type.selectname ()
  Dim As String n
  Dim As menu_setting_type mainmenu
  
  'type a player name
  'if it's a new player, confirm making new player
  'if they don't want a new player, then give them a menu with the list of existing player names
  
  n = utility.gettext(lastplayer,, "Enter player name (for highscores)")
  If n = "" or n = "Player name" Then n = "Guest"
  
  For i As Integer = 1 To name_total
    If Ucase(Name(i)) = Ucase(n) Then
      Name(i) = n 'change case of player name
      lastplayer = n
      return
    End If
  Next i
  
  with mainmenu
    .title = "New Player"
    .option_total = iif(name_total > 1, 3, 2)
    .option(1) = "Play as " + n
    .option(2) = "Enter a different player name"
    .option(3) = "Browse existing player names"
  end with
  
  select case menu.show(mainmenu)
  case 1:
    name_total += 1
    If name_total > name_max Then name_total = 1
    Name(name_total) = n
    lastplayer = n
  case 2:
    selectname()
  case 3:
    With mainmenu
      .title = "Select a player"
      .option_total = name_total
      For i As Integer = 1 To name_total
        .option(i) = Name(i)
      Next i
      .disablecancel = true
    End With
    
    lastplayer = Name(menu.show(mainmenu))
  end select
End sub

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
