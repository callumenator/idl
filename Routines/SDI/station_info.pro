
function station_info, site_code, info

	for i = 0, n_elements(site_code) - 1 do begin

		isite_code = strlowcase(site_code[i])
		case isite_code of

			'pkr':begin
				name = 'Poker Flat'
				glat = 65.13
				glon = -147.48
				mlat = 66.012
				mlon = -96.782
				oval_angle = 23.72
				mlt_ut = 11.17
			end

			'hrp':begin
				name = 'HAARP'
				glat = 62.3
				glon = -145.3
				mlat = 63.65
				mlon = -92.888
				oval_angle = 22.70
				mlt_ut = 10.88
			end

			'kto':begin
				name = 'Kaktovic'
				glat = 69.9
				glon = -143.7
				mlat = 71.264
				mlon = -98.208
				oval_angle = 28.26
				mlt_ut = 11.24
			end

			'tlk':begin
				name = 'Toolik Lake'
				glat = 68.63
				glon = -149.6
				mlat = 68.731
				mlon = -101.223
				oval_angle = 25.23
				mlt_ut = 11.5
			end

			'resolute_bay':begin
				name = 'Resolute Bay'
				glat = 74.72
				glon = -95
				mlat = 83.24
				mlon = -41.12
				oval_angle = 22.62
				mlt_ut = 7.32
			end

			'old_crow':begin
				name = 'Old Crow'
				glat = 67.57
				glon = -139.83
				mlat = 69.25
				mlon = -91.19
				oval_angle = 27.30
				mlt_ut = 10.78
			end

			'maw':begin
				name = 'Mawson'
				glat = -67.603
				glon = 62.874
				mlat = -70.755
				mlon = 90.618
				oval_angle = -45.9
				mlt_ut = 22.66
			end

			'dav':begin
				name = 'Davis'
				glat = -68.577
				glon = 77.967
				mlat = -75.022
				mlon = 100.882
				oval_angle = -49.88
				mlt_ut = 21.94
			end

			else:begin
				glat = -1
				glon = -1
				mlat = -1
				mlon = -1
			end
		endcase

		info = {name:name, $
				glat:glat, glon:glon, $
				mlat:mlat, mlon:mlon, $
				oval_angle:oval_angle, $
				mlt_ut:mlt_ut}

		if size(all_info, /type) eq 0 then begin
			all_info = [info]
		endif else begin
			all_info = [all_info, info]
		endelse

	endfor

	return, all_info
end
