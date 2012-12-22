
Sub sound_speak_thread (Byval text As Any Ptr)
  #ifndef server_validator
  Dim myt As Wstring * 512
  Dim As HRESULT hr
  
  DISPATCH_OBJ(tts)
  
  dhInitialize(TRUE)
  dhToggleExceptions(FALSE) 'set this TRUE to get error codes
  
  myt = "Sapi.SpVoice"
  hr = dhCreateObject(@myt, NULL, @tts)
  If hr <> 0 Then Exit Sub
  
  myt = *Cptr(String Ptr, text)
  dhPutValue(tts, ".Volume = %d", 100) '(sound.audio.effect_volume shr 2) + 37)
  dhCallMethod(tts, ".Speak(%S)", @myt)
  
  SAFE_RELEASE(tts)
  
  'announce end of sub, so music can be unmuted
  mutexlock(sound.threadmutex)
  sound.speakthread = 0
  mutexunlock(sound.threadmutex)
  #Endif
End Sub

Sub sound_type.start ()
  #ifndef server_validator
  Dim As Integer f
  Dim As String dp = "data/sound/", l
  
  threadmutex = Mutexcreate()
  
  f = utility.openfile("data/volume.txt", utility_file_mode_enum.for_input)
  Input #f, volume_music
  Input #f, volume_sfx
  Close #f
  
  With audio
    .start()
    
    'set volume
    commit_volume_music()
    commit_volume_sfx()
    
    'load effects
    f = utility.openfile(dp & "sfx/list.m3u", utility_file_mode_enum.for_input)
    While Not Eof(f)
      Line Input #f, l
      .register_effect(dp & "sfx/" & l)
    Wend
    Close #f
    
    'load music
    f = utility.openfile(dp & "music/list.m3u", utility_file_mode_enum.for_input)
    While Not Eof(f)
      Line Input #f, l
      .register_music(dp & "music/" & l)
    Wend
    Close #f
    
    .update()
  End With
  #Endif
End Sub

Sub sound_type.add (Byval s As sound_enum)
  #ifndef server_validator
  audio.fire_effect(s)
  #Endif
End Sub

Sub sound_type.move ()
  #ifndef server_validator
  
  Static As Integer ismuted = false
  
  If volume_music > volumequiet Then
    Mutexlock(threadmutex)
    If ismuted Then
      if speakthread = 0 then
        ismuted = false
        commit_volume_music()
      end if
    Else
      If speakthread > 0 Then
        ismuted = true
        commit_volume_music(volumequiet)
      End If
    End If
    Mutexunlock(threadmutex)
  End If
  
  audio.update()
  #Endif
End Sub

Sub sound_type.finish ()
  #ifndef server_validator
  Dim As Integer f
  
  f = utility.openfile("data/volume.txt", utility_file_mode_enum.for_output)
  Print #f, volume_music
  Print #f, volume_sfx
  Close #f
  
  audio.finish()
  Mutexdestroy(threadmutex)
  #Endif
End Sub

Sub sound_type.commit_volume_music (level as integer = -1)
  #ifndef server_validator
  if level < 0 then level = volume_music
  audio.set_volume_music((level - 1) * volumestep)
  #Endif
end sub

Sub sound_type.commit_volume_sfx (level as integer = -1)
  #ifndef server_validator
  if level < 0 then level = volume_sfx
  audio.set_volume_effect((level - 1) * volumestep)
  #Endif
end sub

Sub sound_type.speak (Byref _text As String, Byval dowait As Integer = false)
  #ifndef server_validator
  Static As String text
  
  #ifdef debug
    utility.logerror(_text)
  #Endif
  
  #macro waitforit()
    'similar to threadwait, but the thread nullifies itself
    mutexlock(threadmutex)
    while speakthread > 0
      mutexunlock(threadmutex)
      sleep(10, 1)
      mutexlock(threadmutex)
    wend
    mutexunlock(threadmutex)
  #endmacro
  
  If audio.effect_volume = 0 Then Exit Sub
  
  waitforit()
  
  if _text = "" then return
  text = _text
  
  mutexlock(threadmutex)
  speakthread = Threadcreate(@sound_speak_thread(), @text)
  mutexunlock(threadmutex)
  
  If dowait Then
    waitforit()
  End If
  
  move() 'give that a chance to mute the music
  #Endif
End Sub

Sub sound_type.set_volume ()
  'volume menu
  #ifndef server_validator
  
  Dim As menu_setting_type menumajor, menuminor
  
  With menumajor
    .title = "Adjust the Volume"
    .option_total = 2
    .option(1) = "SFX Volume"
    .option(2) = "Music Volume"
  End With
  
  With menuminor
    .option_total = 18
    .option(1) = "Off"
    .option(2) = "Low"
    .option(3) = "Lowish"
    .option(4) = "Medium"
    .option(5) = "Highish"
    .option(6) = "High"
    .option(7) = "Very high"
    .option(8) = "Test your sound-proof studio"
    .option(9) = "Too high"
    .option(10) = "Bleeding-ear high"
    .option(11) = "Annoy your neighbors"
    .option(12) = "Annoy your half-deaf neighbors"
    .option(13) = "UltraBreaker vs. the car stereo"
    .option(14) = "Blow your speakers so you can get new ones"
    .option(15) = "Entertain the police department"
    .option(16) = "Declare yourself supreme dictator"
    .option(17) = "Simulate caffeine OD"
    .option(18) = "Host a concert!!!"
  End With
  
  Do
    menu.show(menumajor)
    
    menuminor.scrolloffset = 0
    Select Case menumajor.returnvalue
    Case 1
      menuminor.title = "SFX Volume"
      Do
        menuminor.option_preselected = volume_sfx
        
        If menu.show(menuminor) Then
          volume_sfx = menuminor.returnvalue
          commit_volume_sfx()
        End If
      Loop Until menuminor.returnvalue = false
    Case 2
      menuminor.title = "Music Volume"
      Do
        menuminor.option_preselected = volume_music
        
        If menu.show(menuminor) Then
          volume_music = menuminor.returnvalue
          commit_volume_music()
        End If
      Loop Until menuminor.returnvalue = false
    End Select
  Loop Until menumajor.returnvalue = false
  #Endif
End Sub
