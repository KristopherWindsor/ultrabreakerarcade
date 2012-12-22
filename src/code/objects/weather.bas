
sub weather_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  weather.gfxchange()
end sub

Sub weather_type.start ()
  graphic.start()
End Sub

Sub weather_type.reset ()
  is_wind = false
  is_rain = false
  is_fireworks = false
  is_metal = false
   
  wind_xv = 0
  
  rain_xv = 0
  rain_yv = 0
  
  fireworks_total = 0
End Sub

Sub weather_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub weather_type.add (Byval climate As weather_enum)
  
  sound.add(sound_enum.weather_create)
  
  Select Case climate
  Case weather_enum.wind
    is_wind = true
    wind_xv = (wind_speed_max - wind_speed_min) * rnd() + wind_speed_min
  Case weather_enum.rain
    is_rain = true
    rain_xv = (rain_speed_x_max - rain_speed_x_min) * rnd() + rain_speed_x_min
    rain_yv = (rain_speed_y_max - rain_speed_y_min) * rnd() + rain_speed_y_min
  Case weather_enum.fireworks
    is_fireworks = true
  Case weather_enum.metal
    is_metal = true
  End Select
End Sub

Sub weather_type.move ()
  Dim As Integer a, x, y, style
  
  If is_wind Then
    If Rnd() < .5 Then wind_xv = -wind_xv
    
    If brick.total + 36 <= brick.max andalso _
      Int(Rnd() * game.fps * 8 / game.mode_windfactor) = 0 Then
      
      If wind_xv < 0 Then
        x = screen.default_sx * 1.1
      Else
        x = -screen.default_sx * .1 - wind_shape_size
      End If
      y = (screen.default_sy - wind_shape_size) * (.2 + Rnd() * .6)
      style = Int(Rnd() * Cdbl(brick_enum.last_extended - brick_enum.first_extended + 1) + _
        Cint(brick_enum.first_extended))
      
      Select Case Rnd() * 4.25
      Case is <= 1
        'line (9)
        For i As Integer = 0 To 8
          brick.add(x, y + i * wind_shape_size / 8, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
        Next i
      Case is <= 2
        'triangle (21)
        'base
        For i As Integer = 0 To 4
          brick.add(x + i * wind_shape_size / 4, y + wind_shape_size, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
        Next i
        'diagonals
        For i As Integer = 1 To 8
          brick.add( _
            x + (16 - i) * wind_shape_size / 16, _
            y + (8 - i) * wind_shape_size / 8, _
            style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
          brick.add( _
            x + i * wind_shape_size / 16, _
            y + (8 - i) * wind_shape_size / 8, _
            style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
        Next i
      Case is <= 3
        'box (20)
        For i As Integer = 0 To 4
          'columns
          brick.add(x, y + (i + 1) * wind_shape_size / 6, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
          brick.add(x + wind_shape_size, y + (i + 1) * wind_shape_size / 6, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
          'rows
          brick.add(x + i * wind_shape_size / 4, y, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
          brick.add(x + i * wind_shape_size / 4, y + wind_shape_size, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
        Next i
      Case is <= 4
        'circle (32)
        For d As Double = 0 To 31 * pi / 16 + 1E-9 Step pi / 16
          brick.add(x + (Cos(d) + 1) * wind_shape_size / 2, _
            y + (Sin(d) + 1) * wind_shape_size / 2, style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
          brick.graphic.set_mini(brick.object(brick.total))
        Next d
      Case is <= 4.25
        'diamond (36) (rare)
        For i As Integer = 0 To 8
          for xn as integer = -1 to 1 step 2
            for yn as integer = -1 to 1 step 2
              brick.add( _
                x + xn * i * wind_shape_size / 16 + wind_shape_size / 2, _
                y + yn * i * wind_shape_size / 16 + iif(yn < 0, wind_shape_size, 0), _
                style, wind_brick_size, wind_brick_value, wind_xv, 0, true)
              brick.graphic.set_mini(brick.object(brick.total))
            next yn
          next xn
        Next i
      End Select
    End If
  End If
  
  If is_rain andalso Int(Rnd() * game.fps * 2) = 0 Then
    gravity.add(screen.default_sx * Rnd(), rain_startoffset, _
      gravity.scalefactor_rain, gravity_enum.rain)
  End If
  
  If is_fireworks Then
    'new explosion
    If Int(Rnd() * game.fps) = 0 And fireworks_total < fireworks_max Then
      fireworks_total += 1
      sound.add(sound_enum.fireworks_create)
      With fireworks(fireworks_total)
        .x = -fireworks_startoffset + Int(Rnd() * 2) * (screen.default_sx + fireworks_startoffset * 2)
        .y = screen.default_sy - 1
        .xv = -Sgn(.x) * fireworks_speed_x * Rnd()
        .yv = (fireworks_speed_y_max - fireworks_speed_y_min) * rnd() + fireworks_speed_y_min
        .scale = fireworks_scale_initial
        .angle = Rnd() * pi * 2
        .alpha = &HFF
      End With
    End If
    
    For i As Integer = 1 To fireworks_total
      fireworks(i).move()
    Next i
    
    a = 1
    While a <= fireworks_total
      If fireworks(a).alpha = 0 Then
        fireworks(a) = fireworks(fireworks_total)
        fireworks_total -= 1
      Else
        a += 1
      End If
    Wend
  End If
End Sub

Sub weather_type.display ()
  #ifndef server_validator
  If is_fireworks Then
    For i As Integer = fireworks_total To 1 Step -1
      fireworks(i).display()
    Next i
  End If
  #Endif
End Sub

Sub weather_type.finish ()
  graphic.finish()
End Sub

Sub weather_fireworks_object_type.move ()
  Dim As Double d
  
  angle += weather.fireworks_rotationspeed
  
  If yv > weather.fireworks_speed_y_explode Then
    'explode
    If scale < weather.fireworks_scale_max Then scale = weather.fireworks_scale_max
    For i As Integer = 1 To brick.total
      With brick.object(i)
        d = brick.graphic.brick_sx * .scale + scale * weather.graphic.fireworks_sr
        If (.x - x) * (.x - x) + (.y - y) * (.y - y) < d * d And alpha = 250 Then
          .killme = true
          
          d = Atan2(.y - y, .x - x)
          
          .awardpoints = true
          .hit_bonusball = 0
          .hit_shadow_xv = Cos(d) * xfx_flyingbrick_type.speed
          .hit_shadow_yv = Sin(d) * xfx_flyingbrick_type.speed
          .hit_shadow_spin = Sgn(Rnd() - Rnd())
        End If
      End With
    Next i
    
    scale += weather.fireworks_scale_step
    
    If alpha > 0 Then
      If alpha = &HFF And x + scale * weather_graphic_type.fireworks_sr > 0 And _
        x - scale * weather.graphic.fireworks_sr < screen.default_sx - 1 And _
        y + scale * weather.graphic.fireworks_sr > 0 Then
        
        sound.add(sound_enum.fireworks_destroy)
        xfx.camshake.add(.5)
      End If
      alpha -= 5
    End If
  Else
    yv += game.gravityfactor
    x += xv
    y += yv
  End If
End Sub

Sub weather_fireworks_object_type.display ()
  #ifndef server_validator
  multiput(, screen.scale_x(x + xfx.camshake.x), screen.scale_y(y + xfx.camshake.y), _
    weather.graphic.fireworks, scale * screen.scale,, angle, alpha)
  #Endif
End Sub

Sub weather_graphic_type.start ()
  #ifndef server_validator
  fireworks = utility.createimage(fireworks_sd, fireworks_sd mop("fireworks"))
  #Endif
End Sub

Sub weather_graphic_type.gfxchange ()
  #ifndef server_validator
  utility.loadimage(main.levelpack.gfxset + "/fireworks", fireworks)
  #Endif
End Sub

Sub weather_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(fireworks mop("fireworks"))
  #Endif
End Sub
