
sub ball_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  ball.gfxchange()
end sub

Sub ball_type.start ()
  graphic.start()
End Sub

Sub ball_type.reset ()
  data_multiplier = 1
  data_melee = false
  data_scale = 1
  data_speed = 1
  total = 0
  
  'handles ball-blowup end-anim rare case where there are no balls in the level
  With object(1)
    .x = 0
    .y = 0
    .scale = 0
  End With
End Sub

Sub ball_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub ball_type.reset2 ()
  addgroup(true)
end sub

Sub ball_type.add (Byval apaddle As Integer, Byval addtotal As Integer = 1, _
  Byval stuck As Integer = false)
  
  Dim As Double b_radius, p_halfheight
  Dim As Double angle, angle2, paddleplace 'angle is for velocity; paddleplace is the ball position relative to the paddle
  
  Select Case paddle.object(apaddle).side
  Case paddle_side_enum.top
    angle = pi / 2
  Case paddle_side_enum.bottom
    angle = 3 * pi / 2
  Case paddle_side_enum.left, paddle_side_enum.center
    angle = 0
  Case paddle_side_enum.right
    angle = pi
  End Select
  
  If total + addtotal > max Then addtotal = max - total
  If addtotal = 1 Then angle += Rnd() - Rnd()
  
  For i As Integer = 1 To addtotal
    angle2 = angle + (i - (addtotal + 1) * .5) / addtotal
    
    total += 1
    
    With object(total)
      .style = ball_enum.normal
      .scale = ball.data_scale * ball.scalefactor
      
      If stuck Then
        .stuck = apaddle
      Else
        .stuck = false
      End If
      .instantrelease = stuck
      
      var p = @paddle.object(apaddle)
      b_radius = graphic.ball_sr * .scale + 1
      p_halfheight = paddle.graphic.paddle_sy * paddle.data_scale / 2
      paddleplace = paddle.graphic.paddle_sx * paddle.data_scale * (i - (addtotal + 1) * .5) / addtotal
      
      Select Case p->side
      Case paddle_side_enum.top
        .y = p->y + p_halfheight + b_radius
        .x = p->x - paddleplace
      Case paddle_side_enum.bottom
        .y = p->y - p_halfheight - b_radius
        .x = p->x + paddleplace
      Case paddle_side_enum.left, paddle_side_enum.center
        .x = p->x + p_halfheight + b_radius
        .y = p->y + paddleplace
      Case paddle_side_enum.right
        .x = p->x - p_halfheight - b_radius
        .y = p->y - paddleplace
      End Select
      
      'constant value * level value * arcade mode speed-tweak factor
      .xv = Cos(angle2) * speedfactor * data_speed * game.mode.speed
      .yv = Sin(angle2) * speedfactor * data_speed * game.mode.speed
      
      .angle = 0
      .aimrotate = 1
      .mightbereleased = false
      
      .trail_current = .trail_max
      For i As Integer = 1 To .trail_max
        .trail(i) = Type(0, 0)
      Next i
      
      .killme = false
    End With
  Next i
End Sub

Sub ball_type.move ()
  Dim As Integer a, existinstantreleaseballs
  
  'determine which balls can be released next frame
  for i as integer = 1 to total
    object(i).mightbereleased = false
  next i
  for a = 1 to setting.players
    'see if there are any instantrelease balls to select
    existinstantreleaseballs = false
    For i As Integer = 1 to total
      if object(i).stuck = false then continue for
      if paddle.object(object(i).stuck).owner <> a then continue for
      If object(i).instantrelease Then
        existinstantreleaseballs = true
        object(i).mightbereleased = true
      end if
    Next i
    if existinstantreleaseballs then continue for
    'if no instantrelease, then release some other
    For i As Integer = 1 to total
      if object(i).stuck = false then continue for
      if paddle.object(object(i).stuck).owner <> a then continue for
      object(i).mightbereleased = true
      exit for
    Next i
  next a
  
  'move
  For i As Integer = 1 To ball.total
    object(i).move()
  Next i
  
  'cleanup
  a = 1
  While a <= total
    If object(a).killme Then
      sound.add(sound_enum.thud)
      
      'change bonuses' parentball
      For i As Integer = 1 To bonus.total
        With bonus.object(i)
          If .data_parentball = a Then
            .data_parentball = 0
          Elseif .data_parentball > a Then
            .data_parentball -= 1
          End If
        End With
      Next i
      
      'change brick hitball
      For i As Integer = 1 To brick.total
        With brick.object(i)
          If .hit_bonusball = a Then
            .hit_bonusball = 0
          Elseif .hit_bonusball > a Then
            .hit_bonusball -= 1
          End If
        End With
      Next i
      
      For i As Integer = a To total - 1
        object(i) = object(i + 1)
      Next i
      total -= 1
    Else
      a += 1
    End If
  Wend
End Sub

Sub ball_type.display ()
  #ifndef server_validator
  
  'Balls' Glows (Transparent BMP)
  If setting.ballglow Then
    For i As Integer = 1 To ball.total
      With object(i)
        Put (screen.scale_x(.x + xfx.camshake.x) - ((xfx.graphic.glow -> Width) Shr 1), _
          screen.scale_y(.y + xfx.camshake.y) - ((xfx.graphic.glow -> height) Shr 1)), _
          xfx.graphic.glow, alpha
      End With
    Next i
  End If
  
  'Balls (Multiput BMP)
  For i As Integer = ball.total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub ball_type.finish ()
  graphic.finish()
End Sub

Sub ball_type.addgroup (Byval stuck As Integer = true)
  Dim As Integer p, bt(1 To setting.maxplayers), addtotal
  
  If paddle.total = 0 Then Exit Sub
  
  for i as integer = 1 to setting.players
    bt(i) = data_multiplier \ setting.players
    if i <= data_multiplier mod setting.players then bt(i) += 1
  next i
  
  If data_melee Then
    'all paddles
    For i As Integer = 1 To paddle.total
      addtotal += bt(paddle.object(i).owner)
    next i
    If total + addtotal > max Then Exit Sub
    For i As Integer = 1 To paddle.total
      add(i, bt(paddle.object(i).owner), stuck)
    Next i
  Else
    'add balls to one paddle (either random paddle or the first one)
    If total + data_multiplier > max Then Exit Sub
    p = Int(Rnd() * paddle.total) + 1
    add(p, data_multiplier, stuck)
  End If
End Sub

Sub ball_type.duplicate (Byval aball As Integer)
  If total = max Then Exit Sub
  total += 1
  
  object(total) = object(aball)
  
  With object(total)
    .xv *= -1
    .yv *= -1
    For i As Integer = 1 To .trail_max
      .trail(i) = Type(0, 0)
    Next i
    .instantrelease = false
  End With
  
  'now, let's see if it exists (if you created two of them in the same frame)
  var b1 = @object(total)
  If b1->stuck Then Return
  
  For i As Integer = 1 To total - 1
    var b2 = @object(i)
    
    If b2->stuck > 0 Then Continue For
    If b1->x <> b2->x Or b1->y <> b2->y Then Continue For
    If b1->xv <> b2->xv Or b1->yv <> b2->yv Then Continue For
    If b1->scale <> b2->scale Then Continue For
    
    b1->scale *= 2
    If b1->scale > ball.scalemax Then b1->scale = ball.scalemax: Exit For
    i = 0 'restart search for equivalent ball
  Next i
End Sub

Sub ball_graphic_type.start ()
  #ifndef server_validator
  'create images for bloading
  For i As Integer = 1 To ball_enum.max
    ball(i) = utility.createimage(ball_sd, ball_sd mop("ball"))
  Next i
  #Endif
End Sub

Sub ball_graphic_type.gfxchange ()
  #ifndef server_validator
  'load new images
  utility.loadimage(main.levelpack.gfxset + "/balls/normal", ball(ball_enum.normal))
  utility.loadimage(main.levelpack.gfxset + "/balls/fire", ball(ball_enum.fire))
  #Endif
End Sub

Sub ball_graphic_type.finish ()
  #ifndef server_validator
  For i As Integer = 1 To ball_enum.max
    utility.deleteimage(ball(i) mop("ball"))
  Next i
  #Endif
End Sub

sub ball_object_type.display ()
  #ifndef server_validator
  Dim As Integer alpha, t, step_x, step_y
  Dim As Double v
  
  If style = ball_enum.fire Or game.mode_balltrail Then
    t = trail_current
    alpha = ball.graphic.trail_alpha
    For i2 As Integer = 1 To trail_max Step 2
      If trail(t).x = 0 Or trail(t).y = 0 Then Exit For
      
      multiPut(, screen.scale_x(trail(t).x + xfx.camshake.x), _
        screen.scale_y(trail(t).y + xfx.camshake.y), _
        ball.graphic.ball(style), scale * screen.scale,, angle, alpha)
      
      alpha += ball.graphic.trail_alpha
      t += 2
      If t > trail_max Then t -= trail_max
    Next i2
  End If
  
  'let player aim before releasing
  If mightbereleased and game.data_isgameover = false Then
    if paddle.object(stuck).get_totalInstantReleaseBalls() <= 1 then
      v = Sqr(xv * xv + yv * yv)
      step_x = xv / v * scale * ball.graphic.ball_sr
      step_y = yv / v * scale * ball.graphic.ball_sr
      For i As Integer = 1 To 3
        multiPut(, screen.scale_x(x + xfx.camshake.x + step_x * i), _
          screen.scale_y(y + xfx.camshake.y + step_y * i), _
          ball.graphic.ball(style), scale * screen.scale,, angle, ball.graphic.trail_alpha)
      Next i
    end if
  End If
  
  multiPut(, screen.scale_x(x + xfx.camshake.x), _
    screen.scale_y(y + xfx.camshake.y), _
    ball.graphic.ball(style), scale * screen.scale,, angle)
  #endif
end sub

Sub ball_object_type.fixstuckposition ()
  'adjusts the position so ball is just touching paddle, not embedded in it
  'only called when a ball gets stuck, or paddle changes size
  
  If stuck = 0 Then Return
  
  Dim As Double p_halfheight, p_halfwidth, radius
  
  radius = ball.graphic.ball_sr * scale + 1
  p_halfheight = paddle.graphic.paddle_sy * paddle.data_scale * .5
  p_halfwidth = paddle.graphic.paddle_sx * paddle.data_scale * .5
  
  var p = @paddle.object(stuck)
  
  'make sure ball isn't away from the paddle
  Select Case p->side
  Case paddle_side_enum.top, paddle_side_enum.bottom
    If x < p->x - p_halfwidth Then x = p->x - p_halfwidth
    If x > p->x + p_halfwidth Then x = p->x + p_halfwidth
  Case paddle_side_enum.left, paddle_side_enum.right, paddle_side_enum.center
    If y < p->y - p_halfwidth Then y = p->y - p_halfwidth
    If y > p->y + p_halfwidth Then y = p->y + p_halfwidth
  End Select
  
  Select Case p->side
  Case paddle_side_enum.top
    y = p->y + p_halfheight + radius
  Case paddle_side_enum.bottom
    y = p->y - p_halfheight - radius
  Case paddle_side_enum.left
    x = p->x + p_halfheight + radius
  Case paddle_side_enum.right
    x = p->x - p_halfheight - radius
  Case paddle_side_enum.center
    x = p->x + (p_halfheight + radius) * Sgn(x - p->x)
  End Select
End Sub

sub ball_object_type.move ()
  
  Dim As Integer a, flybrick_hitsgn
  Dim As Integer collision_x, collision_y, collision_r, collision_testx, collision_testy
  Dim As Double collision_embed, collision_angle, d1, d2, d3, vsquare, vsquare2
  Dim As Double superpaddle_velocity, flybrick_xv, flybrick_yv
  
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
  
  'fire trail
  If style = ball_enum.fire Or game.mode_balltrail Then
    If game.frametotal Mod 2 = 0 Then
      trail_current = (trail_current Mod trail_max) + 1
      trail(trail_current) = Type(x, y)
    End If
  End If
  
  If stuck > 0 Then
    'move if the paddle moves
    x += paddle.object(stuck).xv
    y += paddle.object(stuck).yv
    
    'release balls on click
    if mightbereleased then
      If game.control(paddle.object(stuck).owner).click And _
        (instantrelease or game.control(paddle.object(stuck).owner).launchdelay = 0) Then
        
        sound.add(sound_enum.ball_collide)
        mightbereleased = false
        instantrelease = false
        game.control(paddle.object(stuck).owner).launchdelay = game.fps * .25
        
        xv += paddle.object(stuck).xv * paddle.frictioneffect
        yv += paddle.object(stuck).yv * paddle.frictioneffect
        stuck = false
      End If
    end if
  End If
  
  if mightbereleased and game.frametotal > game.fps then
    if paddle.object(stuck).get_totalInstantReleaseBalls() <= 1 then aim()
  end if
  
  If stuck > 0 Then return
  
  'keep velocity in range; if gravity attempts to reverse direction, it can
  vsquare = xv * xv + yv * yv
  If vsquare < ball.speedmin * ball.speedmin Then vsquare = ball.speedmin * ball.speedmin
  If vsquare < ball.speedstablevector * ball.speedstablevector Then vsquare = (Sqr(vsquare) + .01) ^ 2
  If vsquare > ball.speedmax * ball.speedmax Then vsquare = ball.speedmax * ball.speedmax
  
  If Abs(xv) < ball.speedstablecomponent Then
    if abs(xv) < ball.speedmin then xv = -ball.speedmin * sgn(xv)
    xv += Sgn(xv) * ball.speedmin
    If xv = 0 Then xv = ball.speedmin
  End If
  If Abs(yv) < ball.speedstablecomponent Then
    if abs(yv) < ball.speedmin then yv = -ball.speedmin * sgn(yv)
    yv += Sgn(yv) * ball.speedmin
    If yv = 0 Then yv = ball.speedmin
  End If
  
  'factor to keep velocity same even though this might have changed direction
  vsquare2 = Sqr(vsquare / (xv * xv + yv * yv))
  xv *= vsquare2
  yv *= vsquare2
  
  'move balls (most awesome part evar!!!)
  x += xv
  y += yv
  angle += ball.spinspeed
  
  'get the ball data in an integer and out of the UDT, for collision detection
  collision_x = x
  collision_y = y
  collision_r = ball.graphic.ball_sr * scale
  
  'bounce off paddles (very optimized)
  var thispaddle = @paddle.object(1) - 1
  var lastpaddle = iif(paddle.total < 1, thispaddle, @paddle.object(paddle.total))
  while thispaddle < lastpaddle
    thispaddle += 1
    ballboxcollisionwhile(thispaddle->x1, thispaddle->y1, thispaddle->x2, thispaddle->y2, _
      collision_x, collision_y, collision_r)
    
    with *thispaddle
      'calculate embed distance
      collision_embed = (scale * ball.graphic.ball_sr) - Sqr( _
         (x - collision_testx) * (x - collision_testx) + _
         (y - collision_testy) * (y - collision_testy))
      
      'get angle for unembedding
      collision_angle = Atan2(yv, xv)
      sound.add(sound_enum.ball_collide)
      
      'see which side is hit
      'the ball might stick, or it might change velocity
      If (Abs((.x1 - (.x1 + .x2) * .5) / (collision_x - (.x1 + .x2) * .5)) > _
        Abs((.y1 - (.y1 + .y2) * .5) / (collision_y - (.y1 + .y2) * .5))) Then
        
        'hit on top or bottom
        If collision_y > (.y1 + .y2) * .5 Then
          'hit on the bottom
          yv = Abs(yv)
          
          x -= Cos(collision_angle) * collision_embed
          y += Sin(collision_angle) * collision_embed
          
          If .side = paddle_side_enum.top And paddle.data_sticky Then
            stuck = cast(integer, thispaddle - @paddle.object(1)) + 1
          Else
            'xv += .xv * paddle.frictioneffect
            push(.xv * paddle.frictioneffect, 0)
          End If
          
          If .side = paddle_side_enum.top And .style = paddle_enum.super Then
            push(collision_x - (.x1 + .x2) * .5, (collision_y - .y1) * 2, true)
          End If
        Else
          'hit on the top
          yv = -Abs(yv)
          
          x -= Cos(collision_angle) * collision_embed
          y += Sin(collision_angle) * collision_embed
          
          If .side = paddle_side_enum.bottom And paddle.data_sticky Then
            stuck = cast(integer, thispaddle - @paddle.object(1)) + 1
          Else
            push(.xv * paddle.frictioneffect, 0)
          End If
          
          If .side = paddle_side_enum.bottom And .style = paddle_enum.super Then
            push(collision_x - (.x1 + .x2) * .5, (collision_y - .y2) * 2, true)
          End If
        End If
      Else
        'hit on left or right
        If collision_x > (.x1 + .x2) * .5 Then
          'hit on the right
          xv = Abs(xv)
          
          x += Cos(collision_angle) * collision_embed
          y -= Sin(collision_angle) * collision_embed
          
          If (.side = paddle_side_enum.left Or .side = paddle_side_enum.center) And _
            paddle.data_sticky Then
            
            stuck = cast(integer, thispaddle - @paddle.object(1)) + 1
          Else
            push(0, .yv * paddle.frictioneffect)
          End If
          
          If (.side = paddle_side_enum.left Or .side = paddle_side_enum.center) And .style = paddle_enum.super Then
            push((collision_x - .x1) * 2, collision_y - (.y1 + .y2) * .5, true)
          End If
        Else
          'hit on the left
          xv = -Abs(xv)
          
          x += Cos(collision_angle) * collision_embed
          y -= Sin(collision_angle) * collision_embed
          
          If (.side = paddle_side_enum.right Or .side = paddle_side_enum.center) And _
            paddle.data_sticky Then
            
            stuck = cast(integer, thispaddle - @paddle.object(1)) + 1
          Else
            push(0, .yv * paddle.frictioneffect)
          End If
          
          If (.side = paddle_side_enum.right Or .side = paddle_side_enum.center) And .style = paddle_enum.super Then
            push((collision_x - .x2) * 2, collision_y - (.y1 + .y2) * .5, true)
          End If
        End If
      End If
      
      If stuck > 0 Then
        fixstuckposition()
        return 'stuck -> no more collision
      Else
        'jump (if ball was buried 2px, then it should have moved 2px after hitting the brick)
        'but only jump if the ball isn't going to stick
        collision_angle = Atan2(yv, xv)
        x += Cos(collision_angle) * collision_embed
        y += Sin(collision_angle) * collision_embed
      End If
    End With
  wend
  
  'store v because if ball collides with multiple bricks, all flying bricks should go the same direction
  '(only used for setting flying bricks)
  flybrick_xv = xv
  flybrick_yv = yv
  flybrick_hitsgn = 0
  
  'bounce off bricks (very optimized)
  var thisbrick = @brick.object(1) - 1
  var lastbrick = iif(brick.total < 1, thisbrick, @brick.object(brick.total))
  while thisbrick < lastbrick
    thisbrick += 1
    ballboxcollisionwhile(thisbrick->x1, thisbrick->y1, thisbrick->x2, thisbrick->y2, _
      collision_x, collision_y, collision_r)
    
    With *thisbrick
      xfx.particle.add(collision_testx, collision_testy)
      sound.add(sound_enum.ball_collide)
      
      'can bounce if: ball is not fire or brick is invincible
      'can destroy if brick is not invincible
      If .is_explodable() Then
        'destroy brick
        If flybrick_hitsgn = 0 Then flybrick_hitsgn = Iif(collision_x > (.x1 + .x2) * .5, -1, 1)
        .awardpoints = true
        .hit_bonusball = cast(integer, @this - @(ball.object(1)) + 1)
        .hit_shadow_xv = flybrick_xv
        .hit_shadow_yv = flybrick_yv
        .hit_shadow_spin = flybrick_hitsgn
        .killme = true
      End If
      
      If style = ball_enum.normal Or .is_explodable() = false Then
        'calculate embed distance
        collision_embed = (scale * ball.graphic.ball_sr) - Sqr( _
          (x - collision_testx) * (x - collision_testx) + _
          (y - collision_testy) * (y - collision_testy))
        
        'get angle for unembedding
        collision_angle = Atan2(yv, xv)
        
        'see which side is hit
        If (Abs((.x1 - (.x1 + .x2) * .5) / (collision_x - (.x1 + .x2) * .5)) > _
          Abs((.y1 - (.y1 + .y2) * .5) / (collision_y - (.y1 + .y2) * .5))) Then
          
          'hit on top or bottom
          If collision_y > (.y1 + .y2) * .5 Then
            'hit on the bottom
            yv = Abs(yv)
            
            x -= Cos(collision_angle) * collision_embed
            y += Sin(collision_angle) * collision_embed
          Else
            'hit on the top
            yv = -Abs(yv)
            
            x -= Cos(collision_angle) * collision_embed
            y += Sin(collision_angle) * collision_embed
          End If
        Else
          'hit on left or right
          If collision_x > (.x1 + .x2) * .5 Then
            'hit on the right
            xv = Abs(xv)
            
            x += Cos(collision_angle) * collision_embed
            y -= Sin(collision_angle) * collision_embed
          Else
            'hit on the left
            xv = -Abs(xv)
            
            x += Cos(collision_angle) * collision_embed
            y -= Sin(collision_angle) * collision_embed
          End If
        End If
        
        'jump (if ball was buried 2px, then it should have moved 2px after hitting the brick)
        collision_angle = Atan2(yv, xv)
        x += Cos(collision_angle) * collision_embed
        y += Sin(collision_angle) * collision_embed
      End If
    End With
  wend
  
  'collide with enemies
  For i2 As Integer = 1 To enemy.total
    with enemy.object(i2)
      collision_x = .x
      collision_y = .y
      
      d1 = (x - collision_x) * (x - collision_x) + (y - collision_y) * (y - collision_y) 'ball - enemy distance (^2)
      d2 = (.scale * enemy.graphic.enemy_sr + scale * ball.graphic.ball_sr) 'allowed min distance
      If d1 < d2 * d2 Then
        sound.add(sound_enum.ball_collide)
        sound.add(sound_enum.thud)
        'unsquare distance from ball to enemy
        d1 = Sqr(d1)
        'angle from enemy to ball
        d3 = Atan2(y - collision_y, x - collision_x)
        'locate ball so it is not touching enemy
        x = collision_x + Cos(d3) * d1
        y = collision_y + Sin(d3) * d1
        'get ball velocity
        d1 = Sqr(xv * xv + yv * yv)
        'set velocity: ball moves away from enemy
        xv = Cos(d3) * d1
        yv = Sin(d3) * d1
        'move ball a bit to distance it from the enemy
        x += xv
        y += yv
        'shrink enemy
        .damage(1)
      End If
    end with
  Next i2
  
  'collide with items
  For i2 As Integer = 1 To item.total
    with item.object(i2)
      collision_x = .x
      collision_y = .y
      
      d1 = (x - collision_x) * (x - collision_x) + (y - collision_y) * (y - collision_y) 'ball - item distance (^2)
      d2 = (.scale * item.graphic.item_sr + scale * ball.graphic.ball_sr) 'allowed min distance
      If d1 > d2 * d2 Then Continue For
      
      'two selects
      Select Case .style
      Case item_enum.bonusbutton
        If .d_temp = 0 Then
          If .d = 0 Then .d = 1 Else .d Shl= 1
          .d_temp = .d
          
          bonus.add(x, y, bonus_enum.bonus_score, 0, 0, 0)
        Else
          .d_temp -= 1
        End If
      End Select
      
      Select Case .style
      Case item_enum.portal
        sound.add(sound_enum.portal_collide)
        If .d > 0 Then
          x += item.object(.d).x - .x
          y += item.object(.d).y - .y
          d1 = Sqr(xv * xv + yv * yv)
          d2 = Rnd() * 2 * pi
          d3 = d2
          While d3 > pi / 2: d3 -= pi / 2: Wend
          If pi / 2 - d3 < d3 Then
            d3 = pi / 2 - d3
            If d3 < pi / 16 Then d2 -= pi / 16
          Else
            If d3 < pi / 16 Then d2 += pi / 16
          End If
          xv = Cos(d2) * d1
          yv = Sin(d2) * d1
        End If
      Case item_enum.bonusbutton, item_enum.brickmachine
        sound.add(sound_enum.ball_collide)
        If .style = item_enum.bonusbutton Then sound.add(sound_enum.thud)
        'bounce
        'unsquare distance from ball to item
        d1 = Sqr(d1)
        'angle from item to ball
        d3 = Atan2(y - collision_y, x - collision_x)
        'locate ball so it is not touching item
        x = collision_x + Cos(d3) * d1
        y = collision_y + Sin(d3) * d1
        'get ball velocity
        d1 = Sqr(xv * xv + yv * yv)
        'set velocity: ball moves away from item
        xv = Cos(d3) * d1
        yv = Sin(d3) * d1
        'move ball a bit to distance it from the item
        x += xv
        y += yv
      End Select
    end with
  Next i2
    
  'collide with orbs
  For i2 As Integer = 1 To orb.total
    with orb.object(i2)
      collision_x = .x
      collision_y = .y
      
      d1 = (x - collision_x) * (x - collision_x) + (y - collision_y) * (y - collision_y) 'ball - orb distance (^2)
      d2 = (.scale * .size + scale * ball.graphic.ball_sr) 'allowed min distance
      If d1 < d2 * d2 Then
        sound.add(sound_enum.ball_collide)
        'unsquare distance from ball to orb
        d1 = Sqr(d1)
        'angle from orb to ball
        d3 = Atan2(y - collision_y, x - collision_x)
        'locate ball so it is not touching orb
        x = collision_x + Cos(d3) * d1
        y = collision_y + Sin(d3) * d1
        'get ball velocity
        d1 = Sqr(xv * xv + yv * yv)
        'set velocity: ball moves away from orb
        xv = Cos(d3) * d1
        yv = Sin(d3) * d1
        'move ball a bit to distance it from the orb
        x += xv
        y += yv
      End If
    end with
  Next i2
  
  'bounce from screen borders
  If x < ball.graphic.ball_sr * scale And paddle.quantities(paddle_side_enum.left) = 0 Then
    sound.add(sound_enum.ball_collide)
    x = ball.graphic.ball_sd * scale - x
    xv *= -1
    xfx.particle.add(0, y)
  End If
  
  If x > screen.default_sx - ball.graphic.ball_sr * scale - 1 And _
    paddle.quantities(paddle_side_enum.right) = 0 Then
    
    sound.add(sound_enum.ball_collide)
    x = (screen.default_sx - ball.graphic.ball_sr * scale - 1) * 2 - x
    xv *= -1
    xfx.particle.add(screen.default_sx - 1, y)
  End If
  
  If y < ball.graphic.ball_sr * scale And paddle.quantities(paddle_side_enum.top) = 0 Then
    sound.add(sound_enum.ball_collide)
    y = ball.graphic.ball_sd * scale - y
    yv *= -1
    xfx.particle.add(x, 0)
  End If
  
  If y > screen.default_sy - ball.graphic.ball_sr * scale - 1 And paddle.quantities(paddle_side_enum.bottom) = 0 Then
    sound.add(sound_enum.ball_collide)
    y = (screen.default_sy - ball.graphic.ball_sr * scale - 1) * 2 - y
    yv *= -1
    xfx.particle.add(x, screen.default_sy - 1)
  End If
  
  'balls off the screen (defined as 10% of width)
  If y - ball.graphic.ball_sr * scale > screen.default_sy + screen.default_sx * .1 Or _
    y + ball.graphic.ball_sr * scale < -screen.default_sx * .1 Or _
    x - ball.graphic.ball_sr * scale > screen.default_sx * 1.1 Or _
    x + ball.graphic.ball_sr * scale < -screen.default_sx * .1 Then
    
    killme = true
  End If
end sub

sub ball_object_type.aim ()
  
  #define m ball.speedstablecomponent
  
  dim as double a, ds, d
  
  a = Atan2(yv, xv) + ball.aimrotatefactor * aimrotate
  ds = xv * xv + yv * yv
  if ds < m * m then ds = m * m 'forces min velocity, but prevents crash
  d = Sqr(ds)
  
  xv = Cos(a) * d
  yv = Sin(a) * d
  
  Select Case paddle.object(stuck).side
  Case paddle_side_enum.top
    If yv < m Then
      xv = Sqr(ds - m * m) * Sgn(xv)
      yv = m
      aimrotate = Iif(xv < 0, -1, 1)
    End If
  Case paddle_side_enum.bottom
    If yv > -m Then
      xv = Sqr(ds - m * m) * Sgn(xv)
      yv = -m
      aimrotate = Iif(xv < 0, 1, -1)
    End If
  Case paddle_side_enum.left
    If xv < m Then
      xv = m
      yv = Sqr(ds - m * m) * Sgn(yv)
      aimrotate = Iif(yv < 0, 1, -1)
    End If
  Case paddle_side_enum.right
    If xv > -m Then
      xv = -m
      yv = Sqr(ds - m * m) * Sgn(yv)
      aimrotate = Iif(yv < 0, -1, 1)
    End If
  Case paddle_side_enum.center
    If x < paddle.object(stuck).x Then
      'like right paddle
      If xv > -m Then
        xv = -m
        yv = Sqr(ds - m * m) * Sgn(yv)
        aimrotate = Iif(yv < 0, -1, 1)
      End If
    Else
      'like left paddle
      If xv < m Then
        xv = m
        yv = Sqr(ds - m * m) * Sgn(yv)
        aimrotate = Iif(yv < 0, 1, -1)
      End If
    End If
  End Select
  
end sub

Sub ball_object_type.push (Byval ixv As Double, Byval iyv As Double, Byval vreset As Integer = false)
  Dim As Double d
  
  'change direction, but not speed, unless vreset
  d = Sqr(xv * xv + yv * yv)
  If vreset Then
    xv = ixv
    yv = iyv
  Else
    xv += ixv
    yv += iyv
  End If
  
  If Abs(xv) < ball.speedmin Then xv = ball.speedmin
  If Abs(yv) < ball.speedmin Then yv = ball.speedmin
  If Abs(xv) > Abs(yv) * ball.componentratiomax Then xv = Sgn(xv) * Abs(yv) * ball.componentratiomax
  If Abs(yv) > Abs(xv) * ball.componentratiomax Then yv = Sgn(yv) * Abs(xv) * ball.componentratiomax
  
  d /= Sqr(xv * xv + yv * yv)
  xv *= d
  yv *= d
End Sub
