

pro haarp_thermal_drift

	dir = 'C:\cal\Operations\SDI_Instruments\Gakona\ThermalLogs\'
	logs = file_search(dir + '*.txt', count = n_logs)
	save_file = 'c:\cal\idlsource\newalaskacode\routines\sdi\haarp_drift_temps.idlsave'
	redo = 0

	if redo eq 1 or file_test(save_file) eq 0 then begin

		period = ((findgen(100))+1) * 60.
		power = fltarr(nels(period), n_logs)
		ydn = fltarr(n_logs)
		for log_idx = 0, n_logs - 1 do begin

			nl = file_lines(logs[log_idx])
			dat = strarr(nl)
			openr, hnd, logs[log_idx], /get
			readf, hnd, dat
			free_lun, hnd

			_dy = fix(strmid(dat, 0, 2))
			_mn = fix(strmid(dat, 3, 2))
			_yr = fix(strmid(dat, 6, 4))

			_hrs = fix(strmid(dat, 11, 2))
			_mns = fix(strmid(dat, 14, 2))
			_scs = fix(strmid(dat, 17, 4))

			_temp = float(strmid(dat, 22, 8))

			append, _dy, day
			append, _mn, month
			append, _yr, year
			append, _hrs, hour
			append, _mns, minute
			append, _scs, second
			append, _temp, temp

			keep = where(_temp ne -100)
			js = ymds2js(_yr, _mn, _dy, _hrs*3600. + _mns*60. + _scs)
			temp_c = _temp - smooth(_temp, nels(_temp)/10., /edge)
			power[*,log_idx] = generalised_lomb_scargle(js[keep], temp_c[keep], 1./period, /raw)
			ydn[log_idx] = max(_yr) + max(_mn)/12. + max(_dy)/365.

			print, log_idx, n_logs
			wait, 0.005
		endfor

		save, filename = save_file, period, power, ydn
	endif else begin
		restore, save_file
	endelse

	restore, 'c:\cal\idlsource\newalaskacode\routines\sdi\haarp_drift.idlsave'


	las_keep = where(las_ydn gt 2009 and ydn lt 2013)
	las_med = median(las_power[30:36, las_keep], dim=1)
	las_med -= min(las_med)
	las_med /= max(las_med)
	las_ydn = las_ydn[las_keep]

	tmp_keep = where(ydn gt 2009 and ydn lt 2013)
	tmp_med = median(power[34:40, tmp_keep], dim=1)
	tmp_med -= min(tmp_med)
	tmp_med /= max(tmp_med)
	tmp_ydn = ydn[tmp_keep]

	bin, las_ydn, las_med, 10./365., xa, ya, /ymed
	bin, tmp_ydn, tmp_med, 10./365., xb, yb, /ymed

	stop


end