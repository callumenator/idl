

;\\ This function overlays superdarn potential contours on a map. It accepts
;\\ superdarn data read in using red_superdarn_potentials.pro.

pro superdarn_potential_overlay, in_data, $	 ;\\ data for one timestamp read in from read_superdarn_potentials
								 mapstruct, $ ;\\ map structure used for plotting
								 range, $ ;\\ map data range (which includes zoom!)
								 levels = levels, $ ;\\ contour levels
								 ctable = ctable, $ ;\\ color table to use
								 color = color, $ ;\\ 2-element array [positive potential, negative potential]
								 thick = thick, $;\\ line thickness
								 bounds = bounds


	if not keyword_set(levels) then levels = [-33,-27,-21,-15,-9,-3,3,9,15,21,27,33,39]
	if not keyword_set(ctable) then ctable = 39
	if not keyword_set(color) then color = [250, 50]
	if not keyword_set(thick) then thick = 1
	if not keyword_set(bound) then bounds = [0,0,1,1]

	pot = in_data[0,*]
	glat = in_data[2,*]
	glon = in_data[3,*]
	mlat = in_data[4,*]
	mlon = in_data[5,*]

	x = ((90-glat))*sin(glon*!DTOR)
	y = ((90-glat))*cos(glon*!DTOR)
	z = pot/1000.

	CONTOUR, z, x, y, /irregular, PATH_XY=xy, PATH_INFO=info, /path_data_coords, levels=levels

	PLOT, range[[0,2]],  range[[1,3]], $
			/NODATA, XSTYLE=5, YSTYLE=5, color=53, $
	  		back=0, xticklen=.0001, yticklen=.0001, position=bounds, /noerase

	loadct, ctable, /silent
	cols = bytscl(info(*).value)
	FOR I = 1, (N_ELEMENTS(info) - 1 ) DO BEGIN
	   	S = [INDGEN(info(I).N), 0]
	   	tlon = atan(xy(0,INFO(I).OFFSET + S ),xy(1,INFO(I).OFFSET + S ))/!dtor
	   	tlat = 90 - sqrt( xy(0,INFO(I).OFFSET + S )^2. + xy(1,INFO(I).OFFSET + S )^2.)
	   	map_xy = map_proj_forward(tlon, tlat, map_structure=mapstruct)
	   	lab_xy = map_proj_forward(tlon(0), tlat(0), map_structure=mapstruct)
	   	if info(I).value lt 0 then cl = color[1] else cl = color[0]
	   	PLOTS, /data, map_xy, color=cl, thick = thick, clip = range, noclip=0
	   	PLOTS, /data, map_xy, color=cl, thick = thick, clip = range, noclip=0
	   	if keyword_set(label) then xyouts, /data, lab_xy(0), lab_xy(1), $
	   							   string(info(I).value, f='(f0.1)'), color = color, chars = 1.5
	ENDFOR

	if keyword_set(mark_centers) then begin
		max_pot_latlon = [lat(where(z eq max(z))),lon(where(z eq max(z)))/!dtor]
		min_pot_latlon = [lat(where(z eq min(z))),lon(where(z eq min(z)))/!dtor]
		max_pot_xy = map_proj_forward(max_pot_latlon(1), max_pot_latlon(0), map_structure=mapstruct)
		min_pot_xy = map_proj_forward(min_pot_latlon(1), min_pot_latlon(0), map_structure=mapstruct)
		plots, /data, max_pot_xy, color=color(1), psym=1, sym=symsize, thick = thick+1, clip = [xscale(0),yscale(0),xscale(1),yscale(1)], noclip=0
		plots, /data, min_pot_xy, color=color(0), psym=7, sym=symsize, thick = thick+1, clip = [xscale(0),yscale(0),xscale(1),yscale(1)], noclip=0
	endif

	pot_diff = max(z) - min(z)

end