
Sub explodepaddle_type.reset ()
  #ifndef server_validator
  While explodepaddle.total > 0
    utility.deleteimage(object(total).graphic mop("exploded paddle"))
    total -= 1
  Wend
  #Endif
End Sub

Sub explodepaddle_type.add (Byval apaddle As Integer)
  #ifndef server_validator
  
  Dim As Integer particle_total_x, particle_total_y
  Dim As Integer x, y
  Dim As Double angle, gx, gy
  Dim As fb.image Ptr g
  
  If setting.extras = false Then Return
  
  If total = max Then Exit Sub
  total += 1
  
  With paddle.object(apaddle)
    g = paddle.graphic.minis(.owner, .style, .side)
  End With
  
  With object(total)
    'scaled top left of paddle graphic
    gx = screen.scale_x(paddle.object(apaddle).x) - (g->width) \ 2
    gy = screen.scale_y(paddle.object(apaddle).y) - (g->height) \ 2
    
    particle_total_x = Int(((g -> Width) - 1) / particle_sd)
    particle_total_y = Int(((g -> height) - 1) / particle_sd)
    If (particle_total_x + 1) * (particle_total_y + 1) > .particle_max Then
      particle_total_y = Int(.particle_max / (particle_total_x + 1)) - 1
    End If
    
    .particle_total = 0
    For x = 0 To particle_total_x
      For y = 0 To particle_total_y
        angle = Atan2((y - particle_total_y / 2) / (g -> height), _
          (x - particle_total_x / 2) / (g -> Width))
        
        .particle_total += 1
        With .particle(.particle_total)
          .x = screen.unscale_x(gx + x * particle_sd)
          .y = screen.unscale_y(gy + y * particle_sd)
          .xv = Cos(angle) * particlespeed
          .yv = Sin(angle) * particlespeed
          .gx = x * particle_sd
          .gy = y * particle_sd
        End With
      Next y
    Next x
    
    .graphic = utility.createimage(g -> Width, g -> height mop("exploded paddle"))
    Put .graphic, (0, 0), g, Pset
    
    .ttl = game.framerate.fps_loop * 8
    .killme = false
  End With
  #Endif
End Sub

Sub explodepaddle_type.move ()
  #ifndef server_validator
  Dim As Integer a
  
  For i As Integer = 1 To total
    With object(i)
      For i2 As Integer = 1 To .particle_total
        With .particle(i2)
          .yv += game.gravityfactor
          .x += .xv
          .y += .yv
        End With
      Next i2
      
      .ttl -= 1
      If .ttl = 0 Then .killme = true
    End With
  Next i
  
  a = 1
  While a <= total
    If object(a).killme Then
      utility.deleteimage(object(a).graphic mop("exploded paddle"))
      object(a) = object(total)
      total -= 1
    Else
      a += 1
    End If
  Wend
  #Endif
End Sub

Sub explodepaddle_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    With object(i)
      For i2 As Integer = 1 To .particle_total
        With .particle(i2)
          Put (screen.scale_x(.x + xfx.camshake.x), _
            screen.scale_y(.y + xfx.camshake.y)), _
            object(i).graphic, (.gx, .gy) - _
            Step(particle_sd - 1, particle_sd - 1), alpha
        End With
      Next i2
    End With
  Next i
  #Endif
End Sub

Sub explodepaddle_type.finish ()
  'cleanup left-over gfx
  #ifndef server_validator
  reset()
  #Endif
End Sub
