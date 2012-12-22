
sub brick_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  brick.gfxchange()
end sub

Sub brick_type.screenchange ()
  graphic.screenchange()
End Sub

Sub brick_type.reset ()
  iscleared = false
  field_x1 = 0
  field_y1 = 0
  field_x2 = screen.default_sx - 1
  field_y2 = screen.default_sy * .8 - 1
  total = 0
End Sub

Sub brick_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub brick_type.reset2 ()
  Dim As Integer v
  
  For i As Integer = 1 To total
    v += object(i).value
  Next i
  ballspeedup = cInt(v * .5)
  
  graphic.gfxreset()
End Sub

Sub brick_type.add (Byval x As Double, Byval y As Double, _
  Byval style As brick_enum, Byval scale As Double, Byval value As Integer, _
  Byval xv As Integer = 0, Byval yv As Integer = 0, _
  Byval independant As Integer = false, Byval replicating As Integer = false, _
  Byval autoexplode As Integer = 0)
  
  'scale = 1 for a brick that appears at the original size (defined by png) at the default screen size
  
  If total = max Then Exit Sub
  
  total += 1
  If game.frametotal > 0 Then sound.add(sound_enum.brickgravity_create)
  
  With object(total)
    .x = x
    .y = y
    .scale = scale
    .style = style
    .value = Iif(.is_explodable(), value, 0)
    .awardpoints = false
    
    .delay_explode = Iif(autoexplode < 0, 1, autoexplode * 120) 'autoexplode is in seconds

    .replication = 0
    If style = brick_enum.replicating Or replicating Then .replication = value - 1
    
    .graphic_mini = 0
    
    'moving invincible bricks
    If style = brick_enum.invincible_bouncy Then
      .bouncy = true
      
      .xv = Iif(value Mod 2 = 0, -speed_moving, speed_moving)
      .yv = 0
      .independant = true
    Else
      .bouncy = false
      
      .xv = xv
      .yv = yv
      .independant = independant
    End If
    
    .hit_bonusball = 0
    .hit_shadow_xv = 0
    .hit_shadow_yv = 0
    .hit_shadow_spin = 0
    If autoexplode <> 0 Then
      .hit_shadow_xv = xfx.flyingbrick.speed * Sgn(x - screen.default_sx \ 2)
      .hit_shadow_spin = Sgn(.hit_shadow_xv)
    End If
    
    .x1 = x - scale * .5 * graphic.brick_sx
    .x2 = x + scale * .5 * graphic.brick_sx
    .y1 = y - scale * .5 * graphic.brick_sy
    .y2 = y + scale * .5 * graphic.brick_sy
    
    .killme = false
  End With
End Sub

Sub brick_type.move ()
  'terminate bricks, add bonuses, handle some special effects (like bomb bricks)
  
  Dim As Integer a, didkill, v_remaining
  Dim As Double angle
  
  'game.frametotal & " " & total & "  " & ball.total & "  " & brick.object(1).killme
  For i As Integer = 1 To total
    With object(i)
      .move()
      if .killme = false then v_remaining += .value
    End With
  Next i
  
  a = 1
  While a <= total
    If object(a).killme Then
      didkill = true
      object(a).cleanup()
      
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
  
  If didkill Then
    'speed up ball when level is 50% done
    If v_remaining <= ballspeedup And ballspeedup > 0 Then
      ballspeedup = 0
      
      For i As Integer = 1 To ball.total
        With ball.object(i)
          .xv *= Sqr(2)
          .yv *= Sqr(2)
        End With
      Next i
    End If
    
    'cleared flag for determining level completion
    If iscleared = false Then
      iscleared = true
      For i As Integer = 1 To total
        If object(i).is_explodable() Then
          iscleared = false
          Exit For
        End If
      Next i
    End If
    
    'Shooter mode triggered 
    If iscleared And game.setting.special_shooter And game.mode_shooter = false Then
      If total = 0 Then
        With game.setting
          game.mode_shooter = true
          sound.add(sound_enum.shootermode)
          
          .special_noballlose = true
          .special_nobrickwin = true
          
          laser.power += laser.powerbonus_shootermode
          If laser.power = laser.powerbonus_shootermode Then paddle.graphic.gfxreset()
        End With
      Else
        For i As Integer = 1 To total
          graphic.erasebrick(object(i)) 'have to erase the old one in case the new one is semi-transparent
          object(i).style = brick_enum.normal
          object(i).value = value_convertedtonormal
          graphic.redrawbrick(object(i))
        Next i
        iscleared = false
      End If
    End If
  End If
End Sub

Sub brick_type.display ()
  'show background images
  
  #ifndef server_validator
  Static As Integer shooter_startframe
  
  Dim As Integer alpha, f, s
  
  With game.framerate
    f = Int(brick_graphic_type.frame_ratefactor * .loop_total / .fps_loop) Mod 6 + 1
  End With
  
  alpha = setting.alphavalue
  If weather.is_metal Or game.mode_invertedcolors Or game.mode_pixelation Or _
    game.video.isStarted Then alpha = 255
  
  If game.mode_shooter Then
    'v-scrolling
    
    If shooter_startframe = 0 Then shooter_startframe = game.framerate.loop_total
    s = (game.framerate.loop_total - shooter_startframe) * scrollspeed * _
      screen.scale Mod screen.screen_sy
    
    Put (xfx.camshake.x * screen.scale, _
      s + xfx.camshake.y * screen.scale - screen.screen_sy + 1), _
      graphic.brickset(1), alpha, alpha
    Put (xfx.camshake.x * screen.scale, _
      s + xfx.camshake.y * screen.scale), _
      graphic.brickset(1), alpha, alpha
  Else
    shooter_startframe = 0
    
    'normal mode
    Put (xfx.camshake.x * screen.scale, xfx.camshake.y * screen.scale), _
      graphic.brickset(f), alpha, alpha
  End If
  
  For i As Integer = 1 To total
    With object(i)
      If .independant Then
        Put (screen.scale_x(.x1 + xfx.camshake.x), _
          screen.scale_y(.y1 + xfx.camshake.y)), _
          graphic.mini(.graphic_mini).b.g(f), trans
      End If
    End With
  Next i
  #Endif
End Sub

Sub brick_type.finish ()
  brick.graphic.finish()
End Sub

Sub brick_type.replicate (Byref ibrick as brick_object_type)
  Dim As Integer px, py
  
  With ibrick
    For x As Integer = -1 To 1 Step 2
      For y As Integer = -1 To 1 Step 2
        px = .x + x * graphic.brick_sx * .scale * .value
        py = .y + y * graphic.brick_sy * .scale * .value
        If px > screen.default_sx * .1 And py > screen.default_sy * .1 And _
          px < screen.default_sx * .9 And py < screen.default_sy * .9 Then
          
          add(px, py, .style, .scale, .value - 1,,, true, true)
        End If
        graphic.set_mini(object(total))
      Next y
    Next x
  End With
End Sub

Sub brick_graphic_brick_type.cleanup ()
  #ifndef server_validator
  If g(1) = 0 Then Exit Sub
  
  Select Case total
  Case -1
    For i As Integer = 1 To 3
      utility.deleteimage(g(i) mop("brick"))
    Next i
  Case 0, 1
    utility.deleteimage(g(1) mop("brick"))
  Case 2
    utility.deleteimage(g(1) mop("brick"))
    utility.deleteimage(g(4) mop("brick"))
  Case 3
    utility.deleteimage(g(1) mop("brick"))
    utility.deleteimage(g(3) mop("brick"))
    utility.deleteimage(g(5) mop("brick"))
  Case 6
    For i As Integer = 1 To 6
      utility.deleteimage(g(i) mop("brick"))
    Next i
  End Select
  
  For i As Integer = 1 To 6
    g(i) = 0
  Next i
  #Endif
End Sub

Sub brick_graphic_type.screenchange ()
  #ifndef server_validator
  'create images for backgrounds
  
  If background > 0 Then utility.deleteimage(background mop("background"))
  background = utility.createimage(screen.view_sx, screen.view_sy mop("background"))
  For i As Integer = 1 To frame_max
    If brickset(i) > 0 Then utility.deleteimage(brickset(i) mop("brickset"))
    brickset(i) = utility.createimage(screen.screen_sx, screen.screen_sy mop("brickset"))
  Next i
  #Endif
End Sub

Sub brick_graphic_type.gfxchange ()
  #ifndef server_validator
  'load the graphic set
  
  Dim As Integer a, f
  Dim As Integer anim(1 To brick_enum.max)
  Dim As String l
  
  f = utility.openfile("data/graphics/" + main.levelpack.gfxset + "/bricks/frames.txt", utility_file_mode_enum.for_input)
  While Not Eof(f)
    Do
      Line Input #f, l
    Loop Until Left(l, 2) <> "//"
    
    a = Instr(l, " ")
    anim(Val(Left(l, a - 1))) = Val(Mid(l, a + 1))
  Wend
  Close #f
  
  For i As Integer = 1 To brick_enum.max
    With brick(i)
      .cleanup() 'delete brick gfx from previous set
      
      l = main.levelpack.gfxset + "/bricks/" + Right("0" + Str(i), 2) + "/"
      
      f = anim(i)
      If f <> -1 And f <> 1 And f <> 2 And f <> 3 And f <> 6 Then f = 0
      .total = f
      
      Select Case f
      Case -1
        For i2 As Integer = 1 To 3
          .g(i2) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
          utility.loadimage(l & i2, .g(i2))
          .g(7 - i2) = .g(i2)
        Next i2
      Case 0
        .g(1) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
        Line .g(1), (0, 0) - (brick_sx - 1, brick_sy - 1), color_enum.gray, BF
        For i2 As Integer = 2 To 6
          .g(i2) = .g(1)
        Next i2
      Case 1
        .g(1) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
        utility.loadimage(l & 1, .g(1))
        For i2 As Integer = 2 To 6
          .g(i2) = .g(1)
        Next i2
      Case 2
        For i2 As Integer = 1 To 6 Step 3
          .g(i2) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
          utility.loadimage(l & ((i2 + 2) \ 3), .g(i2))
          .g(i2 + 1) = .g(i2)
          .g(i2 + 2) = .g(i2)
        Next i2
      Case 3
        For i2 As Integer = 1 To 6 Step 2
          .g(i2) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
          utility.loadimage(l & ((i2 + 1) Shr 1), .g(i2))
          .g(i2 + 1) = .g(i2)
        Next i2
      Case 6
        For i2 As Integer = 1 To 6
          .g(i2) = utility.createimage(brick_sx, brick_sy mop("brick fullsize"))
          utility.loadimage(l & i2, .g(i2))
        Next i2
      End Select
    End With
  Next i
  #Endif
End Sub

Sub brick_graphic_type.gfxreset ()
  'load background, minis, and brickset
  
  #ifndef server_validator
  Static As Integer previous_tile_state, previous_color, previous_hicontrast
  Static As Integer previous_sx, previous_sy
  Static As String previous_gfxset, previous_background
  
  Dim As Integer mini_current, pitch, step_x, step_y, weight
  Dim As Double scale_x, scale_y
  Dim As Uinteger Ptr dp
  Dim As fb.image Ptr tg, tg_scaled
  
  If previous_tile_state <> game.setting.gfx_background_tile Or _
    previous_color <> game.setting.gfx_background_color Or _
    previous_hicontrast <> setting.hicontrast Or _
    previous_gfxset <> main.levelpack.gfxset Or _
    previous_background <> game.setting.gfx_background_image Or _
    previous_sx <> screen.screen_sx Or previous_sy <> screen.screen_sy Then
    
    Line background, (0, 0) - (background->width - 1, background->height - 1), _
      game.setting.gfx_background_color, BF
    
    'all the loading time is spent right here:
    If Len(game.setting.gfx_background_image) > 0 Then
      tg = png_load("data/graphics/" & main.levelpack.gfxset + "/backgrounds/" & game.setting.gfx_background_image & ".png", PNG_TARGET_FBNEW)
      
      If tg = 0 Then
        'tg = utility.createimage(32, 32 mop("tg"), game.setting.gfx_background_color)
        utility.logerror("Cannot load background image: " & game.setting.gfx_background_image)
      else
        If game.setting.gfx_background_tile Then
          step_x = (tg -> Width) * screen.scale
          step_y = (tg -> height) * screen.scale
          
          If step_x > 0 And step_y > 0 Then
            tg_scaled = utility.createimage(step_x, step_y mop("tg scaled"))
            image_scaler(tg_scaled,,, tg, screen.scale)
            For x As Integer = 0 To screen.view_sx + step_x - 1 Step step_x
              For y As Integer = 0 To screen.view_sy + step_y - 1 Step step_y
                Put background, (x, y), tg_scaled, Pset
              Next y
            Next x
          End If
          
          utility.deleteimage(tg_scaled mop("tg scaled"))
        Else
          scale_x = screen.view_sx / (tg -> Width)
          scale_y = screen.view_sy / (tg -> height)
          If scale_x = 1 And scale_y = 1 Then
            Put background, (0, 0), tg, Pset
          Else
            If scale_x < scale_y Then scale_x = scale_y
            image_scaler(background,,, tg, scale_x)
          End If
        End If
        imagedestroy(tg)
      End If
    End If
    
    If setting.hicontrast Then
      tg = utility.createimage(screen.view_sx, screen.view_sy mop("tg hc"), color_enum.white)
      Put background, (0, 0), tg, alpha, 127
      utility.deleteimage(tg mop("tg hc"))
      
      dp = cast(Uinteger Ptr, background + 1)
      pitch = (background -> pitch) Shr 2
      For y As Integer = 0 To screen.view_sy - 1
        For x As Integer = 0 To screen.view_sx - 1
          weight = *(dp + x)
          weight = ((weight And &HFF) + ((weight And &HFF00) Shr 8) + ((weight And &HFF0000) Shr 16)) \ 3
          *(dp + x) = weight * &H010101
        Next x
        dp += pitch
      Next y
    End If
  End If
  
  While mini_total > 0
    mini(mini_total).b.cleanup()
    mini_total -= 1
  Wend
  
  For i As Integer = 1 To frame_max
    Line brickset(i), (0, 0) - (screen.screen_sx - 1, screen.screen_sy - 1), color_enum.black, BF
    Put brickset(i), (screen.corner_sx, screen.corner_sy), background, Pset
    
    'draw bricks (all bricks defined at this point are not moving)
    For i2 As Integer = 1 To ..brick.total
      set_mini(..brick.object(i2))
      With ..brick.object(i2)
        If .independant Then Continue For
        'multiput(brickset(i), .x * screen.scale + screen.corner_sx, _
        '  .y * screen.scale, brick_graphic.brick(brick_object(i2).style, i), .scale * screen.scale,,, true)
        'image_scaler(brickset(i), _
        '  .x * screen.scale + screen.corner_sx - brick_graphic.brick_sx * .scale * screen.scale * .5, _
        '  .y * screen.scale + screen.corner_sy - brick_graphic.brick_sy * .scale * screen.scale * .5, _
        '  brick_graphic.brick(brick_object(i2).style, i), .scale * screen.scale)
        Put brickset(i), (screen.scale_x(.x1), screen.scale_y(.y1)), _
          mini(.graphic_mini).b.g(i), trans
      End With
    Next i2
  Next i
  
  'assert: if there is a make_normal or make_explode brick, then some new brick types will be made
  'so make those minis now, not in the middle of the game
  Dim As brick_object_type temp
  For i As Integer = 1 To ..brick.total
    If ..brick.object(i).style = bonus_enum.make_explode_brick Then
      temp.style = brick_enum.explode
      
      'make gfx for bricks that could become exploding, or invincible -> normal -> explodable
      For j As Integer = 1 To ..brick.total
        If ..brick.object(j).is_normal() Or ..brick.object(j).style = brick_enum.invincible Then
          temp.scale = ..brick.object(j).scale
          set_mini(temp)
        End If
      Next j
      
      Exit For
    End If
  Next i
  For i As Integer = 1 To ..brick.total
    If ..brick.object(i).style = bonus_enum.make_normal_brick Then
      temp.style = brick_enum.normal
      
      'make gfx for bricks that could become normal
      For j As Integer = 1 To ..brick.total
        If ..brick.object(j).style = brick_enum.invincible Then
          temp.scale = ..brick.object(j).scale
          set_mini(temp)
        End If
      Next j
      
      Exit For
    End If
  Next i
  
  previous_tile_state = game.setting.gfx_background_tile
  previous_color = game.setting.gfx_background_color
  previous_hicontrast = setting.hicontrast
  previous_gfxset = main.levelpack.gfxset
  previous_background = game.setting.gfx_background_image
  previous_sx = screen.screen_sx
  previous_sy = screen.screen_sy
  #Endif
End Sub

Sub brick_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(background mop("background"))
  
  While mini_total > 0
    mini(mini_total).b.cleanup()
    mini_total -= 1
  Wend
  
  For i As Integer = 1 To frame_max
    utility.deleteimage(brickset(i) mop("brickset"))
  Next i
  
  For x As Integer = 1 To brick_enum.max
    brick(x).cleanup()
  Next x
  #Endif
End Sub

Sub brick_graphic_type.erasebrick (Byref ibrick as brick_object_type)
  'remove one brick from the brickset gfx
  #ifndef server_validator
  
  'coords 1 used for both parts; coords 2 used for redraw clipping
  Dim As Integer x1, y1, x2, y2
  
  'display coords; determine if the background color has to be redrawn (if the brick is off the background)
  Dim As Integer bx1, by1, bx2, by2, box1, boy1, box2, boy2
  
  'for redrawing
  Dim As Integer qx1, qy1, qx2, qy2
  Dim As Integer sx1, sy1, sx2, sy2, tx, ty
  
  With ibrick
    If .independant Then Exit Sub
    
    x1 = screen.scale_x(.x1)
    y1 = screen.scale_y(.y1)
    x2 = x1 + (mini(.graphic_mini).b.g(1) -> Width) - 1
    y2 = y1 + (mini(.graphic_mini).b.g(1) -> height) - 1
    
    box1 = x1 - screen.corner_sx: bx1 = box1
    boy1 = y1 - screen.corner_sy: by1 = boy1
    box2 = bx1 + (mini(.graphic_mini).b.g(1) -> Width) - 1: bx2 = box2
    boy2 = by1 + (mini(.graphic_mini).b.g(1) -> height) - 1: by2 = boy2
    
    'change x1 and y1 when b* coords change
    If bx1 < 0 Then bx1 = 0
    If by1 < 0 Then by1 = 0
    If bx2 >= (background -> Width) Then bx2 = (background -> Width) - 1
    If by2 >= (background -> height) Then by2 = (background -> height) - 1
    
    For i As Integer = 1 To frame_max
      If  bx1 <> box1 Or by1 <> boy1 Or bx2 <> box2 Or by2 <> boy2 Then
        Line brickset(i), (x1, y1) - Step(box2 - box1, boy2 - boy1), game.setting.gfx_background_color, BF
      End If
      Put brickset(i), (x1 + bx1 - box1, y1 + by1 - boy1), background, (bx1, by1) - (bx2, by2), Pset
    Next i
    
    For i As Integer = 1 To ..brick.total
      If @ibrick = @(..brick.object(i)) Then Continue For
      
      With ..brick.object(i)
        If .independant Then Continue For
        
        qx1 = screen.scale_x(.x1)
        qx2 = qx1 + mini(.graphic_mini).b.g(1) -> Width - 1
        qy1 = screen.scale_y(.y1)
        qy2 = qy1 + mini(.graphic_mini).b.g(1) -> height - 1
        
        If ((x1 >= qx1 And x1 <= qx2) Or (x2 >= qx1 And x2 <= qx2) Or _
          (qx1 >= x1 And qx1 <= x2) Or (qx2 >= x1 And qx2 <= x2)) And _
          ((y1 >= qy1 And y1 <= qy2) Or (y2 >= qy1 And y2 <= qy2) Or _
          (qy1 >= y1 And qy1 <= y2) Or (qy2 >= y1 And qy2 <= y2)) Then
          
          'only redraw the part of brick(i2) within the area (x1, y1) - (x2, y2)
          
          'setup assuming you will redraw all of brick(i2)
          sx1 = 0 'source
          sy1 = 0
          sx2 = qx2 - qx1
          sy2 = qy2 - qy1
          tx = qx1 'target
          ty = qy1
          
          'clip the drawing to stay in a certain part of the target ((x1, y1) - (x2, y2))
          If tx < x1 Then
            sx1 += x1 - tx
            tx = x1
          End If
          If ty < y1 Then
            sy1 += y1 - ty
            ty = y1
          End If
          If tx + (sx2 - sx1) > x2 Then sx2 = x2 - tx + sx1
          If ty + (sy2 - sy1) > y2 Then sy2 = y2 - ty + sy1
          
          For i2 As Integer = 1 To frame_max
            Put brickset(i2), (tx, ty), mini(.graphic_mini).b.g(i2), (sx1, sy1) - (sx2, sy2), trans
          Next i2
        End If
      End With
    Next i
  End With
  #Endif
End Sub

Sub brick_graphic_type.redrawbrick (Byref ibrick as brick_object_type)
  'the scale or style changed
  'note: the brick has already been erased
  'redraw brick, then redraw overlapping bricks
  #ifndef server_validator
  
  Dim As Integer x1, y1, x2, y2, qx1, qy1, qx2, qy2
  Dim As Integer sx1, sy1, sx2, sy2, tx, ty
  
  set_mini(ibrick)
  
  With ibrick
    If .independant Then Exit Sub
    x1 = screen.scale_x(.x1)
    x2 = x1 + mini(.graphic_mini).b.g(1) -> Width - 1
    y1 = screen.scale_y(.y1)
    y2 = y1 + mini(.graphic_mini).b.g(1) -> height - 1
    
    For i As Integer = 1 To frame_max
      Put brickset(i), (screen.scale_x(.x1), screen.scale_y(.y1)), mini(.graphic_mini).b.g(i), trans
    Next i
  End With
  
  var loopbrick = @ibrick
  while loopbrick < @(..brick.object(..brick.total))
    loopbrick += 1
    With *loopbrick
      If .independant Then Continue while
      
      qx1 = screen.scale_x(.x1)
      qx2 = qx1 + mini(.graphic_mini).b.g(1)->Width - 1
      qy1 = screen.scale_y(.y1)
      qy2 = qy1 + mini(.graphic_mini).b.g(1)->height - 1
      
      If ((x1 >= qx1 And x1 <= qx2) Or (x2 >= qx1 And x2 <= qx2) Or _
        (qx1 >= x1 And qx1 <= x2) Or (qx2 >= x1 And qx2 <= x2)) = false then continue while
      
      if ((y1 >= qy1 And y1 <= qy2) Or (y2 >= qy1 And y2 <= qy2) Or _
        (qy1 >= y1 And qy1 <= y2) Or (qy2 >= y1 And qy2 <= y2)) = false Then continue while
      
      'only redraw the part of brick(i2) within the area (x1, y1) - (x2, y2)
      
      'setup assuming you will redraw all of brick(i2)
      sx1 = 0 'source
      sy1 = 0
      sx2 = qx2 - qx1
      sy2 = qy2 - qy1
      tx = qx1 'target
      ty = qy1
      
      'clip the drawing to stay in a certain part of the target ((x1, y1) - (x2, y2))
      If tx < x1 Then
        sx1 += x1 - tx
        tx = x1
      End If
      If ty < y1 Then
        sy1 += y1 - ty
        ty = y1
      End If
      If tx + (sx2 - sx1) > x2 Then sx2 = x2 - tx + sx1
      If ty + (sy2 - sy1) > y2 Then sy2 = y2 - ty + sy1
      
      For i2 As Integer = 1 To frame_max
        Put brickset(i2), (tx, ty), _
          mini(.graphic_mini).b.g(i2), (sx1, sy1) - (sx2, sy2), trans
      Next i2
    End With
  wend
  #Endif
End Sub

Sub brick_graphic_type.set_mini (Byref ibrick As brick_object_type)
  #ifndef server_validator
  Dim As Integer x, sx, sy
  
  #macro makeimage(i)
    .g(i) = utility.createimage(sx, sy mop("brick mini"))', &HFFFF0000)
    image_scaler(.g(i), 0, 0, brick(ibrick.style).g(i), _
      .g(i)->Width / brick(ibrick.style).g(i)->Width)
  #endmacro
  
  With ibrick
    For i As Integer = 1 To mini_total
      If .scale = mini(i).brick_scale And .style = mini(i).brick_style Then x = i
    Next i
    
    If x > 0 Then
      .graphic_mini = x
      Exit Sub
    End If
    
    If mini_total = mini_max Then
      .graphic_mini = mini_max
      Exit Sub
    End If
    
    mini_total += 1
    .graphic_mini = mini_total
  End With
    
  With mini(mini_total).b
    mini(mini_total).brick_scale = ibrick.scale
    mini(mini_total).brick_style = ibrick.style
    .total = brick(mini(mini_total).brick_style).total
    
    '+1px to prevent ugly gaps
    sx = brick_sx * ibrick.scale * screen.scale + 1'2.5
    sy = brick_sy * ibrick.scale * screen.scale + 1
    
    Select Case .total
    Case -1
      For i As Integer = 1 To 3
        makeimage(i)
        .g(7 - i) = .g(i)
      Next i
    Case 0, 1
      makeimage(1)
      For i As Integer = 2 To 6
        .g(i) = .g(1)
      Next i
    Case 2
      For i As Integer = 1 To 6 Step 3
        makeimage(i)
        .g(i + 1) = .g(i)
        .g(i + 2) = .g(i)
      Next i
    Case 3
      For i As Integer = 1 To 6 Step 2
        makeimage(i)
        .g(i + 1) = .g(i)
      Next i
    Case 6
      For i As Integer = 1 To 6
        makeimage(i)
      Next i
    End Select
  End With
  #Endif
End Sub

sub brick_object_type.move ()
  dim as integer adjust
  
  If independant Then
    x += xv
    x1 += xv
    x2 += xv
    y += yv
    y1 += yv
    y2 += yv
    
    If bouncy Then
      If x1 < 0 Then xv = Abs(xv)
      If x2 >= screen.default_sx Then xv = -Abs(xv)
    End If
    
    'adjust: if moving, kill brick when offscreen, else kill brick when near edge
    If xv <> 0 Or yv <> 0 Then
      adjust = -5
    Else
      adjust = 30
    End If
    
    If (x1 >= screen.default_sx - adjust And xv >= 0) Or _
      (x2 < adjust And xv <= 0) Or _
      (y1 >= screen.default_sy - adjust And yv >= 0) Or _
      (y2 < adjust And yv <= 0) Then
      
      killme = true
      hit_bonusball = 0
      hit_shadow_xv = xv
      hit_shadow_yv = yv
      hit_shadow_spin = Sgn(xv)
      If hit_shadow_spin = 0 Then hit_shadow_spin = Sgn(Rnd() - Rnd())
    End If
  End If
  
  If delay_explode > 0 Then
    delay_explode -= 1
    If delay_explode = 0 Then killme = true
  End If
  
  If killme Then
    'gain points
    If awardpoints Then game.result.scoregained = game.result.scoregained + value
    
    'add bonus
    If style >= brick_enum.first_bonus And style <= brick_enum.last_bonus Then
      bonus.add(x, y, style, 0, 0, scale, hit_bonusball)
    End If
    
    'add brick
    If replication > 0 Then brick.replicate(this)
    
    'add weather
    If style >= brick_enum.first_weather And style <= brick_enum.last_weather Then
      weather.add(style)
    End If
    
    'add an enemy
    If style >= brick_enum.first_enemy And style <= brick_enum.last_enemy Then
      enemy.add(x, y, style - brick_enum.first_enemy + 1, _
        (value + 2) / 7, (value * value) * 100 + 100)
    End If
  End If
end sub

sub brick_object_type.cleanup ()
  dim as double angle
  
  brick.graphic.erasebrick(this)
  xfx.flyingbrick.add(this)
  
  'add sound if onscreen horizontally (not if the wind moved it offscreen)
  If x2 > 0 And x1 < screen.default_sx Then sound.add(sound_enum.thud)
  
  'explode!
  If style = brick_enum.explode Then
    sound.add(sound_enum.brick_explode)
    
    'explode surrounding bricks
    For i2 As Integer = 1 To brick.total
      if @(brick.object(i2)) = @this then continue for
      
      With brick.object(i2)
        If .killme = false And .is_explodable() and _
          Abs(x - .x) <= (.scale + scale) * brick.graphic.brick_sx + 1 And _
          Abs(y - .y) <= (.scale + scale) * brick.graphic.brick_sy + 1 Then
          
          angle = Atan2(.y - y, .x - x)
          .delay_explode = 6
          
          .awardpoints = awardpoints
          .hit_bonusball = hit_bonusball
          .hit_shadow_xv = Cos(angle) * xfx_flyingbrick_type.speed
          .hit_shadow_yv = Sin(angle) * xfx_flyingbrick_type.speed
          .hit_shadow_spin = Sgn(Rnd() - Rnd())
        End If
      End With
    Next i2
    
    'damage with enemies
    For i2 As Integer = 1 To enemy.total
      With enemy.object(i2)
        var d = .scale * enemy.graphic.enemy_sr + scale * brick.graphic.brick_sx * 2
        If (x - .x) * (x - .x) + (y - .y) * (y - .y) < d * d Then .damage(brick.damage_enemyexplosion)
      End With
    Next i2
  End If
end sub

Function brick_object_type.is_explodable () As Integer
  Return style <> brick_enum.invincible And style <> brick_enum.invincible_bouncy
End Function

Function brick_object_type.is_normal () As Integer
  Return style = brick_enum.normal Or (style >= brick_enum.first_extended And style <= brick_enum.last_extended)
End Function
