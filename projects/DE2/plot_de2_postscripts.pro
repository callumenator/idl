
pro plot_de2_postscripts

	date = [81300, $
			81300, $
			81329, $
			81330, $
			81331, $
			81342, $
			81352, $
			81358, $
			81362, $
			82024, $
			82049, $
			82118, $
			82120, $
			82146, $
			82198, $
			82250, $
			82251, $
			82255, $
			82312, $
			82325, $
			83019, $
			83029	]

	orbit = [1251, $
			 1259, $
			 1686, $
			 1696, $
			 1711, $
			 1885, $
			 2025, $
			 2124, $
			 2182, $
			 2580, $
			 2954, $
			 3992, $
			 4028, $
			 4426, $
			 5216, $
			 6008, $
			 6030, $
			 6091, $
			 6971, $
			 7164, $
			 8088, $
			 8257	]

	save_path = 'C:\Cal\IDLSource\de2_data\Cal_Saves\'
	plot_path = 'C:\Cal\IDLSource\de2_data\Plots\'

	loadct, 39, /silent

	r = [intarr(128), indgen(128)*2]
	b = [255 - indgen(128)*2, intarr(128)]
	g = intarr(256)

	for j = 0, n_elements(date) - 1 do begin
		name = 'DE_'+ string(date(j),f='(i0)') + '_Orbit_' + string(orbit(j), f='(i0)')
		restore, save_path + name + '.dat'

		dt = string(date(j), f='(i0)')
		yr = '19' + strmid(dt, 0, 2)
		dayno = strmid(dt, 2, 3)

		ord = sort(k_lat)
		set_plot, 'ps'
		device, filename = plot_path + name + '.eps', /color, /encaps, bits=8, xs = 17, ys = 6

			plot, k_lat(ord), k_vz_mod(ord), /nodata, xstyle = 5, yrange = [-150,150], ystyle=9, chars = .6, $
				  pos = [.13,.22,.98,.93], ytitle = 'Speed (ms!E-1!N)', xrange = [min(k_lat) - .05, max(k_lat) + .05], $
				  title = 'DE2 - ' + yr + ' Day ' + dayno + ', Orbit #' + string(orbit(j), f='(i0)'), yticklen=.01

 			axis, 0, -170, xaxis=0, /xstyle, chars = .6, xtick_get=xut, xtickint=.1, $
 					xrange = [min(k_ut) - .05, max(k_ut) + .05], /data

			xlat = interpol(k_ilat, k_ut, xut)
			axis, 0, -210, xaxis=0, xtickname = string(xlat, f='(i0)') + '!9%!3', chars = .6, /data, /xstyle, $
				  xtickint = .1, xrange = [min(k_ut) - .05, max(k_ut) + .05]

			oplot, [0,100], [0,0], line = 1
			plots, k_lat(ord), k_vz_mod(ord), color = 0, /data
			plots, k_lat(ord), k_vz_mod(ord), color = 0, /data, psym=6, sym=.1, thick = 2

			;axis, yaxis=1, yrange = [400,2000], /save
			;oplot, k_ut, k_temp

			xyouts, /normal, .02, .13, 'Time (UT)', chars = .6
			xyouts, /normal, .02, .05, 'Inv. Latitude', chars = .6

		empty
		set_plot, 'win'


		set_plot, 'ps'
		device, filename = plot_path + name + 'alt.eps', /color, /encaps, bits=8, xs = 17, ys = 8

			plot, k_ut, k_vz_mod, /nodata, xstyle = 5, yrange = [-150,150], /ystyle, chars = .8, chart=1.5, $
				  pos = [.09,.13,.98,.80], ytitle = 'Speed (ms!E-1!N)', xrange = [min(k_ut) - .05, max(k_ut) + .05], $
				  yticklen=.01

 			axis, xaxis=0, /xstyle, chars = .8, xtick_get=xut, xtickint=.1, chart=1.5, $
 					xrange = [min(k_ut) - .05, max(k_ut) + .05], /data

			xlat = interpol(k_ilat, k_ut, xut)
			axis, xaxis=1, xtickname = string(xlat, f='(i0)') + '!9%!3', chars = .8, /data, /xstyle, $
				  xtickint = .1, xrange = [min(k_ut) - .05, max(k_ut) + .05], chart=1.5

			oplot, [0,100], [0,0], line = 1
			tvlct, r, g, b
			plots, k_ut, k_vz_mod, color = 0, /data
			plots, k_ut, k_vz_mod, color = 0, /data, psym=6, sym=.1, thick = 2
			loadct, 39, /silent

			xyouts, /normal, .45, .02, 'Time (UT)', chars = .8, chart=1.5
			xyouts, /normal, .45, .87, 'Inv. Latitude', chars = .8, chart=1.5
			xyouts, /normal, .03, .94, 'DE2 - ' + yr + ' Day ' + dayno + ', Orbit #' + string(orbit(j), f='(i0)'), chars = .8, chart=1.5

		empty
		set_plot, 'win'

	endfor
	stop


end