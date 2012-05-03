

pro read_haarp_thermal_log, year, month, day, $
							data=data

	dir = where_is('gakona_thermal_log')
	name_string = 'TEMPer-' + string(year,f='(i04)') + '-' $
				   + string(month, f='(i02)') + '-' + string(day, f='(i02)') + '.txt'
	file = dir + name_string

	data = {hour:[0.0], temp:[0.0]}

	if file_test(file) then begin

		nl = file_lines(file)
		dat = strarr(nl)
		openr, hnd, file, /get
		readf, hnd, dat
		free_lun, hnd

		_dy = fix(strmid(dat, 0, 2))
		_mn = fix(strmid(dat, 3, 2))
		_yr = fix(strmid(dat, 6, 4))

		_hrs = fix(strmid(dat, 11, 2))
		_mns = fix(strmid(dat, 14, 2))
		_scs = fix(strmid(dat, 17, 4))

		_temp = float(strmid(dat, 22, 8))

		keep = where(_dy eq day and _temp ne -100 and _temp ne 999, n_keep)
		if n_keep gt 0 then begin
			data = {hour:_hrs[keep] + _mns[keep]/60. + _scs[keep]/3600., $
					temp:_temp[keep] }
		endif

	endif else begin
		print, 'HAARP Thermal Log Not Found'
	endelse
end