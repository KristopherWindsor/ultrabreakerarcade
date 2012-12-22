
' AVI Capture Demo by Kristopher Windsor

#define rpt (int(rnd() * sx), int(rnd() * sy))
#define rclr rgb(rnd() * 256, rnd() * 256, rnd() * 256)

#include once "avicapture.bas"

Const sx = 800, sy = 600

Dim As Integer ft
Dim As avicapture squares, circles

Screenres sx, sy, 32

squares.start("squares.avi", 15) '15 FPS
circles.start("circles.avi", 30)

Do
  ft += 1
  
  Screenlock()
  Cls
  Line rpt - rpt, rclr, BF
  Print ft;
  Screenunlock()
  squares.capture()
  
  Screenlock()
  Cls
  Circle rpt, Rnd() * 50, rclr,,,, F
  Screenunlock()
  circles.capture()
  
  Sleep(5, 1)
Loop Until Inkey() = Chr(27)

squares.finish()
circles.finish()
