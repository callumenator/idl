
;\\ This funciton returns Magnetic Kp, Solar F10.7, Dst, Hemispheric Power and A indices for a particular
;\\ date. The default data directory is c:\cal\geodata. Date is eg yymmdd

function Get_Geomag_Conditions, date, time, source_path=source_path, quick=quick

	mag = {match:0, yr:0, mn:0, dy:0, bart_no:0, bart_day:0, kp3:0, kp6:0, kp9:0, kp12:0, kp15:0, kp18:0, kp21:0, kp24:0, kpsum:0, $
				ap3:0, ap6:0, ap9:0, ap12:0, ap15:0, ap18:0, ap21:0, ap24:0, apmean:0, Cp:0.0, C9:0, sunspot_no:0, $
				f107:0.0, flux_qual:0, ap:fltarr(24)}

	dst = {match:0, hour:intarr(24), mean:0}

	ai = {match:0, ae:fltarr(24), au:fltarr(24), al:fltarr(24), ao:fltarr(24), ae_mean:0., au_mean:0., al_mean:0., ao_mean:0.}

	;\\ Hemispheric Power (means of index and power level)
	hp = {match:0, north_index:0.0, south_index:0.0, north_power:0.0, south_power:0.0}


	if not keyword_set(source_path) then source_path = 'c:\cal\geodata\'


	;\\ Get some dates
		year = strmid(date, 0, 2)
		mnth = strmid(date, 2, 2)
		day  = strmid(date, 4, 2)

		if strlen(year) lt 4 then year = '20' + year
		jd0 = js2jd(ymds2js(float(year), float(mnth), float(day), 12))

		date_str = dt_tm_mk(jd0, 0D, f='Y$')

	;\\ Open and read in magnetic Kp and solar F10.7 data


	GET_MAGNETIC:
		ap_list = file_search(source_path + '\kp\*', count = naps)
		ap_list_cpy = get_date_from_string(ap_list,4)
		file_match = where(ap_list_cpy eq year, nmtchs)

		if nmtchs gt 0 then begin

			nlines = file_lines(ap_list(file_match(nmtchs-1)))
			ap_str_arr = strarr(nlines)

			openr, ap_file, ap_list(file_match(nmtchs-1)), /get_lun
				readf, ap_file, ap_str_arr
			close, ap_file
			free_lun, ap_file

			date_match = where(strmid(ap_str_arr, 0, 6) eq date, nmtchs)

			if nmtchs gt 0 then begin
				ap_line = ap_str_arr(date_match(0))
				mag.match = 1
				f = ['i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','i','f','i','i','f','i']
				l = fix([2,2,2,4,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,1,3,5,1])
				pos = 0
				for r = 0, n_elements(l) - 1 do begin
					if f(r) eq 'i' then mag.(r+1) = fix(strmid(ap_line, pos, l(r)))
					if f(r) eq 'f' then mag.(r+1) = float(strmid(ap_line, pos, l(r)))
					pos = pos + l(r)
				endfor
			endif

			for tdx = 0, 23 do begin
				mag.ap(tdx) = mag.(15 + (tdx / 3))
			endfor

		endif else begin

			;print, 'No Kp_Ap Data Found'

		endelse



	GET_DST:
		dst_list = file_search(source_path + '\Dst\*', count = naps)

		nlines = file_lines(dst_list(0))
		dst_str_arr = strarr(nlines)

		openr, dst_file, dst_list(0), /get_lun
			readf, dst_file, dst_str_arr
		close, dst_file
		free_lun, dst_file


		date_match = where(strmid(dst_str_arr, 14, 2) + strmid(dst_str_arr, 3, 2) eq year and $
						   strmid(dst_str_arr, 5, 2) eq mnth and $
						   strmid(dst_str_arr, 8, 2) eq day, nmtchs)

		if nmtchs gt 0 then begin

			dst.match = 1

			baseline = (strmid(dst_str_arr(date_match), 16, 4))
			if total(byte(baseline)) eq 32.*4. then baseline = 0 else baseline = float(baseline)*100
			dst.mean = strmid(dst_str_arr(date_match), 116, 5)
			for n = 0, 23 do begin
				dst.hour(n) = strmid(dst_str_arr(date_match), 16 + (n+1)*4, 5)
			endfor
			dst.hour = dst.hour + baseline

		endif else begin

			;print, 'No Dst Data'

		endelse



	if not keyword_set(quick) then begin

	GET_AE_AL_AU_AO:
		restore, source_path + '\AIndices\aindices_formatted.dat'

		date_match = where(yr eq year and mn eq mnth and dy eq day, nmatch)

		if nmatch eq 4 then begin

			ai.match = 1

			for mm = 0, 3 do begin
				case index(date_match(mm)) of
					'AE': begin
						ai.ae = vals(date_match(mm),*)
						ai.ae_mean = amean(date_match(mm))
					end
					'AU': begin
						ai.au = vals(date_match(mm),*)
						ai.au_mean = amean(date_match(mm))
					end
					'AL': begin
						ai.al = vals(date_match(mm),*)
						ai.al_mean = amean(date_match(mm))
					end
					'AO': begin
						ai.ao = vals(date_match(mm),*)
						ai.ao_mean = amean(date_match(mm))
					end
				endcase

			endfor

		endif else begin

			;print, 'No Dst Data'

		endelse





	GET_HEMISPHERIC_POWER:
		restore, source_path + '\hpi\hpindices_formatted.dat'

			match = where(yr eq year and mn eq mnth and dy eq day, nmatch)

			if nmatch gt 2 then begin

				hm = hm(match)
				ut = ut(match)
				index = index(match)
				power = power(match)
				sths = where(hm eq 'S', ns)
				nths = where(hm eq 'N', nn)

				if ns gt 2 then begin
					south_ave_index = mean(index(sths))
					south_ave_power = mean(power(sths))
					south_power_ut = ut[sths]
					south_power = power[sths]
					;hp.south_power = south_power
					;hp.south_index = south_index
				endif
				if nn gt 2 then begin
					north_ave_index = mean(index(nths))
					north_ave_power = mean(power(nths))
					north_power_ut = ut[nths]
					north_power = power[nths]
					;hp.north_power = north_power
					;hp.north_index = north_index
				endif

			;\\ Hemispheric Power (means of index and power level)
			hp = {match:1, $
				  north_ave_index:north_ave_index, $
				  south_ave_index:south_ave_index, $
				  north_ave_power:north_ave_power, $
				  south_ave_power:south_ave_power, $
				  north_power:north_power, $
				  north_power_ut:north_power_ut, $
				  south_power:south_power, $
				  south_power_ut:south_power_ut }


			endif
		endif


	return_struc = {mag:mag, dst:dst, ai:ai, hp:hp}

	return, return_struc


end