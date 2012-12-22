
Sub orb_type.reset ()
  total = 0
  queue = 0
  For i As Integer = 1 To paddle_side_enum.max
    For i2 As Integer = 1 To setting.players
      paddle(i, i2) = 0
    Next i2
  Next i
End Sub

Sub orb_type.add ()
  If total + setting.players > max Then
    queue += 1
    return
  End If
  
  sound.add(sound_enum.enemyorb_create)
  
  laser.power += 20
  If laser.power = 20 Then ..paddle.graphic.gfxreset()
  
  For i As Integer = 1 To ..paddle.total
    With ..paddle.object(i)
      If .killme = false Then
        paddle(.side, .owner) += 1
        .killme = true
      End If
    End With
  Next i
  
  xfx.camshake.add(1)
  
  For i As Integer = 1 To setting.players
    total += 1
    
    With object(total)
      .x = game.control(i).x
      .y = 0
      .xv = 0
      .yv = 0
      
      gravity.add(.x, .y, gravity.scalefactor_orb, gravity_enum.orbpower, total)
      
      .scale_display = .scale_exploding
      .angle = 0
      
      .owner = i
      
      .lives = lives_max / setting.players
      .killme = false
    End With
  Next i
End Sub

Sub orb_type.move ()
  Dim As Integer a
  
  If queue > 0 Then
    add()
    queue -= 1
  End If
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  a = 1
  While a <= total
    If object(a).killme Then
      sound.add(sound_enum.enemyorb_destroy)
      
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
      
      For i As Integer = 1 To gravity.total
        With gravity.object(i)
          If .style = gravity_enum.orbpower Then
            If .special_enemy = a Then
              .killme = true
            Elseif .special_enemy > a Then
              .special_enemy -= 1
            End If
          End If
        End With
      Next i
      
      If total = 0 Then
        For i As Integer = 1 To paddle_side_enum.max
          For i2 As Integer = 1 To setting.players
            While paddle(i, i2) > 0
              ..paddle.add(i, i2)
              paddle(i, i2) -= 1
            Wend
          Next i2
        Next i
        ball.addgroup()
      End If
    Else
      a += 1
    End If
  Wend
End Sub

Sub orb_type.display ()
  #ifndef server_validator
  For i As Integer = orb.total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

sub orb_object_type.move ()
  Dim As Integer collision_x, collision_y, collision_r, collision_testx, collision_testy
  Dim As Double d1, d2, d3, dx, dy
  
  #macro ballboxcollision(x1, y1, x2, y2, cx, cy, r)
    collision_testx = cx
    collision_testy = cy
    
    If collision_testx < x1 Then collision_testx = x1 Else If collision_testx > x2 Then collision_testx = x2
    If collision_testy < y1 Then collision_testy = y1 Else If collision_testy > y2 Then collision_testy = y2
    
    collision_testx -= cx
    collision_testy -= cy
    
    If collision_testx * collision_testx + collision_testy * collision_testy > r * r Then Continue For
    
    collision_testx += cx
    collision_testy += cy
  #endmacro
  
  'movement
  xv *= .99
  If Sgn(xv) <> Sgn(game.control(owner).x - x) Then xv = 0
  If Abs(game.control(owner).x - x) > 50 Then
    xv += Sgn(game.control(owner).x - x) * orb.xslidefactor
  End If
  If game.control(owner).click Then yv -= game.gravityfactor * 2 Else yv += game.gravityfactor * 2
  If Abs(yv) > game.gravitymax Then yv = Sgn(yv) * game.gravitymax
  
  x += xv
  y += yv
  
  If x < 0 Then
    x = -x
    xv *= -1
  End If
  If x > screen.default_sx - 1 Then
    x = (screen.default_sx - 1) * 2 - x
    xv *= -1
  End If
  If y < 0 Then
    y = -y
    yv = 0
    xfx.particle.add(x, 0)
  End If
  If y > screen.default_sy Then
    y = (screen.default_sy - 1) * 2 - y
    yv *= -.7
    xfx.particle.add(x, screen.default_sy - 1)
  End If
  
  If lives > 0 Then
    scale_display += (scale - scale_display) * .01
  Else
    scale_display += (scale_exploding - scale_display) * .01
  End If
  angle += .03
  
  'brick collision
  collision_x = x
  collision_y = y
  collision_r = scale * size
  For i2 As Integer = 1 To brick.total
    With brick.object(i2)
      If .is_explodable() Then
        ballboxcollision(.x1, .y1, .x2, .y2, collision_x, collision_y, collision_r)
        
        'slide brick out of the way
        brick.graphic.erasebrick(brick.object(i2))
        .independant = true
        .awardpoints = true
        
        d1 = Atan2(collision_testy - collision_y, collision_testx - collision_x)
        d2 = Cos(d1) * brickbumpspeed
        d3 = Sin(d1) * brickbumpspeed
        .x += d2
        .y += d3
        .x1 += d2
        .y1 += d3
        .x2 += d2
        .y2 += d3
      End If
    End With
  Next i2
  
  'fire lasers
  If scale_display / scale < 1.3 And game.frametotal Mod 3 = 0 Then
    d2 = scale_display * size
    For d1 = angle To angle + 2 * pi - 1E-6 Step 2 * pi / 5
      dx = Cos(d1 + pi / 2) * ..paddle.graphic.paddle_sx * scale * .4
      dy = Sin(d1 + pi / 2) * ..paddle.graphic.paddle_sx * scale * .4
      
      laser.add(x + Cos(d1) * d2 - dx, y + Sin(d1) * d2 - dy, Cos(d1), Sin(d1))
      laser.add(x + Cos(d1) * d2 + dx, y + Sin(d1) * d2 + dy, Cos(d1), Sin(d1))
    Next d1
  End If
  
  'termination
  If lives <= 0 Then
    If scale_exploding / scale_display < 1.3 Then killme = true
  End If
end sub

sub orb_object_type.display ()
  #ifndef server_validator
  Dim As Integer tx, ty
  Dim As Double ts
  
  tx = screen.scale_x(x)
  ty = screen.scale_y(y)
  ts = screen.scale * scale_display
  
  xfx.graphic.glow_show(x, y)
  
  For d as double = angle To angle + 2 * pi - 1E-6 Step 2 * pi / 5
    multiput(, tx + Cos(d) * ts * size, ty + Sin(d) * ts * size, _
      ..paddle.graphic.paddle(paddle_enum.normal, true), ts,, d + pi / 2, 255)
  Next d
  #endif
end sub
