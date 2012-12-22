
sub laser_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  laser.gfxchange()
end sub

Sub laser_type.start ()
  graphic.start()
End Sub

Sub laser_type.reset ()
  power = 0
  launchload = 0
  total = 0
End Sub

Sub laser_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub laser_type.add (Byval x As Double, Byval y As Double, Byval xv As Double, Byval yv As Double, _
  Byval style As laser_enum = laser_enum.player)
  
  If total = max Then Exit Sub
  total += 1
  
  sound.add(sound_enum.laser_create)
  
  With object(total)
    .x = x
    .y = y
    .xv = xv * speed
    .yv = yv * speed
    .style = style
    .angle = Atan2(yv, xv)
    .killme = false
  End With
End Sub

Sub laser_type.move ()
  Dim As Integer a, x, y
  Dim As Double d1, d2
  
  'add a laser
  launchload += power * .02
  
  If game.frametotal Mod 3 = 0 And laser.launchload > paddle.total * 2 Then
    For i As Integer = 1 To paddle.total
      With paddle.object(i)
        If game.control(.owner).click Then
          laser.launchload -= 2
          
          Select Case .side
          Case paddle_side_enum.top
            add(.x1 + (.x2 - .x1) * .2, .y2, 0, 1)
            add(.x1 + (.x2 - .x1) * .8, .y2, 0, 1)
          Case paddle_side_enum.bottom
            add(.x1 + (.x2 - .x1) * .2, .y1, 0, -1)
            add(.x1 + (.x2 - .x1) * .8, .y1, 0, -1)
          Case paddle_side_enum.left
            add(.x2, .y1 + (.y2 - .y1) * .2, 1, 0)
            add(.x2, .y1 + (.y2 - .y1) * .8, 1, 0)
          Case paddle_side_enum.right
            add(.x1, .y1 + (.y2 - .y1) * .2, -1, 0)
            add(.x1, .y1 + (.y2 - .y1) * .8, -1, 0)
          Case paddle_side_enum.center
            'left
            add(.x2, .y1 + (.y2 - .y1) * .2, 1, 0)
            add(.x2, .y1 + (.y2 - .y1) * .8, 1, 0)
            'right
            add(.x1, .y1 + (.y2 - .y1) * .2, -1, 0)
            add(.x1, .y1 + (.y2 - .y1) * .8, -1, 0)
          End Select
        End If
      End With
    Next i
  End If
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  a = 1
  While a <= total
    If object(a).killme Then
      object(a) = object(total)
      total -= 1
    Else
      a += 1
    End If
  Wend
End Sub

Sub laser_type.display ()
  #ifndef server_validator
  for i as integer = total to 1 step -1
    object(i).display()
  next i
  #Endif
End Sub

Sub laser_type.finish ()
  graphic.finish()
End Sub

Sub laser_graphic_type.start ()
  #ifndef server_validator
  bullet = utility.createimage(bullet_sx, bullet_sy mop("bullet"))
  laser = utility.createimage(laser_sx, laser_sy mop("laser"))
  #Endif
End Sub

Sub laser_graphic_type.gfxchange ()
  #ifndef server_validator
  utility.loadimage(main.levelpack.gfxset + "/bullet", bullet)
  utility.loadimage(main.levelpack.gfxset + "/laser", laser)
  #Endif
End Sub

Sub laser_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(bullet mop("bullet"))
  utility.deleteimage(laser mop("laser"))
  #Endif
End Sub

sub laser_object_type.move ()
  dim as integer tempx, tempy
  dim as double d1, d2
  
  x += xv
  y += yv
  
  tempx = x 'performance
  tempy = y
  
  If style = laser_enum.player Then
    'collide with bricks
    var thisbrick = @brick.object(1) - 1
    var lastbrick = iif(brick.total < 1, thisbrick, @brick.object(brick.total))
    while thisbrick < lastbrick
      thisbrick += 1
      If tempx >= thisbrick->x1 then
        if tempx <= thisbrick->x2 Then
          If tempy >= thisbrick->y1 And tempy <= thisbrick->y2 Then
            with *thisbrick
              xfx.particle.add(tempx, tempy)
              If .is_explodable() Then
                .awardpoints = true
                .hit_bonusball = 0
                .hit_shadow_xv = xv
                .hit_shadow_yv = yv
                .hit_shadow_spin = Sgn(.xv)
                If .hit_shadow_spin = 0 Then .hit_shadow_spin = Sgn(Rnd() - Rnd())
                .killme = true
              End If
              killme = true
            end with
          End If
        End If
      end if
    wend
    
    'collide with enemies
    For i2 As Integer = 1 To enemy.total
      With enemy.object(i2)
        If (tempx - .x) * (tempx - .x) + (tempy - .y) * (tempy - .y) < _
          (.scale * .scale) * (enemy.graphic.enemy_sr * enemy.graphic.enemy_sr) Then
          
          sound.add(sound_enum.thud)
          .damage(1 / .missileresistance)
          killme = true
        End If
      End With
    Next i2
    
    'collide with items
    var thisitem = @item.object(1) - 1
    var lastitem = iif(item.total < 1, thisitem, @item.object(item.total))
    while thisitem < lastitem
      thisitem += 1
      If (tempx - thisitem->x) * (tempx - thisitem->x) + (tempy - thisitem->y) * (tempy - thisitem->y) > _
        (thisitem->scale * thisitem->scale) * (item.graphic.item_sr * item.graphic.item_sr) Then continue while
      
      With *thisitem
        Select Case .style
        Case item_enum.bonusbutton
          sound.add(sound_enum.thud)
          If .d_temp = 0 Then
            If .d = 0 Then .d = 1 Else .d Shl= 1
            .d_temp = .d
            
            bonus.add(x, y, bonus_enum.bonus_score, 0, 0, 0)
          Else
            .d_temp -= 1
          End If
          killme = true
        Case item_enum.brickmachine
          killme = true
        Case item_enum.portal
          If .d > 0 Then
            var gotoportal = @item.object(.d)
            sound.add(sound_enum.portal_collide)
            d1 = Sqr(xv * xv + yv * yv)
            d2 = Rnd() * 2 * pi
            xv = Cos(d2) * d1
            yv = Sin(d2) * d1
            angle = Atan2(yv, xv)
            x = gotoportal->x + Cos(d2) * item.graphic.item_sr * gotoportal->scale
            y = gotoportal->y + Sin(d2) * item.graphic.item_sr * gotoportal->scale
          End If
        End Select
      End With
    wend
  End If
  
  If style = laser_enum.enemy Then
    'collide with orb
    For i2 As Integer = 1 To orb.total
      With orb.object(i2)
        If (tempx - .x) * (tempx - .x) + (tempy - .y) * (tempy - .y) < _
          (.scale * .scale) * (.size * .size) Then
          
          .lives -= 1
          killme = true
        End If
      End With
    Next i2
    
    'collide with paddles
    For i2 As Integer = 1 To paddle.total
      With paddle.object(i2)
        If tempx >= .x1 And tempx <= .x2 Then
          If tempy >= .y1 And tempy <= .y2 Then
            sound.add(sound_enum.thud)
            .lives -= 1
            killme = true
          End If
        End If
      End With
    Next i2
  End If
  
  'clipping
  If tempx > screen.default_sx * 1.1 then killme = true
  if tempx < -screen.default_sx * .1 then killme = true
  if tempy > screen.default_sy + screen.default_sx * .1 then killme = true
  if tempy < -screen.default_sx * .1 Then killme = true
end sub

sub laser_object_type.display ()
  #ifndef server_validator
  If setting.bullettextures Then
    multiput(, screen.scale_x(x + xfx.camshake.x), screen.scale_y(y + xfx.camshake.y), _
      laser.graphic.bullet, screen.scale * laser.sizefactor,, angle)
  else
    Circle (screen.scale_x(x + xfx.camshake.x), screen.scale_y(y + xfx.camshake.y)), _
      4 * screen.scale * laser.sizefactor, color_enum.black,,, 1, F
  end if
  #endif
end sub
