
sub png_getsize cdecl alias "png_getsize" _
	( _
		byref filename as string, _
		byref w        as uinteger, _
		byref h        as uinteger _
	)
	
	dim as integer i = any
	dim as FILE ptr hfile = fopen( strptr( filename ), "rb" )
	dim as ubyte sig(0 to 7)
	dim as uinteger tmp1 = any, tmp2 = any
	
	if hfile = NULL then
		exit sub
	end if

	if fread( @sig(0), 1, 8, hfile ) <> 8 then
		fclose( hfile )
		exit sub
	end if

	for i = 0 to 7
		if sig(i) <> png_sig(i) then
			fclose( hfile )
			exit sub
		end if
	next i

	if fseek( hfile, &H10, SEEK_SET ) <> 0 then
		fclose( hfile )
		exit sub
	end if
	
	if fread( @tmp1, 1, 4, hfile ) <> 4 then
		fclose( hfile )
		exit sub
	end if

	if fread( @tmp2, 1, 4, hfile ) <> 4 then
		fclose( hfile )
		exit sub
	end if

	w = get_u32( @tmp1 )
	h = get_u32( @tmp2 )
  fclose( hfile )
  
end sub
