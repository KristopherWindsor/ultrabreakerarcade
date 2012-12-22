
sub bonus_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  bonus.gfxchange()
end sub

Sub bonus_type.start ()
  graphic.start()
End Sub

Sub bonus_type.reset ()
  total = 0
End Sub

Sub bonus_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub bonus_type.reset2 ()
  graphic.gfxreset()
End Sub

Sub bonus_type.add (x As double, y As double, Byval style As bonus_enum, _
  Byval xv As Double, Byval yv As Double, _
  Byval brickscale As Double = 0, Byval parentball As Integer = 0)
  
  If total = max Then Exit Sub
  total += 1
  
  With object(total)
    .style = style
    
    .x = x
    .y = y
    .xv = xv * speed
    .yv = yv * speed
    .x_original = x
    .y_original = y
    
    .data_brickscale = brickscale
    .data_parentball = parentball
    
    .maxalpha = 0
    
    .killme = false
  End With
End Sub

Sub bonus_type.move ()
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

Sub bonus_type.display ()
  #ifndef server_validator
  Dim As fb.image Ptr g
  
  For i As Integer = bonus.total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub bonus_type.finish ()
  graphic.finish()
End Sub

Sub bonus_graphic_type.start ()
  #ifndef server_validator
  For i As Integer = bonus_enum.min To bonus_enum.max
    bonus(i) = utility.createimage(bonus_sd, bonus_sd mop("bonus"))
  Next i
  #Endif
End Sub

Sub bonus_graphic_type.gfxchange ()
  #ifndef server_validator
  For i As Integer = bonus_enum.min To bonus_enum.max
    utility.loadimage(main.levelpack.gfxset + "/bonuses/" & i, bonus(i))
  Next i
  #Endif
End Sub

Sub bonus_graphic_type.gfxreset ()
  'scales bonuses down to minis (only needed if gfx or screensize changes)
  
  #ifndef server_validator
  Static As Double check_screenscale
  Static As String check_gfxset
  
  If main.levelpack.gfxset = check_gfxset And _
    screen.scale = check_screenscale Then Exit Sub
  
  check_gfxset = main.levelpack.gfxset
  check_screenscale = bonus_type.sizefactor * screen.scale
  
  For i As Integer = bonus_enum.min To bonus_enum.max
    If minis(i) > 0 Then utility.deleteimage(minis(i) mop("bonus mini"))
    minis(i) = utility.createimage(bonus_sd * check_screenscale, bonus_sd * check_screenscale mop("bonus mini"))
    image_scaler(minis(i), 0, 0, bonus(i), check_screenscale)
  Next i
  #Endif
End Sub

Sub bonus_graphic_type.finish ()
  #ifndef server_validator
  For i As Integer = bonus_enum.min To bonus_enum.max
    utility.deleteimage(bonus(i) mop("bonus"))
    If minis(i) > 0 Then utility.deleteimage(minis(i) mop("bonus"))
  Next i
  #Endif
End Sub

sub bonus_object_type.move ()
  Dim As Integer a, collected, collected_paddle
  Dim As Integer collision_x, collision_y, collision_testx, collision_testy
  Dim As Double v
  
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
  
  If yv < game.gravitymax Then yv += game.gravityfactor
  
  'don't get solid until velocity = 2
  v = xv * xv + yv * yv
  a = 255
  If v < 4 Then a *= v / 4
  If a > maxalpha Then maxalpha = a
  
  x += xv
  y += yv
  
  'set collision variables
  collision_x = x
  collision_y = y
  collected = false
  
  'orb collision
  For i2 As Integer = 1 To orb.total
    With orb.object(i2)
      If Sqr((.x - collision_x) * (.x - collision_x) + (.y - collision_y) * (.y - collision_y)) < _
        bonus_graphic_type.bonus_sr + .scale * .size Then
        
        If style = bonus_enum.paddle_destroy Or _
          style = bonus_enum.paddle_create Or _
          style = bonus_enum.ball_bonus Or _
          style = bonus_enum.ball_bonus_double Then
          
          xv = 0
          yv = -game.gravitymax
        Else
          'note: collected paddle won't matter
          collected = true
        End If
      End If
    End With
  Next i2
  
  'see if player caught bonus
  For i2 As Integer = 1 To paddle.total
    With paddle.object(i2)
      ballboxcollision(.x1, .y1, .x2, .y2, collision_x, collision_y, _
        bonus_graphic_type.bonus_sr * bonus.sizefactor)
      
      collected = true
      collected_paddle = i2
    End With
  Next i2
  
  'apply collected bonus
  If collected Then
    game.tracker_bonuscollect = game.frametotal
    game.tracker_bonustitle = bonus.title(style)
    
    sound.add(sound_enum.bonus_collect)
    
    If data_parentball = 0 Then data_parentball = Int(Rnd() * ball.total) + 1
    
    Select Case style
    Case bonus_enum.bonus_score
      game.result.scoregained = game.result.scoregained + 100
    Case bonus_enum.bonus_time
      With game.setting
        .timelimit += 60 * game.fps
        If .timelimit > game.timemax * game.fps Then .timelimit = game.timemax * game.fps
      End With
    Case bonus_enum.bonus_life
      game.result.livesgained += 1
    Case bonus_enum.levelup
      game.data_collected_levelup = true
    Case bonus_enum.gravity
      gravity.add(x_original, y_original, data_brickscale * gravity.scalefactor_bonus)
    Case bonus_enum.ball_bonus
      a = data_parentball
      If a > 0 Then ball.duplicate(a)
    Case bonus_enum.ball_bonus_double
      ball.add(collected_paddle, ball.total)
    Case bonus_enum.ball_big
      For i2 As Integer = 1 To ball.total
        With ball.object(i2)
          .scale *= Sqr(2)
          If .scale > ball.scalemax Then .scale = ball.scalemax
          .fixstuckposition()
        End With
      Next i2
    Case bonus_enum.ball_small
      For i2 As Integer = 1 To ball.total
        With ball.object(i2)
          .scale /= Sqr(2)
          If .scale < ball.scalemin Then .scale = ball.scalemin
          .fixstuckposition()
        End With
      Next i2
    Case bonus_enum.ball_speed
      For i2 As Integer = 1 To ball.total
        With ball.object(i2)
          .xv *= Sqr(2)
          .yv *= Sqr(2)
        End With
      Next i2
    Case bonus_enum.ball_slow
      For i2 As Integer = 1 To ball.total
        With ball.object(i2)
          .xv /= Sqr(2)
          .yv /= Sqr(2)
        End With
      Next i2
    Case bonus_enum.ball_fire
      For i2 As Integer = 1 To ball.total
        ball.object(i2).style = ball_enum.fire
      Next i2
    Case bonus_enum.make_explode_brick
      For i As Integer = 1 To brick.total
        with brick.object(i)
          If Abs(.x - x_original) <= (.scale + data_brickscale) * _
            brick.graphic.brick_sx * 2 + 1 Then
            
            If Abs(.y - y_original) <= (.scale + data_brickscale) * _
              brick.graphic.brick_sy * 2 + 1 Then
              
              If .is_normal() Then
                brick.graphic.erasebrick(brick.object(i)) 'have to erase the old one in case the new one is semi-transparent
                .style = brick_enum.explode
                brick.graphic.redrawbrick(brick.object(i))
              End If
            End If
          End If
        end with
      Next i
    Case bonus_enum.make_normal_brick
      'only convert the invincible bricks (to let the ball get in somewhere)
      For i As Integer = 1 To brick.total
        with brick.object(i)
          If Abs(.x - x_original) <= (.scale + data_brickscale) * _
            brick.graphic.brick_sx * 2 + 1 Then
            
            If Abs(.y - y_original) <= (.scale + data_brickscale) * _
              brick.graphic.brick_sy * 2 + 1 Then
              
              If .style = brick_enum.invincible Then
                brick.graphic.erasebrick(brick.object(i)) 'have to erase the old one in case the new one is semi-transparent
                .style = brick_enum.normal
                .value = brick.value_convertedtonormal
                brick.graphic.redrawbrick(brick.object(i))
              End If
            End If
          End If
        end with
      Next i
    Case bonus_enum.paddle_grow
      paddle.set_scale(paddle.data_scale * 1.1)
    Case bonus_enum.paddle_shrink
      paddle.set_scale(paddle.data_scale / 1.1)
    Case bonus_enum.paddle_destroy
      paddle.object(collected_paddle).lives -= paddle.lives_rockloss
    Case bonus_enum.paddle_laser
      laser.power += 1
      If laser.power = 1 Then paddle.graphic.gfxreset()
    Case bonus_enum.paddle_stick
      paddle.data_sticky = true
    Case bonus_enum.paddle_super
      For i As Integer = 1 To paddle.total
        paddle.object(i).style = paddle_enum.super
      Next i
    Case bonus_enum.paddle_rapidfire
      game.data_rapidfire += 1
    Case bonus_enum.paddle_create
      For i As Integer = 1 To paddle_side_enum.max
        If paddle.quantities(i) > 0 Then paddle.add(i)
      Next i
    Case bonus_enum.orb
      With game.result
        .orbtokens += 1
        If .orbtokens >= game.orbprice and orb.total < orb.max Then
          .orbtokens -= game.orbprice
          orb.add()
        End If
      End With
    End Select
    
    killme = true
  End If
  
  If y - bonus_graphic_type.bonus_sr > screen.default_sy Then killme = true
end sub

sub bonus_object_type.display ()
  #ifndef server_validator
  dim as fb.image ptr g = bonus.graphic.minis(style)
  
  Put (screen.scale_x(x + xfx.camshake.x) - g->width Shr 1, _
    screen.scale_y(y + xfx.camshake.y) - g->height Shr 1), g, alpha, maxalpha
  #endif
end sub
