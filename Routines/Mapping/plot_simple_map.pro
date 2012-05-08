
pro plot_simple_map, lat, lon, zoom, winx, winy, mapStruct=mapStruct, $
					 projection=projection, $
					 rotation=rotation, $
					 bounds=bounds, $
					 grid=grid, $
					 backColor=backColor, $				;\\ [color, ctable]
					 continentColor=continentColor, $	;\\ [color, ctable]
					 outlineColor=outlineColor, $		;\\ [color, ctable]
					 dataRange=dataRange, $
					 llRange=llRange, $
					 llBox=llBox, $
					 lores=lores, $
					 showBounds = showBounds, $
					 nodraw=nodraw


	;\\ To restore current colors after plotting...
	tvlct, r, g, b, /get

	showBounds_Thick = 1
	if not keyword_set(bounds) then bounds = [-0.02,-0.02,1,1]
	if not keyword_set(rotation) then rotation = 0
	if keyword_set(lores) then hires = 0 else hires = 1

	if not keyword_set(nodraw) then begin
		if keyword_set(backColor) then begin
			loadct, backColor[1], /silent
			polyfill, /normal, bounds[[0,0,2,2]], bounds[[1,3,3,1]], color = backColor[0]
		endif else begin
			loadct, 0, /silent
			polyfill, /normal, bounds[[0,0,2,2]], bounds[[1,3,3,1]], color = 255
		endelse
	endif

	;\\ Projection
		if not keyword_set(projection) then projection = 2
		if projection eq 106 or projection eq 110 then begin
			mapStruct = MAP_PROJ_INIT(projection, CENTER_LATITUDE=lat, CENTER_LONGITUDE=lon, /gctp)
		endif else begin
			mapStruct = MAP_PROJ_INIT(projection, CENTER_LATITUDE=lat, CENTER_LONGITUDE=lon, /gctp, rotation=rotation)
		endelse

	;\\ Create a plot window using the UV Cartesian range.
		!p.noerase = 1
		xscale = mapStruct.uv_box[[0,2]]/(float(zoom)*(float(winy)/float(winx)))
		yscale = mapStruct.uv_box[[1,3]]/(float(zoom))
		dataRange = [xscale[0], yscale[0], xscale[1], yscale[1]]
		llrange = map_proj_inverse(xscale, yscale, map = mapStruct)

		llBox = [ [map_proj_inverse(xscale[0], yscale[0], map = mapStruct)],$
				  [map_proj_inverse(xscale[0], yscale[1], map = mapStruct)],$
				  [map_proj_inverse(xscale[1], yscale[1], map = mapStruct)],$
				  [map_proj_inverse(xscale[1], yscale[0], map = mapStruct)]]

		if not keyword_set(showBounds) then begin
			PLOT, xscale, yscale, /NODATA, XSTYLE=5, YSTYLE=5, $
				  color=53, back=0, xticklen=.0001, yticklen=.0001, pos=bounds
		endif else begin
			blank = replicate(' ', 20)
			PLOT, xscale, yscale, /NODATA, XSTYLE=1, YSTYLE=1, $
				  color=0, back=0, xticks=1, yticks = 1, pos=bounds, $
				  xtickname = blank, ytickname = blank, xthick=showBounds_Thick, ythick=showBounds_Thick
		endelse

		if keyword_set(nodraw) then return

		if keyword_set(continentColor) then begin
			loadct, continentColor[1], /silent
			MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, hires=hires, mlinethick=1, color=continentColor[0], /fill_continents
		endif else begin
			loadct, 0, /silent
			MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, hires=hires, mlinethick=1, color=150, /fill_continents
		endelse

		!p.noerase = 1
		if keyword_set(outlineColor) then begin
			loadct, outlineColor[1], /silent
			MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, hires=hires, mlinethick=1, color=outlineColor[0]
		endif else begin
			;loadct, 0, /silent
			;MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, /hires, mlinethick=1, color=200
		endelse
		!p.noerase = 0

		if keyword_set(grid) then begin
			loadct, 0, /silent
			MAP_GRID, MAP_STRUCTURE=mapStruct, glinestyle=1, color=200, londel=5, latdel=2, $
					  latlab = -147, lonlab = 65, label=1
		endif

		if keyword_set(showBounds) then begin
			blank = replicate(' ', 20)
			PLOT, xscale, yscale, /NODATA, XSTYLE=1, YSTYLE=1, /noerase, $
				  color=0, xticks=1, yticks = 1, pos=bounds, $
				  xtickname = blank, ytickname = blank, $
				  xthick=showBounds_Thick, ythick=showBounds_Thick
		end

		tvlct, r, g, b
end