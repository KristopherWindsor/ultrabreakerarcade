
Sub enemy_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  enemy.gfxchange()
End Sub

Sub enemy_type.start ()
  graphic.start()
End Sub

Sub enemy_type.reset ()
  total = 0
End Sub

Sub enemy_type.gfxchange ()
  Dim As Integer a, b, f
  Dim As Double i_a, i_x, i_y, p_a, p_d
  Dim As String l
  
  f = utility.openfile("data/graphics/" + main.levelpack.gfxset + "/enemies/data.txt", _
    utility_file_mode_enum.for_input)
  For i As Integer = 1 To enemy_enum.max
    With config(i)
      .laser_total = 0
      .engine_total = 0
      
      For i2 As Integer = 1 To .engine_max + .laser_max
        Do
          Line Input #f, l
        Loop Until Left(l, 2) <> "//"
        
        if l = "-" then
          if i2 <= .laser_max then
            i2 = .laser_max
            continue for
          else
            exit for
          end if
        end if
        
        a = Instr(l, " ")
        If a > 0 Then 'skip blank lines
          b = Instr(a + 1, l, " ")
          
          i_x = Val(Left(l, a - 1))
          i_y = Val(Mid(l, a + 1, b - a - 1))
          i_a = Val(Mid(l, b + 1)) * pi / 180
          
          'convert i_x and i_y to polar coords, from center of enemy
          i_x -= graphic.enemy_sr
          i_y -= graphic.enemy_sr
          p_a = Atan2(i_y, i_x)
          p_d = Sqr(i_x * i_x + i_y * i_y)
          
          If i2 <= .laser_max Then
            'add laser
            .laser_total += 1
            With .laser(.laser_total)
              .pa = p_a
              .pd = p_d
              .angle = i_a
            End With
          Else
            'add engine
            .engine_total += 1
            With .engine(.engine_total)
              .pa = p_a
              .pd = p_d
              .angle = i_a
            End With
          End If
        End If
      Next i2
      
      If .laser_total = 0 Then
        .laser_total = 1
        With .laser(1)
          .pa = 0
          .pd = 0
          .angle = 0
        End With
      End If
      
      If .laser_total = 1 Then
        .laser_total = 2
        .laser(2) = .laser(1)
      End If
    End With
  Next i
  Close #f
  
  graphic.gfxchange()
End Sub

Sub enemy_type.add (Byval x As Integer, Byval y As Integer, Byval style As enemy_enum, _
  Byval scale As Double, Byval value As Integer)
  
  'scale = 1 for an enemy that appears at the original size (defined by png) at the default size
  
  xfx.nuke.add(x, y)
  
  If total = max Then Return
  
  total += 1
  sound.add(sound_enum.enemyorb_create)
  
  With object(total)
    .style = style
    
    .x = x
    .y = y
    .xv = 0
    .yv = 0
    
    .scale = 0
    .scale_target = scale * scalefactor
    .value = value
    .angle = 0
    
    gravity.add(x, y, scale * gravitysizefactor(style) * gravity.scalefactor_enemy, _
      gravity_enum.enemypower, total)
    
    .ai_mode = enemy_mode_enum.firing
    .ai_target_x = 0
    .ai_target_y = 0
    .ai_angle = 0
    .ai_angle_v = 0
    .ai_cycle_ttl = 0
    
    .particle_current = 0
    
    For i As Integer = 1 To enemy.config(.style).engine_total
      For i2 As Integer = 1 To .particle_max
        .particle(i, i2).c = 0
      Next i2
    Next i
  End With
End Sub

Sub enemy_type.move ()
  
  Dim As Integer a
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  a = 1
  While a <= total
    If object(a).scale_target <= destructionscale Then
      sound.add(sound_enum.enemyorb_destroy)
      With object(a)
        game.result.scoregained = game.result.scoregained + .value ^ 1.16
        xfx.nuke.add(.x, .y)
      End With
      
      For i As Integer = 1 To gravity.total
        With gravity.object(i)
          If .style = gravity_enum.enemypower Then
            If .special_enemy = a Then
              .killme = true
            Elseif .special_enemy > a Then
              .special_enemy -= 1
            End If
          End If
        End With
      Next i
      
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
End Sub

Sub enemy_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub enemy_type.finish ()
  graphic.finish()
End Sub

Function enemy_config_object_type.coord_x (e As enemy_object_type_forward Ptr) As Double
  Dim As Double r
  
  Return Cos(pa + e->angle) * pd * e->scale + e->x
End Function

Function enemy_config_object_type.coord_y (e As enemy_object_type_forward Ptr) As Double
  Dim As Double r
  
  Return Sin(pa + e->angle) * pd * e->scale + e->y
End Function

Sub enemy_graphic_type.start ()
  #ifndef server_validator
  For i As Integer = 1 To enemy_enum.max
    enemy(i) = utility.createimage(enemy_sd, enemy_sd mop("enemy"))
  Next i
  #Endif
End Sub

Sub enemy_graphic_type.gfxchange ()
  #ifndef server_validator
  For i As Integer = 1 To enemy_enum.max
    utility.loadimage(main.levelpack.gfxset & "/enemies/" & i, enemy(i))
  Next i
  #Endif
End Sub

Sub enemy_graphic_type.finish ()
  #ifndef server_validator
  For i As Integer = 1 To enemy_enum.max
    utility.deleteimage(enemy(i) mop("enemy"))
  Next i
  #Endif
End Sub

Sub enemy_object_type.move ()
  
  Dim As Integer collide_x, collide_y
  Dim As Integer collision_x, collision_y, collision_r, collision_testx, collision_testy
  Dim As Double d1, d2, d3, enemy_v
  
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
  
  'adjust scale
  scale += (scale_target - scale) * .01
  
  'set mode
  ai_cycle_ttl -= 1
  If ai_cycle_ttl <= 0 Then
    ai_mode = (ai_mode Mod enemy_mode_enum.max) + 1
    Select Case ai_mode
    Case enemy_mode_enum.traveling
      ai_cycle_ttl = 300
    Case enemy_mode_enum.aiming
      'set target attack location
      Select Case style
      Case enemy_enum.rocker
        ai_cycle_ttl = 60
        ai_target_x = Int(Rnd() * screen.default_sx)
        ai_target_y = Int(Rnd() * screen.default_sy)
      Case enemy_enum.speedster
        ai_cycle_ttl = 60
        If orb.total >= 1 Then
          ai_target_x = orb.object(1).x
          ai_target_y = orb.object(1).y
        Else
          ai_target_x = paddle.object(1).x
          ai_target_y = paddle.object(1).y
        End If
      Case enemy_enum.destroyer
        ai_cycle_ttl = 0 'don't aim
        If Int(Rnd() * 2) = 0 Then
          with brick
            For d1 = 0 To pi * 2 Step pi / 8
              .add(x + Cos(d1) * 100, y + Sin(d1) * 100, brick_enum.normal, _
                enemy.newbrickscale, .value_enemyfired, Cos(d1) * brick.speed_enemyfired, _
                Sin(d1) * brick.speed_enemyfired, true)
              .graphic.set_mini(.object(.total))
            Next d1
          end with
        End If
      Case enemy_enum.scout
        ai_cycle_ttl = 20
        If orb.total >= 1 Then
          var tempindex = cint(Int(Rnd() * orb.total) + 1)
          ai_target_x = orb.object(tempindex).x
          ai_target_y = orb.object(tempindex).y
        Else
          var tempindex = cint(Int(Rnd() * paddle.total) + 1)
          ai_target_x = paddle.object(tempindex).x
          ai_target_y = paddle.object(tempindex).y
        End If
      End Select
    Case enemy_mode_enum.firing
      Select Case style
      Case enemy_enum.rocker
        ai_cycle_ttl = 60
      Case enemy_enum.speedster
        ai_cycle_ttl = 60
      Case enemy_enum.destroyer
        ai_cycle_ttl = 60
      Case enemy_enum.scout
        ai_cycle_ttl = 120
      End Select
    Case enemy_mode_enum.seeking
      'set target position
      ai_target_x = Int(Rnd() * (brick.field_x2 - brick.field_x1)) + brick.field_x1
      ai_target_y = Int(Rnd() * (brick.field_y2 - brick.field_y1)) + brick.field_y1
      Select Case style
      Case enemy_enum.rocker
        ai_cycle_ttl = 90
      Case enemy_enum.speedster
        ai_cycle_ttl = 90
      Case enemy_enum.destroyer
        ai_cycle_ttl = 15
      Case enemy_enum.scout
        ai_cycle_ttl = 90
      End Select
    End Select
  End If
  
  'adjust angle (even when not in seek / aim modes)
  'adjust target angle, then real angle
  ai_angle = Atan2(ai_target_y - y, ai_target_x - x)
  If angle < ai_angle Then
    ai_angle_v = 1
    If Abs(angle - ai_angle + pi * 2) < Abs(angle - ai_angle) Then ai_angle_v = -1
  Else
    ai_angle_v = -1
    If Abs(angle - ai_angle - pi * 2) < Abs(angle - ai_angle) Then ai_angle_v = 1
  End If
  If Abs(angle - ai_angle) < .03 Then
    angle = ai_angle
  Else
    angle += ai_angle_v * .03
    If angle < -pi Then angle += pi * 2
    If angle > pi Then angle -= pi * 2
  End If
  
  'perform mode action (main part)
  var enemyconfig = @enemy.config(style)
  Select Case ai_mode
  Case enemy_mode_enum.traveling
    If (x - ai_target_x) * (x - ai_target_x) + (y - ai_target_y) * (y - ai_target_y) < 50 * 50 Then
      ai_cycle_ttl = 0 'enemy has arrived
    End If
    enemy_v = enemy.velocities(style)
  Case enemy_mode_enum.aiming
    If Abs(angle - ai_angle) < .03 Then
      ai_cycle_ttl = 0 'facing in the right direction; it can fire now
    End If
  Case enemy_mode_enum.firing
    Select Case style
    Case enemy_enum.rocker
      If ai_cycle_ttl Mod 20 = 0 Then
        bonus.add(x, y, iif(rnd() < 2, bonus_enum.paddle_destroy, bonus_enum.paddle_shrink), _
          Cos(angle), Sin(angle))
      End If
    Case enemy_enum.speedster
      If ai_cycle_ttl Mod 60 = 5 andalso Rnd() < .5 Then
        d2 = Rnd()
        For i2 As Integer = 1 To enemyconfig->laser_total
          d1 = angle + enemyconfig->laser(i2).angle
          bonus.add(enemyconfig->laser(i2).coord_x(@this), _
            enemyconfig->laser(i2).coord_y(@this), _
            Iif(d2 < .3, bonus_enum.ball_speed, bonus_enum.bonus_score), _
            Cos(d1), Sin(d1))
        Next i2
      End If
    Case enemy_enum.destroyer
      If ai_cycle_ttl Mod 5 = 0 Then
        For i2 As Integer = 1 To enemyconfig->laser_total
          d1 = angle + enemyconfig->laser(i2).angle
          laser.add(enemyconfig->laser(i2).coord_x(@this), _
            enemyconfig->laser(i2).coord_y(@this), _
            Cos(d1) * .5, Sin(d1) * .5, laser_enum.enemy)
        Next i2
      End If
      
      If angle = ai_angle Then
        ai_target_x = brick.field_x2 - ai_target_x
        ai_target_y = brick.field_y2 - ai_target_y
      End If
    Case enemy_enum.scout
      If ai_cycle_ttl Mod 60 = 0 Then
        For i2 As Integer = 1 To enemyconfig->laser_total
          d1 = angle + enemyconfig->laser(i2).angle
          laser.add(enemyconfig->laser(i2).coord_x(@this), _
            enemyconfig->laser(i2).coord_y(@this), _
            Cos(d1) * .5, Sin(d1) * .5, laser_enum.enemy)
        Next i2
      End If
    End Select
  Case enemy_mode_enum.seeking
    enemy_v = enemy.velocities(0)
    
    If Abs(angle - ai_angle) < .03 Then
      ai_cycle_ttl = 0 'facing in the right direction; it can go to the target now
    End If
  End Select
  
  'move: velocity and position
  xv *= .8
  yv *= .8
  If enemy_v <> 0 Then
    xv += Cos(angle) * enemy_v
    yv += Sin(angle) * enemy_v
  End If
  x += xv
  y += yv
  
  'brick collision
  collision_x = x
  collision_y = y
  collision_r = scale * enemy.graphic.enemy_sr
  For i2 As Integer = 1 To brick.total
    With brick.object(i2)
      If .is_explodable() Then
        ballboxcollision(.x1, .y1, .x2, .y2, collision_x, collision_y, collision_r)
        
        'slide brick out of the way
        brick.graphic.erasebrick(brick.object(i2))
        .independant = true
        
        d1 = Atan2(collision_testy - collision_y, collision_testx - collision_x)
        d2 = Cos(d1) * 8
        d3 = Sin(d1) * 8
        .x += d2
        .y += d3
        .x1 += d2
        .y1 += d3
        .x2 += d2
        .y2 += d3
      End If
    End With
  Next i2
  
  'engine particles: add / reset
  If game.frametotal Mod 2 = 0 Then
    For i2 As Integer = -8 To 8
      particle_current += 1
      If particle_current > particle_max Then particle_current = 1
      d1 = (i2 / 8) 'fire curve
      d3 = Sqr(xv * xv + yv * yv) 'enemy / fire speed
      
      For i3 As Integer = 1 To enemyconfig->engine_total
        d2 = angle + enemyconfig->engine(i3).angle + pi 'fire angle
        
        With particle(i3, particle_current)
          .x = enemyconfig->engine(i3).coord_x(@this)
          .y = enemyconfig->engine(i3).coord_y(@this)
          .xv = (Cos(d2) * d3 + Cos(d1 + d2) * enemy.engineparticlespeed)
          .yv = (Sin(d2) * d3 + Sin(d1 + d2) * enemy.engineparticlespeed)
          .c = color_enum.red
        End With
      Next i3
    Next i2
  End If
  
  'engine particles: move
  For i2 As Integer = 1 To enemyconfig->engine_total
    For i3 As Integer = 1 To particle_max
      With particle(i2, i3)
        .x += .xv
        .y += .yv
        If .c > 0 Then .c += &H1000
      End With
    Next i3
  Next i2
End Sub

Sub enemy_object_type.display ()
  #ifndef server_validator
  For i2 As Integer = 1 To enemy.config(style).engine_total
    For i3 As Integer = 1 To particle_max
      With particle(i2, i3)
        If .c > 0 Then Circle (screen.scale_x(.x), screen.scale_y(.y)), screen.scale * enemy.scalefactor_particle, .c,,, 1, f
      End With
    Next i3
  Next i2
  
  multiput(, screen.scale_x(x), screen.scale_y(y), enemy.graphic.enemy(style), _
    this.scale * screen.scale,, angle)
  #endif
End Sub

sub enemy_object_type.damage (smashes as double)
  'shrinks enemy
  'for reference, smashes = 1 for ball collisions
  scale_target -= enemy.killfactor * enemy.scalefactor * smashes / value
end sub

property enemy_object_type.missileresistance () as integer
  return enemy.missileresistance(style)
end property
