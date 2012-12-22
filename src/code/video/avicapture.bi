
' AVI Capture! v1.2
' (C) 2009 Innova and Kristopher Windsor

#include once "fbgfx.bi"

Const AVIIF_KEYFRAME = &H10

Enum FILEFLAGS
  xOF_WRITE  = &H0001
  xOF_CREATE = &H1000
End Enum

Enum AVISAVEFLAGS
  ICMF_CHOOSE_KEYFRAME       = (1 Shl 0)
  ICMF_CHOOSE_DATARATE       = (1 Shl 1)
  ICMF_CHOOSE_PREVIEW        = (1 Shl 2)
  ICMF_CHOOSE_ALLCOMPRESSORS = (1 Shl 3)
End Enum

Type AVIFILEINFO
  As Uinteger dwMaxBytesPerSec
  As Uinteger dwFlags
  As Uinteger dwCaps
  As Uinteger dwStreams
  As Uinteger dwSuggestedBufferSize
  As Uinteger dwWidth
  As Uinteger dwHeight
  As Uinteger dwScale
  As Uinteger dwRate
  As Uinteger dwLength
  As Uinteger dwEditCount
  As String * 63 szFileType
End Type

Type AVISTREAMINFO
  As Uinteger fccType
  As Uinteger fccHandler
  As Uinteger dwFlags
  As Uinteger dwCaps
  As Ushort   wPriority
  As Ushort   wLanguage
  As Uinteger dwScale
  As Uinteger dwRate
  As Uinteger dwStart
  As Uinteger dwLength
  As Uinteger dwInitialFrames
  As Uinteger dwSuggestedBufferSize
  As Uinteger dwQuality
  As Uinteger dwSampleSize
  As Uinteger l,t,w,b
  As Uinteger dwEditCount
  As Uinteger dwFormatChangeCount
  As String * 63 szName
End Type

Type AVICOMPRESSOPTIONS
  As Uinteger fccType
  As Uinteger fccHandler
  As Uinteger dwKeyFrameEvery
  As Uinteger dwQuality
  As Uinteger dwBytesPerSecond
  As Uinteger dwFlags
  As Any Ptr  lpFormat
  As Uinteger cbFormat
  As Any Ptr  lpParms
  As Uinteger cbParms
  As Uinteger dwInterleaveEvery
End Type

Type PAVICOMPRESSOPTIONS As AVICOMPRESSOPTIONS Ptr

Type xBITMAPINFOHEADER
  As Integer  biSize
  As Integer  biWidth
  As Integer  biHeight
  As Short    biPlanes
  As Short    biBitCount
  As Integer  biCompression
  As Integer  biSizeImage
  As Integer  biXPelsPerMeter
  As Integer  biYPelsPerMeter
  As Integer  biClrUsed
  As Integer  biClrImportant
End Type

Type AVISaveCallback As Function (Byval nPercent As Integer) As Integer

Type AVIFILE   As Any Ptr

Type AVISTREAM As Any Ptr

Declare Function String2FOURCC       Lib "winmm"    Alias "mmioStringToFOURCCA"  (Byval As String, Byval As Uinteger=0) As Uinteger
Declare Sub      AVIFileInit         Lib "avifil32" Alias "AVIFileInit"
Declare Sub      AVIFileExit         Lib "avifil32" Alias "AVIFileExit"
Declare Function AVIFileOpen         Lib "avifil32" Alias "AVIFileOpenA"         (Byval As AVIFILE Ptr, Byval strfile As String, Byval flag As FILEFLAGS, Byval lpClass As Any Ptr) As Integer
Declare Function AVIFileRelease      Lib "avifil32" Alias "AVIFileRelease"       (Byval As AVIFILE) As Integer
Declare Function AVIFileCreateStream Lib "avifil32" Alias "AVIFileCreateStreamA" (Byval As AVIFILE, Byval As AVISTREAM Ptr, Byval As AVISTREAMINFO Ptr) As Integer
Declare Function AVIStreamRelease    Lib "avifil32" Alias "AVIStreamRelease"     (Byval As AVISTREAM) As Integer
Declare Function AVIMakeCompressedStream Lib "avifil32" Alias "AVIMakeCompressedStream"(Byval As AVISTREAM Ptr, Byval As AVISTREAM , Byval As AVICOMPRESSOPTIONS Ptr, Byval lpClassHandler As Any Ptr) As Integer
Declare Function AVISaveOptions      Lib "avifil32" Alias "AVISaveOptions"       (Byval hParent  As Integer, Byval As AVISAVEFLAGS, Byval nStreams As Uinteger, Byval As AVISTREAM Ptr, Byval As PAVICOMPRESSOPTIONS Ptr) As Integer
Declare Function AVISaveOptionsFree  Lib "avifil32" Alias "AVISaveOptionsFree"   (Byval nStreams As Integer, Byval As PAVICOMPRESSOPTIONS Ptr) As Integer
Declare Function AVIStreamSetFormat  Lib "avifil32" Alias "AVIStreamSetFormat"   (Byval As AVISTREAM, Byval As Integer, Byval As Any Ptr, Byval As Integer) As Integer
Declare Function AVIStreamWrite      Lib "avifil32" Alias "AVIStreamWrite"       (Byval As AVISTREAM, Byval nPos As Integer, Byval nStream As Integer, Byval lpPixel As Any Ptr, Byval bytes As Integer, Byval flag As Integer, Byval swritten As Integer Ptr, Byval bwritten As Integer Ptr) As Integer

Type avicapture
  Declare Sub start (file_name As String, frame_rate As Integer = 30)
  Declare Sub capture ()
  Declare Sub finish ()
  
  Declare property isStarted () As Integer
  
  Private:
  
  As AVIFILE             afile
  As AVISTREAM           stream
  As AVISTREAM           encoderstream
  As AVISTREAMINFO       streaminfo
  As AVICOMPRESSOPTIONS  compressoptions
  As PAVICOMPRESSOPTIONS Ptr ArrayOptions
  As xBITMAPINFOHEADER   Bitmapformat
  
  As Byte Ptr lpBits, lpScreen
  As Integer screen_x, screen_y, frame_count, hWin, started
End Type

property avicapture.isStarted () As Integer
  isStarted = started
End property
