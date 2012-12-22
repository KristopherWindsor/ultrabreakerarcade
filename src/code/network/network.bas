
' Networking code based on stuff from the forum
' Written 2008 - 2010, v1.2

#include once "chisock/chisock.bi"
#inclib "chisock"
#include once "win/wininet.bi"

namespace network
  Function downloadfile (Byref url As String, Byref target As String) As Integer
    Dim As Integer ff = Freefile()
    Dim As Any Ptr library
    Dim URLDownloadToFile As Function (Byval pCaller As Any Ptr, Byval szURL As String, _
      Byval szFileName As String, Byval dwResv As Uinteger, Byval lpfnCB As Any Ptr) As Integer
    
    If Open(target For Append As #ff) Then Return false
    Close #ff
    
    library = Dylibload("urlmon")
    If library = 0 Then Return false
    
    URLDownloadToFile = Dylibsymbol(library, "URLDownloadToFileA")
    If URLDownloadToFile = 0 Then Dylibfree(library): Return false
    
    dim as zstring ptr z = cptr(zstring ptr, @(url[0]))
    DeleteUrlCacheEntry(z)
    If URLDownloadToFile(0, url, target, 0, 0) Then Dylibfree(library): Return false
    
    Dylibfree(library)
    Return true
  End Function
  
  Function hitpage (Byref url_page As String, _
    Byref result As String = "", Byref postdata As String = "") As Integer
    
    'hits page and returns true on success
    'if false but the socket connected, result will be set to empty string
    
    Const url_domain = "ultrabreaker.com"
    
    Dim As Integer a
    Dim As String header, url = url_domain & url_page
    Dim As chi.socket socket
    
    dim as zstring ptr z = cptr(zstring ptr, @(url[0]))
    DeleteUrlCacheEntry(z)
    If socket.client(url_domain, 80) Then Return false
    
    socket.put_HTTP_request(url, "POST", postdata)
    result = socket.get_until("")
    socket.close()
    
    'empty line indicates end of header
    a = Instr(result, Chr(13, 10, 13, 10))
    
    If a = 0 Then
      result = ""
      Return false
    End If
    
    header = Left(result, a - 1)
    result = Mid(result, a + 4)
    
    If Instr(header, "404 Not Found") > 0 Then
      result = ""
      Return false
    End If
    
    Return true
  End Function
  
  function urlencode(value as string) as string
    dim as string r = ""
    dim as string hx = "0123456789ABCDEF"
    
    for i as integer = 0 to len(value) - 1
      dim as integer j = value[i]
      
      if j = 32 then
        r += "+"
      elseif j = asc("-") or j = asc("_") then
        r += chr(j)
      elseif (j >= asc("a") and j <= asc("z")) or (j >= asc("A") and j <= asc("Z")) then
        r += chr(j)
      else
        r += "%" & chr(hx[j \ 16]) & chr(hx[j mod 16])
      end if
    next i
    
    return r
  end function
End namespace
