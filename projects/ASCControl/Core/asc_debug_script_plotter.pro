
pro ASC_Debug_Script_Plotter, in_log

	window, 0, xs = 1200, ys = 700

	plot, in_log.local_secs/3600., in_log.sun_angle, thick = 2, xtitle = 'Local Time (Hours)', $
			ytitle = 'Solar Zenith Angle (Degrees)', chars = 1.5, chart = 2, /xstyle, pos = [.1,.1,.9,.9]

	cmd_struc = {started:0.0, stopped:0.0, sun_angle_min:100.0, sun_angle_max:-100.0, cmd:strarr(50)}
	cmds = [cmd_struc]

	for j = 0, n_elements(in_log) - 1 do begin
		if in_log[j].log_string ne '' then begin

			cmds[n_elements(cmds)-1].stopped = in_log[j].local_secs
			new_cmd = cmd_struc
			new_cmd.started = in_log[j].local_secs

			if in_log[j].sun_angle lt cmds[n_elements(cmds)-1].sun_angle_min then $
				cmds[n_elements(cmds)-1].sun_angle_min = in_log[j].sun_angle
			if in_log[j].sun_angle gt cmds[n_elements(cmds)-1].sun_angle_max then $
				cmds[n_elements(cmds)-1].sun_angle_max = in_log[j].sun_angle

			;\\ Coarse log split
			logs = strsplit(in_log[j].log_string, '|', /extract)
			;\\ Fine log split, by comma
			idx = 0
			for k = 0, n_elements(logs) - 1 do begin
				subsplit = strsplit(logs[k], ',', /extract)
				if n_elements(subsplit) gt 1 then subsplit[1:*] = '    ' + subsplit[1:*]
				new_cmd.cmd[idx:idx + n_elements(subsplit)-1] = subsplit
				idx += n_elements(subsplit)
			endfor
			cmds = [cmds, new_cmd]
		endif

		if in_log[j].sun_angle lt cmds[n_elements(cmds)-1].sun_angle_min then $
			cmds[n_elements(cmds)-1].sun_angle_min = in_log[j].sun_angle
		if in_log[j].sun_angle gt cmds[n_elements(cmds)-1].sun_angle_max then $
			cmds[n_elements(cmds)-1].sun_angle_max = in_log[j].sun_angle

	endfor
	cmds[n_elements(cmds)-1].stopped = in_log[n_elements(in_log)-1].local_secs
	cmds = cmds[1:*]


	loadct, 4, /silent
	for j = 0, n_elements(cmds) - 1 do begin
		polyfill, [cmds[j].started,cmds[j].started,cmds[j].stopped,cmds[j].stopped]/3600., $
				  [cmds[j].sun_angle_min,cmds[j].sun_angle_max,cmds[j].sun_angle_max,cmds[j].sun_angle_min], $
				  color = 46 + 16*(j mod 2)
	endfor
	loadct, 39, /silent

	plot, in_log.local_secs/3600., in_log.sun_angle, thick = 2, /noerase, xtitle = 'Local Time (Hours)', $
			ytitle = 'Solar Zenith Angle (Degrees)', chars = 1.5, chart = 2, /xstyle, pos = [.1,.1,.9,.9]
	oplot, in_log.local_secs/3600., in_log.sun_angle, thick = 2, color = 190

	!p.font = 0
	DEVICE, SET_FONT = 'Times-Bold*Heavy*16'

	for j = 0, n_elements(cmds) - 1 do begin
		sun_angle = .5*(cmds[j].sun_angle_min + cmds[j].sun_angle_max)
		xyouts, replicate(cmds[j].started + .1*(cmds[j].stopped-cmds[j].started), 20)/3600., $
				sun_angle + 10 - 1.5*findgen(20), $
				cmds[j].cmd, /data, color = 255, chars = 1, chart = 1.5
		plots, /data, replicate(cmds[j].started + .09*(cmds[j].stopped-cmds[j].started), 2)/3600., $
				[min(in_log.sun_angle), sun_angle + 10], color = 255, thick = 2
	endfor



	!p.font = -1


end