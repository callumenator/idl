
pro moon_plotter_gui_ak

	common MoonPlotter, gui, misc

	font = 'Ariel*Bold*18'
	smallFont = 'Ariel*Bold*14'
	base = widget_base(mbar = menu, title = 'Moon Plotter', col = 1)

	menu1 = widget_button(menu, value = 'File', /menu)
	menu1_sub1 = widget_button(menu1, value = 'Load', uval={tag:'fileMenu_load'})

	draw1 = widget_draw(base, xs=512, ys=512, uvalue={tag:'draw1'}, /keyboard_events)
	instruction = widget_list(base, uvalue={tag:'list'})
	widget_control, /realize, base

	widget_control, get_val = draw1_id, draw1

	gui = {base:base, $
		   draw1_id:draw1_id}

	xmanager, 'moon_plotter_gui_ak', base, $
			  event = 'moon_plotter_event_ak', $
			  cleanup = 'moon_plooter_cleanup_ak', /no_block
end


pro moon_plooter_cleanup_ak, event

	heap_gc, /ptr

end


pro moon_plotter_event_ak, event
	common MoonPlotter, gui, misc

	widget_control, get_uvalue = uvalue, event.id

	case uvalue.tag of
		'fileMenu_load': begin
			fname = dialog_pickfile(path='C:\Cal\IDLSource\', default_extension='*.sky')
			if file_test(fname) then begin
				misc.fname = fname

				sdi3k_read_netcdf_data, fname, metadata = metadata, winds = winds, images=images
				rads = [0, metadata.zone_radii[0:metadata.rings-1]]/100.
				secs = metadata.zone_sectors[0:metadata.rings-1]
				azis = winds.azimuths + 2*metadata.oval_angle
				zens = winds.zeniths

				*misc.images = images
				*misc.data = ({meta:metadata, winds:winds, rads:rads, secs:secs, azis:azis, zens:zens})
				ut = js2ut(.5*(winds.start_time + winds.end_time))
				*misc.ut = ut
				misc.nt = n_elements(winds) - 1

				zmap = zonemapper(misc.wx, misc.wx, [misc.wx/2., misc.wx/2.], (*misc.data).rads, (*misc.data).secs, 0)
				*misc.notinc = where(zmap eq -1)
				misc.yymmdd = js_to_yymmdd(.5*(winds[0].start_time + winds[0].end_time))
				misc.tx = 0
				moon_plotter_redraw_ak
			endif
		end
		'draw1': begin
			if event.press eq 1 then begin
			key = string(event.ch)

			case key of
				'.': begin
						if misc.tx lt misc.nt - 1 then misc.tx++ else misc.tx = 0
						moon_plotter_redraw_ak
					end
				',': begin
						if misc.tx gt 0 then misc.tx-- else misc.tx = misc.nt - 1
						moon_plotter_redraw_ak
					end
				'=': begin
						if misc.rang lt 360 then misc.rang++ else misc.rang = 0
						moon_plotter_redraw_ak
					end
				'-': begin
						if misc.rang gt 0 then misc.rang-- else misc.rang = 360
						moon_plotter_redraw_ak
					end
				'w': begin & misc.fov++ & moon_plotter_redraw_ak & end
				'q': begin & misc.fov-- & moon_plotter_redraw_ak & end
				'u': begin & misc.my++ & moon_plotter_redraw_ak & end
				'n': begin & misc.my-- & moon_plotter_redraw_ak & end
				'h': begin & misc.mx-- & moon_plotter_redraw_ak & end
				'j': begin & misc.mx++ & moon_plotter_redraw_ak & end
				else:
			endcase
			endif
		end
		else:
	endcase
end



pro moon_plotter_redraw_ak
	common MoonPlotter, gui, misc

	wset, gui.draw1_id
	loadct, 39, /silent
	erase, 0

	misc.time = (*misc.ut)[misc.tx]

	data = *misc.data

	elevation = get_moon_elevation(misc.yymmdd, misc.time, data.meta.latitude, data.meta.longitude, azimuth=azimuth)
	rad = ((90 - elevation)/misc.fov)*(misc.wx/2.)

	x = misc.mx + rad*sin(azimuth*!dtor)
	y = misc.my + rad*cos(azimuth*!dtor)


		allsky = float((*misc.images)[misc.tx].scene)
		allsky = rot(allsky, misc.rang)
		allsky = reverse(allsky)
		;sc = allsky(sort(allsky))
		;image = bytscl(allsky, max = sc(n_elements(sc)*.99 - 1), $
		;				   min = sc(n_elements(sc)*.01 - 1))
		image = bytscl(allsky)
		image(*misc.notinc) = 0
		loadct, 3, /silent
		tv, image

	loadct, 39, /silent
	circ = [[cos(findgen(361)*!dtor)],[sin(findgen(361)*!dtor)]]
	plots, [0,misc.wx], [misc.wx,misc.wx]/2., color = 255, /device
	plots, [misc.wx,misc.wx]/2., [0,misc.wx], color = 255, /device
	plots, (misc.wx/2.)*(1 + .999*circ(*,0)), (misc.wx/2.)*(1 + .999*circ(*,1)), /device, color = 255
	plots, x, y, /device, color=100, psym=1, thick = 2, sym=3
	;arrow, wx/2., wx/2., wx/2. + (wx/4.)*sin(azimuth*!dtor), wx/2. + (wx/4.)*cos(azimuth*!dtor), color = 150, hsize = 5
	arrow, misc.mx, misc.my, x, y, color = 150, hsize = 5
	xyouts, 5, misc.wx-20, /device, 'Azi: ' + string(azimuth, f='(f0.1)'), color = 255
	xyouts, 5, misc.wx-40, /device, 'Elev: ' + string(elevation, f='(f0.1)'), color = 255
	xyouts, misc.wx-80, misc.wx-20, /device, 'FOV: ' + string(misc.fov, f='(f0.1)'), color = 255
	xyouts, misc.wx-80, misc.wx-40, /device, 'Rot: ' + string(misc.rang, f='(f0.1)'), color = 255

	midJs = 0.5*((*misc.data).winds[misc.tx].start_time + (*misc.data).winds[misc.tx].end_time)
	xyouts, 5, 40, /device, 'UT: ' + time_str_from_js(midJs), color = 255

end

pro moon_plotter_alaska
	common MoonPlotter, gui, misc

	;\\ 2007- 66-68 ang = 55
	;\\ 2007- 92,93,100,130 ang = 69
	;\\ 2007- 282-291 ang = 42
	;\\ 2007- 294-297 ang = 27

	;\\ Not level - 2008- 80,81,82,83,84,85-90-110-117-118-140-174-190-200-220,
	;\\ 2008- 227,231 are very bad
	;\\ 2008- 279,284 ang = 44

	misc = {wx:512, $
			tx:0, $
			fov:80.0, $
			rang:72., $
			mx:512/2., $
			my:512/2., $
			yymmdd:'', $
			time:0., $
			fname:'', $
			notinc:ptr_new(/alloc), $
			data:ptr_new(/alloc), $
			images:ptr_new(/alloc), $
			ut:ptr_new(/alloc), $
			inc:1., $
			nt:0.}



;	year = 2007
;	dayno = 111
;
;	if misc.use_maw eq 1 then begin
;		misc.fname = 'C:\Cal\IDLSource\Data\MawsonRedData0708FFC\' + mawname_from_ydn(year, dayno, /flat, /nopath)
;		data = get_ncdf_data(misc.fname, /quick)
;		misc.data = ptr_new(data)
;		ut = js2ut(.5*(data.start_time + data.end_time))
;		misc.ut = ptr_new(ut)
;		misc.nt = data.nexps - 1
;		zmap = zonemapper(misc.wx, misc.wx, [misc.wx/2., misc.wx/2.], data.rads, data.secs, 0)
;		misc.notinc = ptr_new(where(zmap eq -1))
;		ftimes = filename2yymmdd(misc.fname)
;		misc.yymmdd = ftimes.yymmdd
;	endif else begin
;		ut = float([0, 24])
;		misc.ut = ptr_new(ut)
;		misc.inc = 1./60.
;		misc.nt = (ut(1) - ut(0))/misc.inc
;	endelse


	moon_plotter_gui_ak

end