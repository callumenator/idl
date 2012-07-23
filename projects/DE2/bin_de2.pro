

pro bin_de2

	restore, 'c:\cal\idlgit\projects\de2\alldata.idlsave'

	data = data[ where(data.alt gt 300 and data.alt lt 400 and data.lat lt 0 and data.ilat gt 40 and abs(data.vz) lt 300) ]


 	;data = data[ where(data.alt gt 200 and data.alt lt 400 and data.lat gt 0 and $
	;				   data.ilat gt 60 and data.ilat lt 80 and abs(data.vz) lt 300) ]
	;stop

	mlt_bin = .5
	lat_bin = 2.
	bin2d, data.mlt, data.ilat, data.vz, [mlt_bin, lat_bin], x, y, z

	wx = 800.
	wy = 800.

	load_color_table, 'blue_black_red.ctable'
	;loadct, 39, /silent
	scale_to_range, z, -20, 20, oz
	window, 0, xs = wx, ys = wy

	for ix = 0, nels(x) - 1 do begin
	for iy = 0, nels(y) - 1 do begin

		rad = (wx/2.)*((90-y[iy])/float(max(90-y)))
		azi = 90.*(x[ix] - 12)/6.

		rad_upper = rad - (lat_bin/2.)*( (wx/2.) / float(max(90-y)) )
		rad_lower = rad + (lat_bin/2.)*( (wx/2.) / float(max(90-y)) )
		azi_lo = azi - (90.*(mlt_bin/2.)/6.)
		azi_hi = azi + (90.*(mlt_bin/2.)/6.)

		x0 = wx/2. + rad_upper*sin(azi_lo*!DTOR)
		x1 = wx/2. + rad_lower*sin(azi_lo*!DTOR)
		x2 = wx/2. + rad_lower*sin(azi_hi*!DTOR)
		x3 = wx/2. + rad_upper*sin(azi_hi*!DTOR)

		y0 = wx/2. + rad_upper*cos(azi_lo*!DTOR)
		y1 = wx/2. + rad_lower*cos(azi_lo*!DTOR)
		y2 = wx/2. + rad_lower*cos(azi_hi*!DTOR)
		y3 = wx/2. + rad_upper*cos(azi_hi*!DTOR)

		polyfill, /device, [x0,x1,x2,x3], [y0,y1,y2,y3], color=oz[ix, iy]

	endfor
	endfor

	loadct, 0, /silent
	azi = findgen(361)*!DTOR
	rad = (wx/2.)*((90-74)/float(max(90-y)))
	plots, wx/2. + rad*sin(azi), wx/2. + rad*cos(azi), color = 255, thick = 3, /device

	azi = findgen(361)*!DTOR
	rad = (wx/2.)*((90-70)/float(max(90-y)))
	plots, wx/2. + rad*sin(azi), wx/2. + rad*cos(azi), color = 255, thick = 3, /device


	stop

end