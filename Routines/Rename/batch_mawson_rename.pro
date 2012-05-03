
pro batch_mawson_rename

	dir = 'e:\mawson\'

	out = 'e:\mawson_renamed\'

	list = file_search(dir, '*MAW*', count=nfiles)

	for k = 0, nfiles - 1 do begin

		old_name = file_basename(list[k])

		if (byte(old_name))[3] eq 32 then begin
			byte_name = byte(old_name)
			byte_name[3] = byte('_')
			new_name = string(byte_name)

			file_copy, dir + old_name, out + new_name, /over

		endif else begin

			file_copy, dir + old_name, out + old_name, /over

		endelse

	endfor

end