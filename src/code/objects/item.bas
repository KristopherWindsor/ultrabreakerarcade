
sub item_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  item.gfxchange()
end sub

Sub item_type.start ()
  graphic.start()
End Sub

Sub item_type.reset ()
  total = 0
  frame = 1
  frame_previous = 1
End Sub

Sub item_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub item_type.reset2 ()
  Dim As Integer a
  
  'setup portals
  For i As Integer = 1 To total
    With object(i)
      If .style <> item_enum.portal Then continue for
      
      a = 0
      For i2 As Integer = 1 To total
        If object(i2).style = item_enum.portal_out And .d = object(i2).d Then
          a = i2
          Exit For
        End If
      Next i2
      .d = a
    End With
  Next i
End Sub

Sub item_type.add (Byval style As item_enum, Byval x As Integer, _
  Byval y As Integer, Byval scale As Double, Byval d As Integer = 0)
  
  'scale = 1 for a brick that appears at the original size (defined by png) at the default size
  
  If total >= max Then Exit Sub
  total += 1
  
  With object(total)
    .style = style
    
    .x = x
    .y = y
    
    .scale = scale * scalefactor
    .angle = 0
    .alpha = 255
    
    .d = d
    .d_temp = 0
    
    .killme = false
  End With
End Sub

Sub item_type.move ()
  
  Dim As Integer a
  
  'these frames are only for display
  With game.framerate
    frame_previous = frame
    frame = Int(graphic.frame_ratefactor * .loop_total / .fps_loop) Mod graphic.frame_max + 1
  end with
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  a = 1
  While a <= total
    If object(a).killme And object(a).alpha <= 5 Then
      For i As Integer = a To total - 1
        object(i) = object(i + 1)
      Next i
      total -= 1
    Else
      a += 1
    End If
  Wend
End Sub

Sub item_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub item_type.finish ()
  graphic.finish()
End Sub

Sub item_graphic_type.start ()
  #ifndef server_validator
  For x As Integer = 1 To item_enum.max
    For y As Integer = 1 To frame_max
      item(x, y) = utility.createimage(item_sd, item_sd mop("item graphic"))
    Next y
  Next x
  #Endif
End Sub

Sub item_graphic_type.gfxchange ()
  #ifndef server_validator
  For x As Integer = 1 To item_enum.max
    For y As Integer = 1 To frame_max
      utility.loadimage(main.levelpack.gfxset + "/items/" & x & "/" & y, item(x, y))
    Next y
  Next x
  #Endif
End Sub

Sub item_graphic_type.finish ()
  #ifndef server_validator
  For x As Integer = 1 To item_enum.max
    For y As Integer = 1 To frame_max
      utility.deleteimage(item(x, y) mop("item graphic"))
    Next y
  Next x
  #Endif
End Sub

sub item_object_type.display ()
  #ifndef server_validator
  multiput(, _
    screen.scale_x(x + xfx.camshake.x), _
    screen.scale_y(y + xfx.camshake.y), _
    item.graphic.item(style, item.frame), _
    scale * screen.scale,, angle, alpha)
  #endif
end sub

sub item_object_type.move ()

  Dim As Integer collide_x, collide_y
  Dim As Integer collision_x, collision_y, collision_r, collision_testx, collision_testy
  Dim As Double d1, d2, d3
  
  #macro ballboxcollisionwhile(x1, y1, x2, y2, cx, cy, r)
    collision_testx = cx
    collision_testy = cy
    
    If collision_testx < x1 Then collision_testx = x1 Else If collision_testx > x2 Then collision_testx = x2
    If collision_testy < y1 Then collision_testy = y1 Else If collision_testy > y2 Then collision_testy = y2
    
    collision_testx -= cx
    collision_testy -= cy
    
    If collision_testx * collision_testx + collision_testy * collision_testy > r * r Then Continue while
    
    collision_testx += cx
    collision_testy += cy
  #endmacro
  
  angle += item.rotationfactor
  
  'AI
  Select Case style
  Case item_enum.brickmachine
    d_temp = (d_temp + 1) Mod (d * game.fps)
    Select Case d_temp
    Case Is < game.fps * 5 'pause so game can be won
    Case Is < game.fps * 6
      angle += pi / 60
      
      'just pass the button scale because this scale is based on the layer
      brick.add(_
        x + Cos(angle) * scale * item.graphic.item_sr, _
        y + Sin(angle) * scale * item.graphic.item_sr, _
        39, scale, brick.value_brickmachine, Cos(angle) * brick.speed_brickmachine, _
        Sin(angle) * brick.speed_brickmachine, true)
      brick.graphic.set_mini(brick.object(brick.total))
    Case Else
      'once every 6 seconds
      If (game.frametotal mod game.fps = 0) and (d_temp \ game.fps) mod 6 = 3 then
        brick.add(_
          x + Cos(angle) * scale * item.graphic.item_sd, _
          y + Sin(angle) * scale * item.graphic.item_sd, _
          39, scale, brick.value_brickmachine, Cos(angle) * brick.speed_brickmachine, _
          Sin(angle) * brick.speed_brickmachine, true)
        brick.graphic.set_mini(brick.object(brick.total))
      End If
    End Select
  End Select
  
  'brick collision
  collision_x = x
  collision_y = y
  collision_r = scale * item.graphic.item_sr
  
  var thisbrick = @brick.object(1) - 1
  var lastbrick = iif(brick.total < 1, thisbrick, @brick.object(brick.total))
  while thisbrick < lastbrick
    thisbrick += 1
    if thisbrick->is_explodable() = false Then continue while
    ballboxcollisionwhile(thisbrick->x1, thisbrick->y1, thisbrick->x2, thisbrick->y2, _
      collision_x, collision_y, collision_r)
    
    with *thisbrick
      If style = item_enum.brickmachine Then
        'slide brick out of the way
        If .xv = 0 And .yv = 0 Then
          brick.graphic.erasebrick(*thisbrick)
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
      Else
        'destroy brick
        .killme = true
        .hit_bonusball = 0
        .hit_shadow_xv = .xv
        .hit_shadow_yv = .yv
        .hit_shadow_spin = Sgn(.xv)
        If .hit_shadow_spin = 0 Then .hit_shadow_spin = Sgn(Rnd() - Rnd())
      End If
    End With
  wend
  
  If killme Then alpha -= 5
end sub
