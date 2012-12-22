
' AVI Capture! v1.2
' (C) 2009 Innova and Kristopher Windsor

' Written by D.J. Peters
' Exported to a class by Kristopher Windsor

#include once "avicapture.bi"

Sub avicapture.start (file_name As String, frame_rate As Integer = 30)
  Dim As Integer ff = Freefile
  
  If started Then Exit Sub
  started = -1
  frame_count = 0
  
  Screeninfo(screen_x, screen_y)
  
  ArrayOptions = Callocate(4)
  ArrayOptions[0] = @compressoptions
  
  If Open(file_name For Output As ff) Then
    file_name = Int(Timer) & ".avi"
    If Open(file_name For Output As ff) Then
      ? "error: cannot open file!": Beep: Sleep: End 1
    Else
      Close ff
    End If
  Else
    Close ff
  End If
  ScreenControl fb.GET_WINDOW_HANDLE, hWin
  AVIFileInit
  
  If AVIFileOpen(@afile, file_name, xOF_WRITE Or xOF_CREATE,0)<>0 Then
    AVIFileExit
    ? "error: AVIFileOpen!": Beep: Sleep: End 1
  End If
  With streaminfo
    .fccType = String2FOURCC("vids")
    .dwScale = 1
    .dwRate = frame_rate
    .dwSuggestedBufferSize = screen_x * screen_y * 3 ' RGB
    .l = 0: .t = 0: .w = screen_x:.b = screen_y
  End With
  With BitmapFormat
    .biSize = 40
    .biWidth = screen_x
    .biHeight = screen_y
    .biPlanes = 1
    .biBitCount = 24
    .biCompression = 0 ' raw rgb
    .biSizeImage = screen_x * screen_y * 3 ' rgb
    lpbits = Callocate(.biSizeImage)
  End With
  If AVIFileCreateStream(afile, @stream, @streaminfo) Then
    AVIFileRelease(afile)
    AVIFileExit
    ? "error: AVIFileCreateStream!": Beep: Sleep: End 1
  End If
  If AVISaveOptions(hWin, &H7, 1, @stream,ArrayOptions) <> 1 Then
    AVIStreamRelease(stream)
    AVIFileRelease(afile) 
    AVIFileExit
    ? "error: AVISaveOptions!": Beep: Sleep: End 1
  End If
  If AVIMakeCompressedStream(@encoderstream,stream,ArrayOptions[0], 0) Then
    AVISaveOptionsFree(1, ArrayOptions)
    AVIStreamRelease(stream)
    AVIFileRelease(afile)
    AVIFileExit
    ? "error: AVIMakeCompressedStream!": Beep: Sleep: End 1
  End If
  If AVIStreamSetFormat(encoderstream, 0, @BitmapFormat, 40) Then
    AVISaveOptionsFree(1, ArrayOptions)
    AVIStreamRelease(encoderstream)
    AVIStreamRelease(stream)
    AVIFileRelease(afile)
    AVIFileExit
    ? "error: AVIStreamSetFormat!": Beep: Sleep: End 1
  End If
  Asm
    finit
  End Asm
End Sub

Sub avicapture.capture ()
  Static As Integer x, y, d, s
  
  If started = 0 Then Exit Sub
  
  lpScreen = Screenptr()
  ' from bottom to top
  lpScreen += (screen_y - 1) * (screen_x * 4)
  For y=0 To screen_y-1
    d = y * screen_x * 3: s = 0
    For x = 0 To screen_x - 1
      ' ARGB32 to RGB24
      lpBits[d + 0] = lpScreen[s + 0]
      lpBits[d + 1] = lpScreen[s + 1]
      lpBits[d + 2] = lpScreen[s + 2]
      d += 3: s += 4
    Next
    lpScreen -= (screen_x * 4)
  Next
  AVIStreamWrite(encoderstream, frame_count, 1, lpBits, BitmapFormat.biSizeImage, 0, 0, 0)
  frame_count += 1
End Sub

Sub avicapture.finish ()
  If started = 0 Then Exit Sub
  started = 0
  
  ' now free saveoptions, release streams, file and dll
  AVISaveOptionsFree(1, ArrayOptions)
  AVIStreamRelease(encoderstream)
  AVIStreamRelease(stream)
  AVIFileRelease(afile)
  AVIFileExit
End Sub
