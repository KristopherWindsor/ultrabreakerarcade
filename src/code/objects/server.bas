
Sub server_type.start ()
  Dim As Integer f
  
  f = utility.openfile("data/update.txt", utility_file_mode_enum.for_input)
  If f > 0 Then
    Input #f, update
    Close #f
  End If
  
  submit_total = 0
  f = utility.openfile("data/submissions.txt", utility_file_mode_enum.for_input)
  While Eof(f) = false
    submit_total += 1
    Line Input #f, submit(submit_total)
  Wend
  Close #f
  
  lbpack_total = 0
  f = utility.openfile("data/levelpacks/leaderboard.txt", utility_file_mode_enum.for_input)
  While Eof(f) = false
    lbpack_total += 1
    Line Input #f, lbpack(lbpack_total)
  Wend
  Close #f
End Sub

Sub server_type.finish ()
  Dim As Integer f
  
  f = utility.openfile("data/update.txt", utility_file_mode_enum.for_output)
  Print #f, update
  Close #f
  
  f = utility.openfile("data/submissions.txt", utility_file_mode_enum.for_output)
  For i As Integer = 1 To submit_total
    Print #f, submit(i)
  Next i
  Close #f
  submit_total = 0
  
  lbpack_total = 0
End Sub

Sub server_type.addrecording (Byref filename As String)
  
  Dim As Integer valid
  
  If submit_total = submit_max Then Exit Sub
  
  If setting.players <> 1 Then Exit Sub
  If islbpack(main.levelpack.title) = false Then Exit Sub
  
  'no duplicates
  For i As Integer = 1 To submit_total
    If filename = submit(i) Then Exit Sub
  Next i
  
  submit_total += 1
  submit(submit_total) = filename
End Sub

Sub server_type.getlevels ()
  #ifndef server_validator
  'get levelpack list -> mark as LB and already downloaded -> download
  
  Const delimiter = !"\n", list_max = 1024
  
  Dim As Integer a, b, f, n, list_total, list_has(1 To list_max)
  Dim As String commands, levellist, list_name(1 To list_max), list_description(1 To list_max)
  Dim As menu_setting_type mainmenu
  
  If network.hitpage("/main/download/index.php?get=packlist", levellist) = false orelse _
    Len(levellist) = 0 Then
    
    sound.speak("error. the store is not available at this time")
    Exit Sub
  End If
  levellist = Left(levellist, Len(levellist) - 1) 'remove ending newline
  
  a = 0
  Do
    n = Not n
    b = a
    a = Instr(a + 1, levellist, delimiter)
    If a = 0 Then a = Len(levellist) + 1
    
    If n Then
      list_total += 1
      list_name(list_total) = Mid(levellist, b + 1, a - b - 1)
      
      'can't test against list, because it doesn't mentioned locked packs
      f = utility.openfile("data/levelpacks/" + lcase(list_name(list_total)) + "/data.txt", _
        utility_file_mode_enum.for_input, true)
      list_has(list_total) = (f > 0)
      if f > 0 then close #f
    Else
      list_description(list_total) += Mid(levellist, b + 1, a - b - 1)
    End If
  Loop Until a = Len(levellist) + 1
  
  If Instr(list_name(1), "error") > 0 Then
    menu.notify(list_name(1))
    sound.speak("error. cannot connect to server")
    Exit Sub
  End If
  
  Do
    With mainmenu
      .title = "Get Levels"
      .option_total = list_total
      For i As Integer = 1 To list_total
        If list_has(i) Then .option(i) = "* " Else .option(i) = ""
        If islbpack(list_name(i)) Then .option(i) += "(Official) "
        .option(i) += list_name(i) & " (" & list_description(i) & ")"
      Next i
    End With
    
    'using notify for errors instead of speak because this will be confusing without messages
    If menu.show(mainmenu) > 0 Then
      If list_has(mainmenu.returnvalue) Then
        menu.notify("Levels Already Downloaded")
        'sound_speak("you already have these levels")
      Else
        If menu.confirm("Download " & list_name(mainmenu.returnvalue) & "?") Then
          If processcommands("PROCESS /main/download/index.php?get=pack&name=" & _
            list_name(mainmenu.returnvalue) & !"\nEND") Then
            
            main.levelpack.addlp(list_name(mainmenu.returnvalue))
            list_has(mainmenu.returnvalue) = true
            'menu.notify("Levels Downloaded")
            sound.speak("levels downloaded")
          else
            'if the download failed after making the folder, rename it
            'otherwise game thinks you have pack, and won't let you download it again
            'assert: if any one file fails, this code is executed
            var nada = name("data/levelpacks/" + lcase(list_name(mainmenu.returnvalue)), _
              "data/levelpacks/" + lcase(list_name(mainmenu.returnvalue)) + "-failed-download-" & rnd())
            'show a notify, in addition to speak, or player will be confused
            menu.notify("Error! Please Try Again")
          End If
        End If
      End If
    End If
  Loop Until mainmenu.returnvalue = false
  #Endif
End Sub

Function server_type.islbpack (Byref lp As String) As Integer
  For i As Integer = 1 To lbpack_total
    If lp = lbpack(i) Then Return true
  Next i
  Return false
End Function

Function server_type.processcommands (Byref c As String) As Integer
  'commands received from the website, may be multiples separated by !"\n"
  'DOWNLOAD url localfile, or MKDIR localdir, or OPEN url (for EXE program updates)
  'updates are prefixed by UPDATE and an id number
  'aside from updates, this is also used to download levelpacks
  
  #ifndef server_validator
  Const arg_max = 3, command_max = 2048
  
  Dim As Integer a, b, arg_total, command_total
  Dim As String args(1 To arg_max), commands(1 To command_max), process
  
  'either command list is blank, or only contains "END"
  'maybe caused normally because there are no updates; don't give error
  If Len(c) < 5 Then Return false
  
  a = 0
  Do
    b = a
    a = Instr(a + 1, c, !"\n")
    If a = 0 Then a = Len(c) + 1
    
    command_total += 1
    commands(command_total) = Mid(c, b + 1, a - b - 1)
  Loop Until a = Len(c) + 1
  
  'invalid command list; maybe an error message (not ended with "END")
  If commands(command_total) <> "END" Then
    utility.logerror(c)
    sound.speak("error. operation cancelled")
    Return false
  End If
  
  For i As Integer = 1 To command_total - 1
    arg_total = 0
    a = 0
    Do
      b = a
      a = Instr(a + 1, commands(i), " ")
      If a = 0 Then a = Len(commands(i)) + 1
      
      arg_total += 1
      args(arg_total) = Mid(commands(i), b + 1, a - b - 1)
    Loop Until a = Len(commands(i)) + 1 Or arg_total = arg_max
    
    Select Case Ucase(args(1))
    Case "DOWNLOAD" 'potential danger: downloads a bad program (but will not run it, so is ok)
      If Ucase(args(3)) = "ULTRABREAKER.EXE" Or Ucase(args(3)) = "LEVELER.EXE" Then
        sound.speak("error. someone is hacking the server and trying to destroy your computer")
      Else
        utility.showloading("Downloading " & args(3))
        If network.downloadfile(args(2), args(3)) = false Then
          sound.speak("error. the file cannot be downloaded. will try again later")
          Return false
        End If
      End If
    Case "MKDIR"
      var temp = Mkdir(args(2))
    Case "OPEN" 'potential danger: opens a bad webpage (either an IE6 exploit, or a bad download link)
      If Left(args(2), 24) = "http://ultrabreaker.com/" orelse menu.confirm("Open External Webpage?") Then
        utility.showloading("Opening " & args(2))
        Shell("explorer """ & args(2) & """")
      Else
        utility.logerror("Attempted to open external url: " & args(2))
      End If
    Case "PROCESS"
      'recursive call: if this fails, quit (worst thing that happens: some useless files are on the client)
      utility.showloading("Fetching commands")
      process = ""
      If network.hitpage(args(2), process) = false orelse processcommands(process) = false Then
        'maybe recursive call has already spoken the error message
        If Len(process) = 0 Then sound.speak("error. the commands cannot be downloaded. will try again later")
        Return false
      End If
    Case "UPDATE"
      var uc = Trim(Mid(commands(i), Len(args(2)) + 8))
      If Len(uc) > 0 Then
        If processcommands(uc & !"\nEND") = false Then Return false
      End If
      update = Val(args(2))
    End Select
  Next i
  
  Return true
  #Else
  Return false
  #Endif
End Function

Sub server_type.sync (Byval theend As Integer = true)
  'ask to submit list of recordings from the queue
  #ifndef server_validator
  
  Const hexchars = "0123456789ABCDEF"
  
  Dim As Integer a, b, byte_hilo, byte_hi, byte_lo, f, handle, doopensite
  Dim As String filecontents, hexxed
  Dim As menu_setting_type mainmenu
  
  If submit_total = 0 Then Return
  
  'determine if game should sync
  
  With mainmenu
    .title = "Perform Server Sync?"
    .option_total = 3
    .screenshot_disable_intro = true
    .disablecancel = true
    .xoption = 3
    .option(1) = "Yes, and open website"
    .option(2) = "Yes"
    .option(3) = "No"
  End With
  
  Select Case setting.serversync
  Case setting_sync_enum.disabled
    Return
  Case setting_sync_enum.ask
    If menu.show(mainmenu) = 3 Then Return
    doopensite = (mainmenu.returnvalue = 1)
  Case setting_sync_enum.autosync
    'no changes
  Case setting_sync_enum.autosyncandopen
    doopensite = true
  End Select
  
  'exit fullscreen
  
  If theend Then
    Screenres screen.screen_sx, screen.screen_sy, 32
    put (screen.scale_x(0), screen.scale_y(0)), utility.graphic.menu, pset
    screencontrol(fb.get_window_handle, handle)
    ShowWindow(cast(hwnd, handle), SW_MINIMIZE)
  End If
  
  'part 1 - submit recordings
  
  For i As Integer = 1 To submit_total
    utility.showloading("Uploading " & i & " of " & submit_total & "...")
    
    f = utility.openfile(submit(i), utility_file_mode_enum.for_binary)
    If f = 0 orelse Lof(f) = 0 Then
      If f > 0 Then Close #f
      sound.speak("error. missing file. skipping recording")
      Continue For
    End If
    filecontents = Space(Lof(f))
    Get #f, 1, filecontents
    Close #f
    
    'special upload format is hex (doubles file size but prevents special characters)
    hexxed = ""
    For i2 As Integer = 0 To Len(filecontents) - 1
      byte_hilo = filecontents[i2]
      byte_lo = (byte_hilo And &HF)
      byte_hi = (byte_hilo Shr 4)
      hexxed += Mid(hexchars, byte_hi + 1, 1) & Mid(hexchars, byte_lo + 1, 1)
    Next i2
    If network.hitpage("/main/upload/index.php", filecontents, "recording=" & hexxed) = false Then
      sound.speak("error. cannot connect to server. program is now closing", true)
      Exit Sub
    End If
    If Len(filecontents) > 0 Then
      'give an error message: ie the recording already exists, or the hash check failed
      'continue with the rest of the recordings because client is connecting to the server
      sound.speak("error. " & filecontents)
    End If
  Next i
  
  'done with submissions
  If submit_total > 0 Then
    submit_total = 0
    If doopensite Then processcommands(!"OPEN http://ultrabreaker.com/main/index.php?cat=control\nEND")
  End If
  
  'part 2 - update
  utility.showloading("Updating...")
  If processcommands("PROCESS /main/download/index.php?get=update&version=" & _
    ultrabreaker_version_major & "." & ultrabreaker_version_minor & "&update=" & _
    update & !"\nEND") Then
    
    sound.speak("update complete")
  End If
  #Endif
End Sub
