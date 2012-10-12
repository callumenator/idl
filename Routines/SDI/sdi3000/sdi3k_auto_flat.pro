pro sdi3k_auto_flat, mm, wind_offset, use_database = use_database

	if keyword_set(use_database) then begin
	;\\ ######## Version utilizing the all-in-one database ##########

		js2ymds, mm.start_time
		possible = sdi_tag_query(mm.site_code, mm.wavelength_nm, mm.start_time[0])

		if size(possible, /type) eq 2 then begin

			;\\ No usable data in the database yet, fall back on original version
			goto, ORIGINAL_VERSION

		endif else begin

			;\\ Most recent
			possible = possible[sort(possible.js_start)]
			recent = possible(n_elements(possible) - 1)

			exposures = *recent.positions
			sum = findgen(n_elements(exposures[*,0]))
			for i = 0, n_elements(exposures[0,*]) - 1 do begin
				exposure = reform(exposures[*,i])
				exposure -= median(exposure)
				sum += exposure
			endfor

			wind_offset = sum / float(n_elements(exposures[0,*]))

			;\\ If zonemaps are different, we could interpolate spatially here...

			return

		endelse

	endif else begin
	;\\ ######## The original version utilizing separate files ##########

	ORIGINAL_VERSION:

		;----First check if there is a wind offset saved in the netCDF file. If so, use it:
		;     sdi3k_read_netcdf_data, mm.file_name, wind_offset=wind_offset
		     if n_elements(wind_offset) eq mm.nzones then return
		     wind_offset = fltarr(mm.nzones)

		;---Determine the wavelength:
		    doing_sodium = 0
		    doing_red    = 0
		    doing_green  = 0
		    if abs(mm.wavelength_nm - 589.0) lt 5. then begin
		       lamda = '5890'
		       doing_sodium = 1
		       lamstring = '_sodium'
		    endif
		    if abs(mm.wavelength_nm - 557.7) lt 5. then begin
		       lamda = '5577'
		       doing_green = 1
		       lamstring = '_green'
		    endif
		    if abs(mm.wavelength_nm - 630.0) lt 5. then begin
		       lamda = '6300'
		       doing_red = 1
		       lamstring = '_red'
		    endif

		      local_path = file_expand_path(mm.path) + '\'
		      flats    = findfile(local_path + "Wind_flat_field*" + lamda + "*.sav")

			  if size(flats, /dimensions) eq 0 then return

		      j=0
		      used = 0
		      while j lt n_elements(flats) do begin
		          wind_flat_field = 'NULL'
		          if file_test(flats(j)) then begin
		          	restore, flats(j)
		          endif else begin
					j++
					continue
				  endelse
		          if size(wind_flat_field, /tname) ne 'STRUCT' then begin
		             veceldel, flats, j
		             veceldel, optns, j
		          endif else begin
		          	if n_elements(wind_flat_field.wind_offset) eq mm.nzones then begin
		             	if used eq 0 then begin
		             		flatarr = wind_flat_field
		             		used ++
		             	endif else begin
		;---------------Need to use struct_assign in case there are different numbers of days in the various files:
		                	holder  = flatarr(0)
		                	STRUCT_ASSIGN, wind_flat_field, holder
		                	flatarr = [flatarr, holder]
							used ++
		             	endelse
		             endif
		          endelse
		          j = j + 1
		          wait, 0.01
		      endwhile

			if size(flatarr, /type) eq 0 then return

		;-----Only keep the flat field files flagged as being valid during the time of the current data:
		      centime = (mm.start_time + mm.end_time)/2
		      goods = where(centime gt (flatarr.js_valid(0)) and centime lt  (flatarr.js_valid(1)), ng)
		      if ng le 0 then return  ; There were no valid files. Return an offset of zero.
		      flatarr = flatarr(goods)

		;-----Now determine a weighted score of merit for the remaing candidate flat field files:
		      weight = exp(-((flatarr.js_average - centime)/(60D*86400D))^2) + 0.25*flatarr.stars.index
		;      flatarr = flatarr(sort(weight))
		;      best = flatarr(n_elements(weight)-1)
		;      wind_offset = best.wind_offset
		      for j=0,n_elements(weight)-1 do begin
		          wind_offset = weight(j)*flatarr(j).wind_offset
		      endfor
		      wind_offset = wind_offset/total(weight)
	endelse

end
