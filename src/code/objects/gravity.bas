
sub gravity_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  gravity.gfxchange()
end sub

Sub gravity_type.start ()
  graphic.start()
End Sub

Sub gravity_type.reset ()
  total = 0
End Sub

Sub gravity_type.gfxchange (Byval nothing As Any Ptr = 0)
  graphic.gfxchange()
End Sub

Sub gravity_type.add (Byval x As Integer, Byval y As Integer, Byval scale As Double, _
  Byval style As gravity_enum = gravity_enum.normal, Byval enemy As Integer = 0)
  
  'scale = 1 for a brick that appears at the original size (defined by png) at the default size
  
  If total = max Then return
  
  total += 1
  If game.frametotal > 0 And style = gravity_enum.rain Then
    sound.add(sound_enum.brickgravity_create)
  End If
  
  With object(total)
    .style = style
    .x = x
    .y = y
    .scale = scale
    
    If style = gravity_enum.rain Then
      .scale_display = scale
    Else
      .scale_display = .01
    End If
    
    .angle = 0
    .special_enemy = enemy
    .killme = false
  End With
End Sub

Sub gravity_type.move ()
  Dim As Integer a
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  a = 1
  While a <= total
    If object(a).killme Then
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
End Sub

Sub gravity_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub gravity_type.finish ()
  graphic.finish()
End Sub

Sub gravity_graphic_type.start ()
  #ifndef server_validator
  orb = utility.createimage(orb_sd, orb_sd mop("orb"))
  #Endif
End Sub

Sub gravity_graphic_type.gfxchange ()
  #ifndef server_validator
  utility.loadimage(main.levelpack.gfxset + "/gravityorb", orb)
  #Endif
End Sub

Sub gravity_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(orb mop("orb"))
  #Endif
End Sub

sub gravity_object_type.move ()
  scale_display += (Abs(scale) - scale_display) * .002
  angle += .004
  
  Select Case style
  Case gravity_enum.normal
  Case gravity_enum.mouse
    x += (game.control(1).x - x) * .1
    y += (game.control(1).y - y) * .1
  Case gravity_enum.rain
    x += weather.rain_xv
    y += weather.rain_yv
  Case gravity_enum.enemypower
    x = enemy.object(special_enemy).x
    y = enemy.object(special_enemy).y
  Case gravity_enum.orbpower
    x = orb.object(special_enemy).x
    y = orb.object(special_enemy).y
  End Select
  
  For i as integer = 1 To ball.total
    With ball.object(i)
      If .stuck = 0 Then
        var d = Sqr((x - .x) * (x - .x) + (y - .y) * (y - .y))
        If d < Abs(scale) * gravity.graphic.orb_sr Then d = Abs(scale) * gravity.graphic.orb_sr
        
        var ang = Atan2(y - .y, x - .x)
        .xv += gravity.power * scale * Cos(ang) / d
        .yv += gravity.power * scale * Sin(ang) / d
      End If
    End With
  Next i
  
  if style = gravity_enum.rain and y > screen.default_sy * 1.5 then killme = true
end sub

sub gravity_object_type.display ()
  #ifndef server_validator
  If style = gravity_enum.enemypower or style = gravity_enum.orbpower Then return
  
  multiput(, _
    screen.scale_x(x + xfx.camshake.x), _
    screen.scale_y(y + xfx.camshake.y), _
    gravity.graphic.orb, scale_display * screen.scale,, angle, 100)
  #endif
end sub
