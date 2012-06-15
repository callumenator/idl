
;\\ Potentials...
	@w96

;\\ bi/tri static inversion routines
	@resolve_nStatic_wind

;\\ INITIATE THE USER INTERFACE
pro MIWF_Gui

	common miwf_common, guiData, miscData

	font = 'Ariel*Bold*15'
	base = widget_base(col = 2)

	scsze = get_screen_size(0)

	draw = widget_draw(base, xs = scsze[0]/3., ys = scsze[0]/3., /wheel_events, uval={name:'Draw'}, keyboard_events = 1)

	toolsBase = widget_base(base, col = 1)
	toolsTab = widget_tab(toolsBase, font=font)

	;\\ Filename list and data plot options, time labels, colors...
		dataListBase = widget_base(toolsTab, row = 10, title = 'Data')
		dataListLabel = widget_label(dataListBase, value='Data Files (Double Click to Load)', font=font)
		dataListList = widget_list(dataListBase, value=miscData.dataFilenames, ysize = 3, xsize = 65, uval={name:'DataLoad'}, font=font)
		dataListDel = widget_button(dataListBase, value='Clear', uval={name:'DataLoadClear'}, font=font)

	;\\ Tools for monostatic, bistatic and tristatic fitting, and blending...
		fitToolsBase = widget_base(toolsTab, row = 5, title = 'Fit Tools')
		fitToolsLabel = widget_label(fitToolsBase, value = 'Wind Fit Tools', font=font)

		fitToolsBaseTop = widget_base(fitToolsBase, row = 2)

		fitToolsBaseSub = widget_base(fitToolsBaseTop, row = 2)
		fitBtnBase = widget_base(fitToolsBaseSub, col = 2)
		fitMonoBtn = widget_button(fitBtnBase, value = 'Fit MonoStatic Winds', font=font, uval={name:'WindFitMono'}, xs = 130)
		fitMonoBtn = widget_button(fitBtnBase, value = 'Fit Poly Winds', font=font, uval={name:'WindFitPoly'}, xs = 130)
		fitBiBtn = widget_button(fitBtnBase, value = 'Fit BiStatic Winds', font=font, uval={name:'WindFitBi'}, xs = 130)
		fitBiBtn = widget_button(fitBtnBase, value = 'Fit BiStatic USolve', font=font, uval={name:'WindFitBi_USolve'}, xs = 130)
		fitTriBtn = widget_button(fitBtnBase, value = 'Fit TriStatic Winds', font=font, uval={name:'WindFitTri'}, xs = 130)
		fitBlendBtn = widget_button(fitBtnBase, value = 'Batch Fit', font=font, uval={name:'WindFitBlendBatch'}, xs = 130)

		fitBlendOptsBase = widget_base(fitToolsBaseSub, col = 1)
		fitBlendOptsLabs = tag_names(miscData.blendFitOpts)
		fitBlendOptsTable = widget_table(fitBlendOptsBase, value=miscData.blendFitOpts, /column_major, row_labels=fitBlendOptsLabs, $
									 /no_column_headers, /edit, uval={name:'FitBlendOptions'}, font=font, alignment=1, /kbrd_focus)


		fitPltBase = widget_base(fitToolsBaseTop, col = 2, /nonexclusive)
		fitBiBtn = widget_button(fitPltBase, value = 'Plot Poly Winds', font=font, uval={name:'WindPlotPoly'})
		fitBiBtn = widget_button(fitPltBase, value = 'Plot BiStatic Winds', font=font, uval={name:'WindPlotBi'})
		fitBiBtn = widget_button(fitPltBase, value = 'Plot BiStatic Vz', font=font, uval={name:'WindPlotBiVz'})
		fitBiBtn = widget_button(fitPltBase, value = 'Plot BiStatic Overlap', font=font, uval={name:'OverlapPlotBi'})
		fitTriBtn = widget_button(fitPltBase, value = 'Plot TriStatic Winds', font=font, uval={name:'WindPlotTri'})
		fitTriBtn = widget_button(fitPltBase, value = 'Plot TriStatic Overlap', font=font, uval={name:'OverlapPlotTri'})
		fitTriBtn = widget_button(fitPltBase, value = 'Plot Blended Winds', font=font, uval={name:'WindPlotBlend'})
		fitTriBtn = widget_button(fitPltBase, value = 'Plot Blend Data Bounds', font=font, uname='PlotBlendDataBounds')

		fitToolsProgBase = widget_base(fitToolsBase, col = 1, frame=0)
		fitToolsProgLabel = widget_label(fitToolsProgBase, value = 'Progress: ', font=font, uname = 'ProgressBarLabel', xs = 300)
		fitToolsProg = widget_draw(fitToolsProgBase, xs = 300, ys = 20, /align_center)

	;\\ Tools for changing map appearance...
		mapToolsBase = widget_base(toolsTab, row = 4, title = 'Map Tools')
		mapToolsLabel = widget_label(mapToolsBase, value = 'Map Tools', font=font)
		clearMapBtn = widget_button(mapToolsBase, value = 'Clear Map', font=font, uval={name:'ClearMap'})

		mapOptsLabel = widget_label(mapToolsBase, value = 'Map Options', font=font)
		mapOptsLabs = ['Grid On', 'Lon Delta', 'Lat Delta', 'Lon Labels', 'Lat Labels']
		mapOptsLabs = tag_names(miscData.mapOpts)
		mapOptsTable = widget_table(mapToolsBase, value=miscData.mapOpts, /column_major, row_labels=mapOptsLabs, $
									 /no_column_headers, /edit, uval={name:'MapOptions'}, font=font, alignment=1, /kbrd_focus)

	;\\ Vector plotting options...
		vectOptsBaseTop = widget_base(toolsTab, col = 2, title = 'Plotting Options')
		vectOptsBase = widget_base(vectOptsBaseTop, row = 3)
		vectOptsLabel = widget_label(vectOptsBase, value = 'Vector Options', font=font)
		vectOptsLabs = tag_names(miscData.vectorOpts)
		vectOptsTable = widget_table(vectOptsBase, value=miscData.vectorOpts, /column_major, row_labels=vectOptsLabs, $
									 /no_column_headers, /edit, uval={name:'VectorOptions'}, font=font, alignment=1, /kbrd_focus)

	;\\ Plotting options, and image capture...
		miscOptsBase = widget_base(vectOptsBaseTop, row = 2)
		miscOptsLabs = tag_names(miscData.miscOpts)
		miscOptsTable = widget_table(miscOptsBase, value=miscData.miscOpts, /column_major, row_labels=miscOptsLabs, $
									 /no_column_headers, /edit, uval={name:'MiscOptions'}, font=font, alignment=1, /kbrd_focus)

		captureBase = widget_base(vectOptsBaseTop, row = 5)
		miscOptsPNG = widget_button(captureBase, value='Capture PNG', uval={name:'CapturePNG'}, font=font)
		miscOptsJPG = widget_button(captureBase, value='Capture JPG', uval={name:'CaptureJPG'}, font=font)
		miscOptsEPS = widget_button(captureBase, value='Capture EPS', uval={name:'CaptureEPS'}, font=font)
		miscOptsPNGs = widget_button(captureBase, value='Capture PNG Sequence', uval={name:'CapturePNGSequence'}, font=font)
		miscOptsJPGs = widget_button(captureBase, value='Capture JPG Sequence', uval={name:'CaptureJPGSequence'}, font=font)
		miscOptsSAV = widget_button(captureBase, value='IDL-save Data', uval={name:'CaptureIDLSave'}, font=font)

	;\\ Realize...
		widget_control, base, /realize

	;\\ Store the gui settings...
		guiData = {base:base, $
				   toolsBase:toolsBase, $
				   toolsTab:toolsTab, $
				   dataListBase:dataListBase, $
				   dataListList:dataListList, $
				   progress:fitToolsProg, $
				   progressLabel:fitToolsProgLabel, $
				   timeSlider:0L, $
				   draw:draw, $
				   drawX:700., $
				   drawY:700., $
				   font:font}

end



;\\ HANDLE GUI EVENTS
pro MIWF_Event, event

	common miwf_common, guiData, miscData

	widget_control, get_uvalue = uval, event.id

	if size(uval, /type) eq 8 then begin
		case uval.name of
			'nStations':miscData.nStations = event.index + 1

			'ClearMap':begin
				miscData.plotOpts[*,*] = 0
				MIWF_DrawMap
			end

			'CapturePNG': MIWF_ScreenCapture, /png
			'CaptureJPG': MIWF_ScreenCapture, /jpg
			'CaptureEPS': MIWF_ScreenCapture, /eps
			'CapturePNGSequence': MIWF_ScreenCapture, /png, /sequence
			'CaptureJPGSequence': MIWF_ScreenCapture, /jpg, /sequence
			'CaptureIDLSave': MIWF_IDLSaveData

			'DataLoad':begin
				if event.clicks eq 2 then begin
					if event.index le miscData.nStations then begin
						fileName = dialog_pickfile(path=miscData.defaultDataPath)
						miscData.dataFilenames[event.index] = file_basename(fileName)
						miscData.dataFullpaths[event.index] = fileName
						widget_control, event.id, set_value = miscData.dataFilenames
						MIWF_LoadData, event.index
					endif
				endif
				if event.clicks eq 1 then begin
					miscData.list_selected = event.index
				endif
			end

			'DataLoadClear': begin
				MIWF_ClearData
			end

			'Draw': begin
				if event.type eq 7 then begin	;\\ wheel scroll
					if event.clicks eq -1 then miscData.mapZoom = miscData.mapZoom - 1
					if event.clicks eq 1 then miscData.mapZoom = miscData.mapZoom + 1
					MIWF_Refresh
				endif
				if event.type eq 6 and event.press eq 1 then begin	;\\ keyboard
					mapScroll = 1E5 * (7./miscData.mapZoom)
					case event.key of
						5: miscData.mapXoffset = miscData.mapXoffset - mapScroll
						6: miscData.mapXoffset = miscData.mapXoffset + mapScroll
						7: miscData.mapYoffset = miscData.mapYoffset + mapScroll
						8: miscData.mapYoffset = miscData.mapYoffset - mapScroll
					endcase
					MIWF_Refresh
				endif
			end

			'StationPlotWind':begin
				if uval.interp eq 1 then miscData.plotOpts[uval.station,5] = event.select $
					else miscData.plotOpts[uval.station,0] = event.select
				MIWF_Refresh
			end

			'StationPlotLOS':begin
				miscData.plotOpts[uval.station,1] = event.select
				MIWF_Refresh
			end

			'StationPlotZonemap':begin
				miscData.plotOpts[uval.station,2] = event.select
				MIWF_Refresh
			end

			'StationPlotTempmap':begin
				miscData.plotOpts[uval.station,3] = event.select
				MIWF_Refresh
			end

			'StationPlotBritemap':begin
				miscData.plotOpts[uval.station,4] = event.select
				MIWF_Refresh
			end

			'StationColor': begin
				if tag_names(event, /structure) eq 'WIDGET_KBRD_FOCUS' then begin
					if event.enter eq 0 then begin
						widget_control, get_value = newColStr, event.id
						miscData.colors[uval.station] = fix(newColStr)
						MIWF_Refresh
					endif
				endif
				if tag_names(event, /structure) eq 'WIDGET_TEXT_CH' then begin
					widget_control, get_value = newColStr, event.id
					miscData.colors[uval.station] = fix(newColStr)
					MIWF_Refresh
				endif
			end

			'StationCTable':begin
				if event.enter eq 0 then begin
					widget_control, get_value = newCTblStr, event.id
					miscData.ctables[uval.station] = fix(newCTblStr)
				endif
			end

			'TimeSlider':begin
				miscData.timeIndex = event.value - 1
				MIWF_Refresh
			end

			'VectorOptions':begin
				if tag_names(event, /structure) eq 'WIDGET_KBRD_FOCUS' then begin
					if event.enter eq 0 then begin
						widget_control, get_value = table, event.id
						miscData.vectorOpts = table
						MIWF_Refresh
					endif
				endif
				if tag_names(event, /structure) eq 'WIDGET_TABLE_CH' then begin
					widget_control, get_value = table, event.id
					miscData.vectorOpts = table
					MIWF_Refresh
				endif
			end

			'MapOptions':begin
				if tag_names(event, /structure) eq 'WIDGET_KBRD_FOCUS' then begin
					if event.enter eq 0 then begin
						widget_control, get_value = table, event.id
						miscData.mapOpts = table
						MIWF_Refresh
					endif
				endif
				if tag_names(event, /structure) eq 'WIDGET_TABLE_CH' then begin
					widget_control, get_value = table, event.id
					miscData.mapOpts = table
					MIWF_Refresh
				endif
			end

			'MiscOptions':begin
				if tag_names(event, /structure) eq 'WIDGET_KBRD_FOCUS' then begin
					if event.enter eq 0 then begin
						widget_control, get_value = table, event.id
						miscData.miscOpts = table
						MIWF_Refresh
					endif
				endif
				if tag_names(event, /structure) eq 'WIDGET_TABLE_CH' then begin
					widget_control, get_value = table, event.id
					miscData.miscOpts = table
					MIWF_Refresh
				endif
			end

			'FitBlendOptions':begin
				if tag_names(event, /structure) eq 'WIDGET_KBRD_FOCUS' then begin
					if event.enter eq 0 then begin
						widget_control, get_value = table, event.id
						miscData.blendFitOpts = table
					endif
				endif
				if tag_names(event, /structure) eq 'WIDGET_TABLE_CH' then begin
					widget_control, get_value = table, event.id
					miscData.blendFitOpts = table
				endif
			end

			'WindFitMono':begin
				MIWF_FitMonoStatic
				MIWF_Refresh
			end
			'WindFitPoly':begin
				MIWF_FitPoly
				MIWF_Refresh
			end
			'WindPlotPoly': begin
				miscData.polyPlot = event.select
				MIWF_Refresh
			end
			'WindFitBi':begin
				MIWF_FitBiStatic
				MIWF_Refresh
			end
			'WindFitBi_USolve':begin
				MIWF_FitBiStatic_Usolve
				MIWF_Refresh
			end
			'WindPlotBi':begin
				miscData.biPlot = event.select
				MIWF_Refresh
			end
			'WindPlotBiVz':begin
				if event.select eq 1 then MIWF_PlotBistatic, /vertical
			end
			'OverlapPlotBi':begin
				miscData.biPlotOverlap = event.select
				MIWF_Refresh
			end
			'WindFitTri':begin
				MIWF_FitTriStatic
				MIWF_Refresh
			end
			'WindPlotTri':begin
				miscData.triPlot = event.select
				MIWF_Refresh
			end
			'OverlapPlotTri':begin
				miscData.triPlotOverlap = event.select
				MIWF_Refresh
			end
			'WindFitBlend':begin
				MIWF_WindFitBlend
				MIWF_Refresh
			end
			'WindPlotBlend':begin
				miscData.blendPlot = event.select
				MIWF_Refresh
			end
			'WindFitBlendAll':begin
				MIWF_WindFitBlend, /batch
			end
			'WindFitBlendBatch':begin
				MIWF_WindFit_Batch, /fit_mono, /fit_bi, /fit_usolve, file_filter = ['*2010*sky*.nc']
			end

			else:
		endcase
	endif

end



;\\ CLEAN UP AFTER CLOSING, BASICALLY FREE ALL THE POINTERS
pro MIWF_EndSession, event

	common miwf_common, guiData, miscData

	;\\ Clean up all those pointers...
		for s = 0, miscData.maxStations - 1 do begin
			if ptr_valid(miscData.metaData[s]) then ptr_free, miscData.metaData[s]
			if ptr_valid(miscData.windData[s]) then ptr_free, miscData.windData[s]
			if ptr_valid(miscData.spekData[s]) then ptr_free, miscData.spekData[s]
			if ptr_valid(miscData.spekDataX[s]) then ptr_free, miscData.spekDataX[s]
			if ptr_valid(miscData.zoneCenters[s]) then ptr_free, miscData.zoneCenters[s]
			if ptr_valid(miscData.stnTimes[s]) then ptr_free, miscData.stnTimes[s]
			if ptr_valid(miscData.stnIndices[s]) then ptr_free, miscData.stnIndices[s]
		endfor

		if ptr_valid(miscData.mapStructure) then ptr_free, miscData.mapStructure
		if ptr_valid(miscData.allTimes) then ptr_free, miscData.allTimes
		if ptr_valid(miscData.monoFits) then ptr_free, miscData.monoFits
		if ptr_valid(miscData.polyFit) then ptr_free, miscData.polyFit
		if ptr_valid(miscData.biFits) then ptr_free, miscData.biFits
		if ptr_valid(miscData.triFits) then ptr_free, miscData.triFits
		if ptr_valid(miscData.blendFit) then ptr_free, miscData.blendFit
		if ptr_valid(miscData.potentialData) then ptr_free, miscData.potentialData
end



;\\ DRAW THE MAP INTO THE GUI WINDOW USING THE CURRENT MAP SETTINGS
pro MIWF_DrawMap

	common miwf_common, guiData, miscData

	if miscData.epsDraw eq 0 then begin
		widget_control, get_value = windId, guiData.draw
		geom = widget_info(guiData.draw, /geometry)
		winX = geom.xsize
		winY = geom.ysize
		wset, windId
	endif else begin
		winX = 10.
		winY = 10.
	endelse

		loadct, miscData.mapOpts.backCTable, /silent
		polyfill, /normal, [0,0,1,1], [0,1,1,0], color = miscData.mapOpts.backColor

	;\\ Projection
		mapStruct = MAP_PROJ_INIT(2, CENTER_LATITUDE=miscData.mapCenter[0], $
									 CENTER_LONGITUDE=miscData.mapCenter[1])
		*miscData.mapStructure = mapStruct

	;\\ Create a plot window using the UV Cartesian range...
		!p.noerase = 1
		if miscData.mapZoom le 0 then miscData.mapZoom = .01
		xscale = mapStruct.uv_box[[0,2]]/(miscData.mapZoom*(winY/winX)) + miscData.mapXoffset
		yscale = mapStruct.uv_box[[1,3]]/(miscData.mapZoom) + miscData.mapYoffset
		PLOT, xscale, yscale, /NODATA, XSTYLE=5, YSTYLE=5, $
			  color=53, back=0, xticklen=.0001, yticklen=.0001, pos=[0,0,1,1]

	;\\ Store the current axes...
		miscData.mapAxes = {x:xscale, y:yscale}

		loadct, miscData.mapOpts.continentCTable, /silent
		MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, /hires, mlinethick=1, color=miscData.mapOpts.continentColor, /fill_continents
		loadct, miscData.mapOpts.coastCTable, /silent
		!p.noerase = 1 & MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, /hires, mlinethick=1, color=miscData.mapOpts.coastColor & !p.noerase = 0

		if miscData.mapOpts.gridOn eq 1 then begin
			MAP_GRID, MAP_STRUCTURE=mapStruct, glinestyle=1, color=200, londel=miscData.mapOpts.lonDelta, $
					  latdel=miscData.mapOpts.latDelta, latlab = miscData.mapOpts.latLabels, $
					  lonlab = miscData.mapOpts.lonLabels, label=1
		endif
end



;\\ LOAD DATA, USING THE FILENAMES LISTED IN THE GUI LIST BOX
pro MIWF_LoadData, index, return_code

	common miwf_common, guiData, miscData

		return_code = 'null'
		s = index
		if miscData.dataFullpaths[s] eq '' then return

		sdi3k_read_netcdf_data, miscData.dataFullpaths[s], metadata = metadata, winds = winds, $
							    spekfits = speks, zone_centers = centers

		if size(winds, /type) ne 8 then begin
			return_code = 'no_wind_data'
			return
		endif

		if s eq miscData.nStations then miscData.nStations ++

		*miscData.metaData[s] = metadata
		*miscData.windData[s] = winds
		*miscData.spekData[s] = speks
		*miscData.zoneCenters[s] = centers

	;\\ Flat field...
		;sdi3k_auto_flat, metadata, wind_offset, extend_valid_time = 10*3600.*24.
		;print, metadata.site_code + ' WIND OFFSET: ', total(abs(wind_offset))

	;\\ Generate smoothed, drift corrected, etc versions for fitting...
		spekX = speks
		for kk = 0, n_elements(spekX.velocity[0])-1 do spekX[kk].velocity[1:*] = spekX[kk].velocity[1:*] ;- wind_offset[1:*]
		sdi3k_drift_correct, spekX, metadata, /force, /data_based

		if metadata.site_code eq 'PKR' then dift_type = 'data' else drift_type = 'both'
		meta_loader, ml_out, filename=miscData.dataFullpaths[s], filter=['*'+metadata.site_code+'*', '*630*'], drift_type=drift_type, /no_mono, /no_bi, /no_usolve
		res = execute('spekX = ml_out.' + metadata.site_code + '.speks_dc')
		for kk = 0, n_elements(spekX.velocity[0])-1 do spekX[kk].velocity[1:*] = spekX[kk].velocity[1:*]; - wind_offset[1:*]

	    sdi3k_remove_radial_residual, metadata, spekX, parname='VELOCITY'
	    spekX.velocity = metadata.channels_to_velocity*spekX.velocity
	    posarr = spekX.velocity
	    vertical = reform(posarr[0,*])
	    sdi3k_timesmooth_fits,  posarr, winds[0].time_smoothing, metadata
	    sdi3k_spacesmooth_fits, posarr, winds[0].space_smoothing, metadata, centers
	    spekX.velocity = posarr
	    spekX.velocity[0] = vertical
	    nobs = n_elements(spekX)
    	if nobs gt 2 then spekX.velocity = spekX.velocity - $
    		total(spekX(1:nobs-2).velocity(0))/n_elements(spekX(1:nobs-2).velocity(0))

	;\\ Modify the tester files, to test bistatic divergence/vertical wind analysis
		;tester = strmatch(miscData.dataFullpaths[s], '*TESTER*')
		;if tester eq 1 then begin
		;	print, 'Tester mod'
		;	for z = 0, metadata.nzones - 1 do begin
		;		spekX.velocity[z] = spekX.velocity[z] + 100*cos(winds.zeniths[z]*!dtor)
		;	endfor
		;endif

		*miscData.spekDataX[s] = spekX



	allTimes = [0.]
	for s = 0, miscData.nStations - 1 do begin
		if ptr_valid(miscData.windData[s]) then begin
			ut = js2ut(0.5*((*miscData.windData[s]).start_time + (*miscData.windData[s]).end_time))
			allTimes = [allTimes, ut]
		endif
	endfor
	if n_elements(allTimes) gt 1 then begin
		allTimes = allTimes[1:*]
		order = sort(allTimes)
		allTimes = allTimes[order]
		miscData.timeIndex = 0
		*miscData.allTimes = allTimes
	endif


	for s = 0, miscData.nStations - 1 do begin

		ut = js2ut(0.5*((*miscData.windData[s]).start_time + (*miscData.windData[s]).start_time))
		indices = indgen(n_elements(*miscData.windData[s]))

		;\\ Get average intensity, use it to very roughly match the intensities between stations
		;\\ This could be done better by comparing overlap regions...
			if s eq 0 then begin
				s0aveIntens = median((*miscData.spekData[s])[*].intensity)
				miscData.intensGains[s] = 1.0
			endif else begin
				saveIntens = median((*miscData.spekData[s])[*].intensity)
				miscData.intensGains[s] = s0aveIntens / saveIntens
			endelse

		;\\ Generate station exposure indices for each allTime index
			indicesI = fix(interpol(indices, ut, allTimes))
			pts = where(indicesI lt 0, npts)
			if npts gt 0 then indicesI[pts] = 0
			pts = where(indicesI ge n_elements(*miscData.windData[s]), npts)
			if npts gt 0 then indicesI[pts] = n_elements(*miscData.windData[s]) - 1
			ut = ut[indicesI]

		;\\ Store the indices and the times...
			(*miscData.stnTimes[s]) = ut
			(*miscData.stnIndices[s]) = indicesI

		baseID = widget_info(guiData.base, find_by_uname = 'station'+string(s,f='(i0)')+'base')
		if widget_info(baseId, /valid_id) eq 1 then widget_control, /destroy, baseId

		newStnBase = widget_base(guiData.dataListBase, row = 6, frame=1, uname='station'+string(s,f='(i0)')+'base', /base_align_center)

		nameInfo = 'Station ' + string(s+1, f='(i0)') + ': ' + (*miscData.metadata[s]).site
		nameInfo += ' (' + (*miscData.metadata[s]).site_code + '), '
		nameInfo += date_str_from_js((*miscData.windData[s])[0].start_time, /day_month_year) + ', '
		nameInfo += string((*miscData.metaData[s]).wavelength_nm, f='(f0.1)') + ' nm'

		newStnLabel = widget_label(newStnBase, value = nameInfo, font=guiData.font, xsize = 400)

		newStnInfoBase = widget_base(newStnBase, col = 2)
		newStnTime = widget_label(newStnInfoBase, value='Time: ' + $
								  time_str_from_decimalut((*miscData.stnTimes[s])[miscData.timeIndex]) + ' UT', $
						 		  font=guiData.font, uname = 'Station' + string(s, f='(i0)') + 'TimeLabel')

		newStnColorBase = widget_base(newStnBase, col = 6)
		newStnColorLabel1 = widget_label(newStnColorBase, value='Color: ', font=guiData.font)
		newStnColorText1 = widget_text(newStnColorbase, value = string(miscData.colors[s], f='(i0)'), $
									   font=guiData.font, /edit, xsize = 5, uval={name:'StationColor', station:s}, /kbrd_focus)
		newStnColorLabel2 = widget_label(newStnColorBase, value='CTable: ', font=guiData.font)
		newStnColorText2 = widget_text(newStnColorbase, value = string(miscData.ctables[s], f='(i0)'), $
									   font=guiData.font, /edit, xsize = 5, uval={name:'StationCTable', station:s}, /kbrd_focus)


		newStnToolBase = widget_base(newStnBase, col = 3, /nonexclusive)

	   	newStnWindPlot = widget_button(newStnToolBase, value = 'Plot Wind', font=guiData.font, $
									   uval={name:'StationPlotWind', station:s, interp:0})
			widget_control, set_button = miscData.plotOpts[s,0], newStnWindPlot

		newStnIWindPlot = widget_button(newStnToolBase, value = 'Plot Wind Interp', font=guiData.font, $
									   uval={name:'StationPlotWind', station:s, interp:1})
			widget_control, set_button = miscData.plotOpts[s,5], newStnIWindPlot

		newStnLosPlot = widget_button(newStnToolBase, value = 'Plot LOS', font=guiData.font, $
									  uval={name:'StationPlotLOS', station:s})
			widget_control, set_button = miscData.plotOpts[s,1], newStnLosPlot

		newStnZmapPlot = widget_button(newStnToolBase, value = 'Plot ZoneMap', font=guiData.font, $
									   uval={name:'StationPlotZonemap', station:s})
			widget_control, set_button = miscData.plotOpts[s,2], newStnZmapPlot

		newStnTempPlot = widget_button(newStnToolBase, value = 'Plot Temp. Map', font=guiData.font, $
									   uval={name:'StationPlotTempmap', station:s})
			widget_control, set_button = miscData.plotOpts[s,3], newStnTempPlot

		newStnBritePlot = widget_button(newStnToolBase, value = 'Plot Intens. Map', font=guiData.font, $
									   uval={name:'StationPlotBritemap', station:s})
			widget_control, set_button = miscData.plotOpts[s,4], newStnBritePlot
	endfor

	;\\ Add a time slider
		slideID = widget_info(guiData.base, find_by_uname = 'TimeSliderBase')
		if widget_info(slideID, /valid_id) eq 1 then widget_control, /destroy, slideID

		if n_elements(allTimes) gt 1 then begin
			timeSlideBase = widget_base(guiData.toolsBase, uname = 'TimeSliderBase', col = 1, frame = 1, /align_center)
			timeSlideLabel = widget_label(timeSlideBase, value = 'Exposure Select', font=guiData.font)
			timeSlide= widget_slider(timeSlideBase, minimum=1, maximum=n_elements(allTimes), $
									 font=guiData.font, uval={name:'TimeSlider'}, xsize = 300, /align_center)
			guiData.timeSlider = timeSlide
		endif

	return_code = 'success'

end


;\\ CLEAR THE LOADED DATA FILES
pro MIWF_ClearData

	common miwf_common, guiData, miscData

		for s = 0, miscData.maxStations - 1 do begin
			if ptr_valid(miscData.metaData[s]) then *miscData.metaData[s] = 0
			if ptr_valid(miscData.windData[s]) then *miscData.windData[s] = 0
			if ptr_valid(miscData.spekData[s]) then *miscData.spekData[s] = 0
			if ptr_valid(miscData.spekDataX[s]) then *miscData.spekDataX[s] = 0
			if ptr_valid(miscData.zoneCenters[s]) then *miscData.zoneCenters[s] = 0
			if ptr_valid(miscData.stnTimes[s]) then *miscData.stnTimes[s] = 0
			if ptr_valid(miscData.stnIndices[s]) then *miscData.stnIndices[s] = 0
		endfor

		if ptr_valid(miscData.allTimes) then *miscData.allTimes = 0
		if ptr_valid(miscData.monoFits) then *miscData.monoFits = 0
		if ptr_valid(miscData.polyFit) then *miscData.polyFit = 0
		if ptr_valid(miscData.biFits) then *miscData.biFits = 0
		if ptr_valid(miscData.triFits) then *miscData.triFits = 0
		if ptr_valid(miscData.blendFit) then *miscData.blendFit = 0
		if ptr_valid(miscData.potentialData) then *miscData.potentialData = 0

		for s = 0, miscData.nstations - 1 do begin
			baseID = widget_info(guiData.base, find_by_uname = 'station'+string(s,f='(i0)')+'base')
			if widget_info(baseId, /valid_id) eq 1 then widget_control, /destroy, baseId
		endfor

		heap_gc

		miscData.nStations = 0
		miscData.dataFilenames[*] = ''
		miscData.dataFullpaths[*] = ''

		widget_control, guiData.datalistlist, set_value = miscData.dataFilenames
end



;\\ PLOT THE MONOSTATIC WINDS, OR LINE-OF-SIGHT WINDS, FOR A GIVEN STATION
pro MIWF_PlotFittedWinds, stationIndex, los=los, interp=interp

	common miwf_common, guiData, miscData

	s = stationIndex
	if size((*miscData.windData[s]), /type) ne 8 then return
	expIndex = (*miscData.stnIndices[s])[miscData.timeIndex]

	diff = 180 - ((*miscData.windData[s])[0].azimuths[2] - (*miscData.metadata[s]).oval_angle)
	rads = [0,(*miscData.metadata[s]).zone_radii[0:(*miscData.metadata[s]).rings-1]]/100.
	secs = (*miscData.metadata[s]).zone_sectors[0:(*miscData.metadata[s]).rings-1]
	azis = (*miscData.windData[s])[0].azimuths + diff
	zens = (*miscData.windData[s])[0].zeniths
	ring = get_zone_rings(zens)

	case (*miscData.metadata[s]).wavelength_nm of
		557.7: alt = 120.
		589.0: alt = 92.
		630.0: alt = 240.
		else: alt = 0.
	endcase

	MIWF_GetInterpolates, s, miscData.timeIndex, interps

	angle = (-1.0)*(*miscData.metaData[s]).oval_angle*!dtor
	;zonalWind = ((*miscData.windData[s])[expIndex]).zonal_wind
	;meridWind = ((*miscData.windData[s])[expIndex]).meridional_wind
	zonalWind = interps.zonal
	meridWind = interps.merid
	geoZonalWind = zonalWind*cos(angle) - meridWind*sin(angle)
	geoMeridWind = zonalWind*sin(angle) + meridWind*cos(angle)

	;loswind = (*miscData.spekDataX[s]).velocity
	loswind = interps.los

	loadct, miscData.ctables[s], /silent
	if miscData.epsDraw eq 1 then hsizeMult = 15. else hsizeMult = 1.
	if not keyword_set(interp) then begin

;		;\\ Plot the winds already in the netcdf file
;		for z = 0, n_elements(zens) - 1 do begin
;			;\\ Coords of zone center
;				dist = get_great_circle_length(zens[z], alt)
;				endpt = get_end_lat_lon((*miscData.metadata[s]).latitude, (*miscData.metadata[s]).longitude, dist, azis[z])
;
;				if not keyword_set(los) then begin
;					xcomp = geoZonalWind[z]
;					ycomp = geoMeridWind[z]
;					magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*miscData.vectorOpts.scale
;					azimuth = atan(xcomp, ycomp)/!DTOR
;				endif else begin
;					magnitude =  loswind[z]*miscData.vectorOpts.scale
;					azimuth = azis[z]
;					if z eq 0 then magnitude = 0
;				endelse
;
;				get_mapped_vector_components, *miscData.mapStructure, endPt[0], endPt[1], magnitude, azimuth, $
;											  mapXBase, mapYBase, mapXlen, mapYlen
;
;					arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
;						   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
;						   color = miscData.colors[s], thick = miscData.vectorOpts.thick, $
;						   solid = miscData.vectorOpts.solid, /data, $
;						   hsize = miscData.vectorOpts.hsize*hsizeMult
;
;		endfor


		;\\ And plot my fitted ones for comparison
		if size(*miscData.monoFits, /type) gt 2 and not keyword_set(los) then begin
			mfits = reform((*miscData.monoFits)[miscData.timeIndex,*])
			pts = where(mfits.station eq (*miscData.metaData[s]).site_code, npts)
			for mm = 0, npts - 1 do begin
				xcomp = mfits[pts[mm]].zonal
				ycomp = mfits[pts[mm]].merid
				magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*miscData.vectorOpts.scale
				azimuth = atan(xcomp, ycomp)/!DTOR
				get_mapped_vector_components, *miscData.mapStructure, mfits[pts[mm]].lat, mfits[pts[mm]].lon, magnitude, azimuth, $
											  mapXBase, mapYBase, mapXlen, mapYlen

				arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
					   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   color = miscData.colors[s], thick = miscData.vectorOpts.thick, $
					   solid = miscData.vectorOpts.solid, /data, $
					   hsize = miscData.vectorOpts.hsize*hsizeMult
			endfor
		endif

	endif else begin

		xlats = fltarr((*miscData.metaData[s]).nzones)
		xlons = fltarr((*miscData.metaData[s]).nzones)
		for z = 0, (*miscData.metaData[s]).nzones - 1 do begin
			dist = get_great_circle_length(zens[z], alt)
			endpt = get_end_lat_lon((*miscData.metaData[s]).latitude, (*miscData.metaData[s]).longitude, dist, azis[z])
			xlats[z] = endpt[0]
			xlons[z] = endpt[1]
		endfor

		nx = 80.
		ny = 80.
		TRIANGULATE, xlats, xlons, tr, b
		latsGrid = TRIGRID(xlats, xlons, xlats, tr, nx=nx, ny=ny, /quintic, missing=-999)
		lonsGrid = TRIGRID(xlats, xlons, xlons, tr, nx=nx, ny=ny, /quintic, missing=-999)
		meridGrid = TRIGRID(xlats, xlons, geoMeridWind, tr, nx=nx, ny=ny, /quintic, missing=-999)
		zonalGrid = TRIGRID(xlats, xlons, geoZonalWind, tr, nx=nx, ny=ny, /quintic, missing=-999)

		;\\ This plots in a square grid, sampled at given resolution, but looks better done in circles, below...
		;	for xx = 0, nx - 1, 7 do begin
		;	for yy = 0, ny - 1, 7 do begin
		;		if latsGrid[xx,yy] eq -999 then continue
		;
		;		xcomp = zonalGrid[xx,yy]
		;		ycomp = meridGrid[xx,yy]
		;		magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*miscData.vectorOpts.scale
		;		azimuth = atan(xcomp, ycomp)/!DTOR
		;		get_mapped_vector_components, *miscData.mapStructure, latsGrid[xx,yy], lonsGrid[xx,yy], magnitude, azimuth, $
		;										  mapXBase, mapYBase, mapXlen, mapYlen
		;
		;		arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
		;			   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
		;			   color = miscData.colors[s], thick = miscData.vectorOpts.thick, $
		;			   solid = miscData.vectorOpts.solid, /data, $
		;			   hsize = miscData.vectorOpts.hsize*hsizeMult
		;	endfor
		;	endfor

		;\\ Plot gridded data in concentric circles...
			arcLen = 8. 	;\\ pixels
			nRads = 7.
			maxRad = nx/2.
			xCen = nx/2.
			yCen = ny/2.
			for rr = 0, nrads - 1 do begin
				thisRad = ((rr+1)*(maxRad / nRads))*.9
				angleWid = (arcLen / thisRad)/!dtor
				angs = findgen(ceil(360./angleWid))
				angs = 2*!PI*angs/max(angs)
				xPts = (fix(xCen + thisRad*cos(angs)))
				yPts = (fix(yCen + thisRad*sin(angs)))

				for pp = 0, n_elements(xPts) - 1 do begin
					xcomp = zonalGrid[xPts[pp],yPts[pp]]
					ycomp = meridGrid[xPts[pp],yPts[pp]]

					magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*miscData.vectorOpts.scale
					azimuth = atan(xcomp, ycomp)/!DTOR

					get_mapped_vector_components, *miscData.mapStructure, latsGrid[xPts[pp],yPts[pp]], $
												  lonsGrid[xPts[pp],yPts[pp]], magnitude, azimuth, $
												  mapXBase, mapYBase, mapXlen, mapYlen

					arrow, 	mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
					   		mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   		color = miscData.colors[s], thick = miscData.vectorOpts.thick, $
					   		solid = miscData.vectorOpts.solid, /data, $
					   		hsize = miscData.vectorOpts.hsize*hsizeMult
				endfor
			endfor

	endelse

	MIWF_PlotWindScale
end



;\\ PLOT THE ZONE BOUNDARY OUTLINES FOR A GIVEN STATION, OR BISTATIC OVERLAP ZONES
pro MIWF_PlotZonemap, stationIndex, $
					  biStaticOverlap=biStaticOverlap

	common miwf_common, guiData, miscData
	s = stationIndex

	if keyword_set(biStaticOverlap) then begin
		for st1 = 0, miscData.nStations - 1 do begin
		for st2 = st1+1, miscData.nStations - 1 do begin

			case (*miscData.metadata[st1]).wavelength_nm of
				557.7: alt = 120.
				589.0: alt = 92.
				630.0: alt = 240.
				else: alt = 0.
			endcase

			stnName = [(*miscData.metaData[st1]).site_code, (*miscData.metaData[st2]).site_code]
			stnName = stnName[sort(stnName)]
			saveName = miscData.savedDataPath + 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '_' + string(alt, f='(i0)') + '.saved'
			if file_test(saveName) eq 1 then begin
				restore, saveName
			endif else begin
				print, 'No Overlap File: ' + saveName
				continue
			endelse

			;\\ To check for dotp, zenith angle, overlap cutoffs we need these...
				diff = 180 - ((*miscData.windData[st1])[0].azimuths[2] - (*miscData.metadata[st1]).oval_angle)
				azis1 = (*miscData.windData[st1])[0].azimuths + diff
				zens1 = (*miscData.windData[st1])[0].zeniths
				diff = 180 - ((*miscData.windData[st2])[0].azimuths[2] - (*miscData.metadata[st2]).oval_angle)
				azis2 = (*miscData.windData[st2])[0].azimuths + diff
				zens2 = (*miscData.windData[st2])[0].zeniths
				lons = [(*miscData.metadata[st1]).longitude, (*miscData.metadata[st2]).longitude]
				lats = [(*miscData.metadata[st1]).latitude, (*miscData.metadata[st2]).latitude]
				if lats[0] gt lats[1] then begin
					minIdx = 1
					maxIdx = 0
				endif else begin
					minIdx = 0
					maxIdx = 1
				endelse

			st1_index = (where(zone_overlap.stationNames eq stnName[st1]))[0]
			st2_index = (where(zone_overlap.stationNames eq stnName[st2]))[0]
			pts = where(max(zone_overlap.overlaps, dimension=2) gt miscData.blendFitOpts.biZoneOverlap, nBiPts)

			if nBiPts eq 0 then return

			pairs = zone_overlap.pairs

			for k = 0, nBiPts - 1 do begin

				stns = [st1,st2]
				stnsI = [st1_index, st2_index]
				for sidx = 0, 1 do begin
					s = stns[sidx]
					rads = [0,(*miscData.metadata[s]).zone_radii[0:(*miscData.metadata[s]).rings-1]]/100.
					secs = (*miscData.metadata[s]).zone_sectors[0:(*miscData.metadata[s]).rings-1]
					fov = (*miscData.metaData[s]).sky_fov_deg

					calculate_bistatic_params, 0, 0, lats, lons, $
						[azis1[pairs[pts[k],stnsI[0]]],azis2[pairs[pts[k],stnsI[1]]]], $
						[zens1[pairs[pts[k],stnsI[0]]],zens2[pairs[pts[k],stnsI[1]]]], [alt, alt], out

					if out.dotProduct gt miscData.blendFitOpts.biMaxDotProduct then continue
					if abs(out.mAngle) lt miscData.blendFitOpts.biAngleCutoff then continue

					plot_zonemap_on_map,(*miscData.metaData[s]).latitude, (*miscData.metaData[s]).longitude, rads, secs, alt, $
										180 + (*miscData.metaData[s]).oval_angle, fov, $
										*miscData.mapStructure, front_color=miscData.colors[s], $
										onlyTheseZones=[pairs[pts[k],stnsI[sidx]]]
				endfor

			endfor

		endfor
		endfor
	endif else begin

		case (*miscData.metadata[s]).wavelength_nm of
			557.7: alt = 120.
			589.0: alt = 92.
			630.0: alt = 240.
			else: alt = 0.
		endcase

		rads = [0,(*miscData.metadata[s]).zone_radii[0:(*miscData.metadata[s]).rings-1]]/100.
		secs = (*miscData.metadata[s]).zone_sectors[0:(*miscData.metadata[s]).rings-1]
		fov = (*miscData.metaData[s]).sky_fov_deg

		plot_zonemap_on_map,(*miscData.metaData[s]).latitude, (*miscData.metaData[s]).longitude, rads, secs, alt, $
							180 + (*miscData.metaData[s]).oval_angle, fov, $
							*miscData.mapStructure, front_color=miscData.colors[s]
	endelse

end



;\\ PLOT LARGE PIXELS TO THE SCREEN REPRESENTING INTERPOLATED TEMPERATURE, INTENSITY, ETC, FOR GIVEN STATION
pro MIWF_PlotParamMap, stationIndex, $
					   temp=temp, $
					   brite=brite

	common miwf_common, guiData, miscData

	s = stationIndex
	expIndex = (*miscData.stnIndices[s])[miscData.timeIndex]
	if keyword_set(temp) then begin
		loadct, 39, /silent
		sParam = (*miscData.spekData[s])[expIndex].temperature
	endif
	if keyword_set(brite) then begin
		loadct, 8, /silent
		site_code = (*miscData.metadata[s]).site_code
		sParam = (*miscData.spekData[s])[expIndex].intensity*miscData.intensGains[s]/pixels_per_zone((*miscData.metaData[s]), /rel)
	endif

	case (*miscData.metadata[s]).wavelength_nm of
		557.7: alt = 120.
		589.0: alt = 92.
		630.0: alt = 240.
		else: alt = 0.
	endcase

	diff = 180 - ((*miscData.windData[s])[0].azimuths[2] - (*miscData.metadata[s]).oval_angle)
	azis = (*miscData.windData[s])[0].azimuths + diff
	zens = (*miscData.windData[s])[0].zeniths

	xlats = fltarr((*miscData.metaData[s]).nzones)
	xlons = fltarr((*miscData.metaData[s]).nzones)
	for z = 0, (*miscData.metaData[s]).nzones - 1 do begin
		dist = get_great_circle_length(zens[z], alt)
		endpt = get_end_lat_lon((*miscData.metaData[s]).latitude, (*miscData.metaData[s]).longitude, dist, azis[z])
		xlats[z] = endpt[0]
		xlons[z] = endpt[1]
	endfor

	nx = 80
	ny = 80
	TRIANGULATE, xlats, xlons, tr, b
	latsGrid = TRIGRID(xlats, xlons, xlats, tr, nx=nx, ny=ny, /quintic, missing=-999)
	lonsGrid = TRIGRID(xlats, xlons, xlons, tr, nx=nx, ny=ny, /quintic, missing=-999)
	paramGrid = TRIGRID(xlats, xlons, sParam, tr, nx=nx, ny=ny, /quintic, missing=-999)

	if keyword_set(brite) then begin
		scale_to_range, paramGrid, miscData.miscOpts.intensMin, miscData.miscOpts.intensMax, sParamG
	endif
	if keyword_set(temp) then begin
		scale_to_range, paramGrid, miscData.miscOpts.tempMin, miscData.miscOpts.tempMax, sParamG
	endif

	for xx = 0, nx - 1 do begin
	for yy = 0, ny - 1 do begin
		if paramGrid[xx,yy] eq -999 then continue
		mapxy = map_proj_forward(lonsGrid[xx,yy], latsGrid[xx,yy], map_struc = *miscData.mapStructure)
		plots, /data, mapxy, psym=6, sym = 1, thick = 6, color = sParamG[xx,yy]
	endfor
	endfor

end



;\\ PLOT THE RESULT OF BISTATIC FITS, STORED IN THE MISCDATA STRUCTURE, IF AVAILABLE
pro MIWF_PlotBiStatic, vertical=vertical

	common miwf_common, guiData, miscData

	if size(*miscData.biFits, /type) eq 2 or $
		size(*miscData.biFits, /type) eq 0 then return

	if miscData.epsDraw eq 1 then hsizeMult = 15. else hsizeMult = 1.
	if not keyword_set(vertical) then begin
		biFits = reform((*miscData.biFits)[miscData.timeIndex, *])
		loadct, 39, /silent
		for k = 0, n_elements(biFits) - 1 do begin

			if abs(biFits[k].mAngle) lt miscData.blendFitOpts.biAngleCutoff or $
			   max(biFits[k].overlap) lt miscData.blendFitOpts.biZoneOverlap or $
			   (biFits[k].obsDot) gt miscData.blendFitOpts.biMaxDotProduct then begin
				continue
			endif

			if abs(biFits[k].merr) gt miscData.blendFitOpts.biMaxAbsError or $
			   abs(biFits[k].lerr) gt miscData.blendFitOpts.biMaxAbsError then continue

			out = project_bistatic_fit(biFits[k], 0.0)
			north = out[1]
			east = out[0]

			magnitude = sqrt(east*east + north*north)*miscData.vectorOpts.scale
			azimuth = atan(east, north)/!DTOR

			get_mapped_vector_components, *miscData.mapStructure, biFits[k].lat, biFits[k].lon, magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			if miscData.vectorOpts.scale eq 1 then begin
				plots, /data, noclip = 0, color = miscData.vectorOpts.biColor, $
					   thick = miscData.vectorOpts.thick, mapXBase, mapYBase, psym=6, sym=miscData.vectorOpts.hsize
			endif else begin
				arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
					   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   color = miscData.vectorOpts.biColor, thick = miscData.vectorOpts.thick, $
					   solid = miscData.vectorOpts.solid, /data, $
					   hsize = miscData.vectorOpts.hsize*hsizeMult
					   ;miscData.vectorOpts.biColor
			endelse
		endfor
		MIWF_PlotWindScale
	endif

	if keyword_set(vertical) then begin
		colors = [48, 250, 99, 189, 153, 47]
		biFits = (*miscData.biFits)

		pts = where(abs(biFits[0,*].mangle) lt miscData.blendFitOpts.biMaxVerticalAngle and $
					max(reform(biFits[0,*].overlap), dimension=1) gt miscData.blendFitOpts.biZoneOverlap and $
					abs(biFits[0,*].obsDot) le miscData.blendFitOpts.biMaxDotProduct, npts)

		lats = biFits[0, pts].lat
		order = sort(lats)
		pts = reverse(pts[order])
		lats = reverse(lats[order])
		;\\ Plot the cv vertical wind locations on the main map
		loadct, 39, /silent
		col = randomu(systime(/sec), npts)*255
		if miscData.epsDraw eq 1 then set_plot, 'win'
		widget_control, get_value = windId, guiData.draw
		wset, windId
		for j = 0, npts - 1 do begin
			lat = biFits[*,pts[j]].lat
			lon = biFits[*,pts[j]].lon
			plots, map_proj_forward(lon, lat, map_struc = *miscData.mapStructure), psym=6, sym=.5, thick=5, $
				color = 150
		endfor

		;\\ Check out vertical winds, and compare with station winds
		;window, 1, xs = 1000, ys = 750, title = 'Vertical Winds...'
		bounds = get_boundcoords_for_multiplots(npts+miscData.nStations, [.08, .06, .98, .98], .01)

		set_plot, 'ps'
		dateStr = date_str_from_js((*miscData.windData[0])[0].start_time, separator = "_")
		device, filename = miscData.savedDataPath + 'VZ_' + dateStr + '.eps', /encaps, /color, xs = 10, ys = 12

		!p.charsize = .6
		!p.charthick = 1.5

		stVz = ptrarr(miscData.nStations + npts, /alloc)
		stUt = ptrarr(miscData.nStations + npts, /alloc)
		stLos1 = ptrarr(miscData.nStations + npts, /alloc)
		stLos2 = ptrarr(miscData.nStations + npts, /alloc)
		stLat = fltarr(miscData.nStations + npts)
		stName = strarr(miscData.nStations + npts)
		minUt = 30.
		maxUt = 0.
		minVz = 300.
		maxVz = -300.
		for s = 0, miscData.nStations - 1 do begin
			*stVz[s] = (*miscData.spekDataX[s]).velocity[0]
			*stUt[s] = js2ut((*miscData.windData[s]).start_time)
			stLat[s] = (*miscData.metaData[s]).latitude
			stName[s] = (*miscData.metaData[s]).site_code
			if min(*stUt[s]) lt minUt then minUt = min(*stUt[s])
			if max(*stUt[s]) gt maxUt then maxUt = max(*stUt[s])
			if min(*stVz[s]) lt minVz then minVz = min(*stVz[s])
			if max(*stVz[s]) gt maxVz then maxVz = max(*stVz[s])
		endfor
		for j = s, miscData.nStations + npts - 1 do begin
			*stVz[j] = biFits[*,pts[j-s]].mcomp
			*stUt[j] = 0.5*(biFits[*,pts[j-s]].times[0] + biFits[*,pts[j-s]].times[1])
			*stLos1[j] = biFits[*,pts[j-s]].loswinds[0]
			*stLos2[j] = biFits[*,pts[j-s]].loswinds[1]
			stLat[j] = lats[j-s]
			stName[j] = 'CV Lat:' + string(lats[j-s], f='(f0.1)')

			if min(*stVz[j]) lt minVz then minVz = min(*stVz[j])
			if max(*stVz[j]) gt maxVz then maxVz = max(*stVz[j])
		endfor

		order = reverse(sort(stLat))
		stVz = stVz[order]
		stLos1 = stLos1[order]
		stLos2 = stLos2[order]
		stUt = stUt[order]
		stLat = stLat[order]
		stName = stName[order]

		minVz = -100
		maxVz = 100

		if npts gt 0 then begin
			loadct, 39, /silent

			for k = 0, miscData.nStations + npts - 1 do begin
				if k eq 0 then noerase = 0 else noerase = 1
				if k eq miscData.nStations + npts - 1 then xstyle=9 else xstyle=5
				plot, [minUt, maxUt], [minVz,maxVz], psym=-6, sym=.3, thick = 1, title = stName[k], $
					  pos = bounds[npts + miscData.nStations - k - 1, *], noerase=noerase, /nodata, $
					  xstyle = xstyle, /ystyle, xtitle = 'Time (UT)'
				oplot, [minUt, maxUt], [0,0], line = 1

				if size(*stLos1[k], /type) ne 0 then begin
					oplot, *stUt[k], *stLos1[k], color = 50, line = 2, thick=1
					oplot, *stUt[k], *stLos2[k], color = 250, line = 2, thick=1
				endif
				oplot, *stUt[k], *stVz[k], thick = 1
				xyouts, /data, maxut, maxVz - 20, align=1.2, 'Mean: ' + string(mean(*stVz[k]),f='(f0.1)')

				ptr_free, stVz[k], stUt[k], stLos1[k], stLos2[k]
			endfor

			device, /close
			set_plot, 'win'
			!p.charsize = 0
			!p.charthick = 0
		endif

		for s = 0, miscData.nStations - 1 do begin
			ptr_free, stVz[s]
			ptr_free, stUt[s]
		endfor
		if miscData.epsDraw eq 1 then set_plot, 'ps'
	endif
end



;\\ PLOT THE RESULT OF THE BLENDED WIND FIT, IF AVAILABLE
pro MIWF_PlotBlendedWind

	common miwf_common, guiData, miscData

	;\\ Display the final blended windfield
		if miscData.epsDraw eq 1 then hsizeMult = 15. else hsizeMult = 1.
		if size(*miscData.blendFit, /type) eq 0 then return

		blend = (*miscData.blendFit)[miscData.timeIndex]
		if blend.fitted ne 1 then return

		gridx = n_elements(blend.merid[*,0])
		gridy = n_elements(blend.merid[0,*])
		loadct, 39, /silent

		merid = blend.merid
		zonal = blend.zonal

		;\\ Plot the fit-type boundaries...
		btnId = widget_info(guiData.base, find='PlotBlendDataBounds')
		if widget_info(btnId, /button_set) eq 1 then begin
			idx = [indgen(n_elements((*blend.monoBounds)[*,1])), 0]
			plots, map_proj_forward((*blend.monoBounds)[idx,1], (*blend.monoBounds)[idx,0], map = *miscData.mapStructure), $
				   /data, color = 255, line = 2
			idx = [indgen(n_elements((*blend.biBounds)[*,1])), 0]
			plots, map_proj_forward((*blend.biBounds)[idx,1], (*blend.biBounds)[idx,0], map = *miscData.mapStructure), $
				   /data, color = 255, line = 1
		endif

		;\\ Plot the winds...
		for xx = 0, gridx - 1, 5 do begin
		for yy = 0, gridy - 1, 5 do begin

			if blend.merid[xx,yy] eq blend.missing then continue

			magnitude = sqrt(merid[xx,yy]^2 + zonal[xx,yy]^2)*miscData.vectorOpts.scale
			azimuth = atan(zonal[xx,yy], merid[xx,yy])/!dtor
			get_mapped_vector_components, *miscData.mapStructure, blend.lat[yy], blend.lon[xx], magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
				   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
				   color = miscData.vectorOpts.blendColor, thick = miscData.vectorOpts.thick, $
				   solid = miscData.vectorOpts.solid, /data, $
				   hsize = miscData.vectorOpts.hsize*hsizeMult
		endfor
		endfor

		MIWF_PlotWindScale
end



;\\ DRAW AN ARROW REPRESENTING THE VECTOR WIND SCALE
pro MIWF_PlotWindScale

	common miwf_common, guiData, miscData

	;\\ Vector scale arrow
		loadct, 39, /silent
		if miscData.epsDraw eq 1 then hsizeMult = 15. else hsizeMult = 1.
		base_coords = convert_coord(.01, .01, /normal, /to_data)
		base_coords = map_proj_inverse(base_coords[0], base_coords[1], map_struc = *miscData.mapStructure)
		magnitude = 200.*miscData.vectorOpts.scale
		azimuth = 90.
		get_mapped_vector_components, *miscData.mapStructure, base_coords[1], base_coords[0], magnitude, azimuth, $
		 						  	  mapXBase, mapYBase, mapXlen, mapYlen
		length = sqrt(mapXLen*mapXLen + mapYLen*mapYLen)
		p0 = convert_coord(mapXBase,mapYBase, /data, /to_normal)
		p1 = convert_coord(mapXBase+length,mapYBase, /data, /to_normal)
		xlen = p1[0]-p0[0]

		;polyfill, /normal, [0,0,xlen+.02,xlen+.02], [-1,40,40,-1], color = 0
		arrow, .01, .01, .01 + xlen, .01, /solid, hsize = 15*hsizeMult, thick = 3, color = 255, /normal

		if miscData.epsDraw eq 0 then begin
			!p.font = 0
			device, set_font="Ariel*18*Bold"
			xyouts, /device, 10, 20, '200 m/s', color = 255

			;\\ Output station times
			for s = 0, miscData.nStations - 1 do begin
				xyouts, 200 + s*150, 10, (*miscData.metaData[s]).site_code + ': ' + $
						time_str_from_decimalut((*miscData.stnTimes[s])[miscData.timeIndex]) + ' UT', $
						color = 255, /device
			endfor

			!p.font = -1
		endif else begin
			MIWF_SetEpsCoords
			xyouts, /data, 10, 20, '200 m/s', color = 255, chars = .7, chart = 2

			;\\ Output station times
			for s = 0, miscData.nStations - 1 do begin
				xyouts, 200 + s*180, 10, (*miscData.metaData[s]).site_code + ': ' + $
						time_str_from_decimalut((*miscData.stnTimes[s])[miscData.timeIndex]) + ' UT', $
						color = 255, chars = .7, chart = 2, /data
			endfor

			MIWF_SetEpsCoords, /unset
		endelse
end



;\\ UPDATE THE FIT PROGRESS BAR
pro MIWF_UpdateProgress, percent, progMessage, reset=reset

	common miwf_common, guiData, miscData

	oldWindow = !d.window
	widget_control, get_value = windId, guiData.progress
	wset, windId

	loadct, 39, /silent
	if keyword_set(reset) then begin
		erase, 0
		progMessage = ''
	endif else begin
		polyfill, /normal, [0,0,percent,percent], [-.1,1,1,-.1], color = 120
	endelse
	widget_control, set_value = 'Progress: ' + progMessage, guiData.progressLabel

	wset, oldWindow

end



;\\ REDRAW ANYTHING THAT IS SET TO BE DRAW, FOR EACH STATION
pro MIWF_Refresh

	common miwf_common, guiData, miscData

	MIWF_DrawMap
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,3] eq 1 then MIWF_PlotParamMap, s, /temp
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,4] eq 1 then MIWF_PlotParamMap, s, /brite
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,2] eq 1 then MIWF_PlotZoneMap, s
	if miscData.biPlotOverlap eq 1 then MIWF_PlotZoneMap, s, /biStatic
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,0] eq 1 then MIWF_PlotFittedWinds, s
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,5] eq 1 then MIWF_PlotFittedWinds, s, /interp
	for s = 0, miscData.maxStations - 1 do if miscData.plotOpts[s,1] eq 1 then MIWF_PlotFittedWinds, s, /los

	if miscData.polyPlot eq 1 then MIWF_FitPoly, /draw
	if miscData.biPlot eq 1 then MIWF_PlotBiStatic
	;if miscData.triPlot eq 1 then MIWF_PlotTriStatic
	if miscData.blendPlot eq 1 then MIWF_PlotBlendedWind

	;\\ Show the station locations and update times
	if miscData.epsDraw eq 0 then begin
		widget_control, get_value = windId, guiData.draw
		wset, windId
	endif
	for s = 0, miscData.maxStations - 1 do begin

		if size((*miscData.metaData[s]), /type) ne 8 then continue

		loadct, 39, /silent
		if miscData.epsDraw eq 1 then sizeMult = .5 else sizeMult = 1.
		mapXY = map_proj_forward((*miscData.metaData[s]).longitude, (*miscData.metaData[s]).latitude, map_struc = *miscData.mapStructure)
		plots, mapXY, psym=6, thick = 10, sym=1.7*sizeMult, color=255, /data
		plots, mapXY, psym=6, thick = 8, sym=1.7*sizeMult, color=0, /data
		loadct, miscData.ctables[s], /silent
		plots, mapXY, psym=6, thick = 3, sym=1.7*sizeMult, color=miscData.colors[s], /data

		mapXY = map_proj_forward((*miscData.metaData[s]).longitude, (*miscData.metaData[s]).latitude + .3, map_struc = *miscData.mapStructure)
		if miscData.epsDraw eq 0 then begin
			!p.font = 0
			device, set_font="Ariel*18*Bold"
			xyouts, mapXY[0], mapXY[1], (*miscData.metaData[s]).site_code, $
					color=miscData.colors[s], /data, align=0.5
			!p.font = -1
		endif else begin
			xyouts, mapXY[0], mapXY[1], (*miscData.metaData[s]).site_code, $
					color=miscData.colors[s], /data, align=0.5, chars = .7, chart = 2
		endelse

		stnTimeLabel = widget_info(guiData.base, find_by_uname = 'Station' + string(s, f='(i0)') + 'TimeLabel')

		;\\ Update station time label
			if widget_info(stnTimeLabel, /valid) then $
				widget_control, set_value = 'Time: ' + $
					time_str_from_decimalut((*miscData.stnTimes[s])[miscData.timeIndex]), stnTimeLabel
	endfor

end



;\\ NOT REALLY IMPLEMENTED - OVERLAYS VERY GENERIC, MODEL ELECTRIC POTENTIAL CONTOURS
pro MIWF_OverlayPotentials, generate=generate, overlay=overlay

	common miwf_common, guiData, miscData

	if keyword_set(generate) then begin
		ReadCoef

		bx = 1. & by = 2. &	bz = -3.
		tilt = 0.0 & vel = 340.

		theta=atan(By,Bz)
		angle=theta*180./!PI
		if angle lt 0. then angle=angle+360.
		Bt=sqrt(bx^2 + by^2 + bz^2)

		SetModel,angle,Bt,tilt,vel

		min_lat = 40.
		xs = 400.
		pot = fltarr(xs,xs)

		xarr = fltarr(xs,xs)
		for z = 0, xs - 1 do xarr(*,z) = findgen(xs) - xs/2.
		yarr = transpose(xarr)

		distarr = sqrt(xarr^2 + yarr^2)
		anglarr = reverse(rot(atan(yarr, xarr)+ !pi, 270))
		anglarr = (anglarr/(2.*!pi))*24.

		lat_ext = 90 - abs(min_lat)
		lat_rad = xs / 2.
		lat_scl = lat_ext / lat_rad
		latarr = (90 - distarr * lat_scl)

		pts = where(distarr lt lat_rad, npts, complement = opts)
		pot(opts) = 0
		pot(pts) = epotval(latarr(pts), anglarr(pts))

		CONTOUR, smooth(pot, 10, /edge), PATH_XY=xy, PATH_INFO=info, /path_data_coords, nlevels=50
		*miscData.potentialData = {path_xy:xy, path_info:info, lons:anglarr*(360./24.), lats:latarr}

	endif

	if keyword_set(overlay) then begin
		info = (*miscData.potentialData).path_info
		xy = (*miscData.potentialData).path_xy
		tlon = (*miscData.potentialData).lons
		tlat = (*miscData.potentialData).lats
		FOR I = 1, (N_ELEMENTS(info) - 1 ) DO BEGIN
		   	S = [INDGEN(info(I).N), 0]
		   	clon = tlon(xy(0,INFO(I).OFFSET + S ), xy(1,INFO(I).OFFSET + S ))
		   	clat = tlat(xy(0,INFO(I).OFFSET + S ),  xy(1,INFO(I).OFFSET + S ))
		   	map_xy = map_proj_forward(clon, clat, map=*miscData.mapStructure)
		   	;lab_xy = map_proj_forward(tlon(0), tlat(0), map=*miscData.mapstruct)
		   	if info(I).value lt 0 then cl = 255 else cl = 255

		   	PLOTS, /data, map_xy, color=cl, thick = 1 ;, clip = [miscData.mapAxes.x[0], miscData.mapAxes.y[0], $
		   			;miscData.mapAxes.x[1], miscData.mapAxes.y[1]], noclip=0
		   	;PLOTS, /data, map_xy, color=cl, thick = thick, clip = [xscale(0),yscale(0),xscale(1),yscale(1)], noclip=0
		   	;if keyword_set(label) then xyouts, /data, lab_xy(0), lab_xy(1), $
		   	;						   string(info(I).value, f='(f0.1)'), color = color, chars = 1.5
		ENDFOR
	endif

end



;\\ CAPTURE SCREEN CONTENTS TO AN IMAGE OR EPS, OR CAPTURE A SEQUENCE OF IMAGES FOR MOVIES
pro MIWF_ScreenCapture, png=png, $
						jpg=jpg, $
						eps=eps, $
						filename=filename, $
						sequence=sequence

	common miwf_common, guiData, miscData

	widget_control, get_value = windId, guiData.draw
	wset, windId

	if not keyword_set(sequence) then begin
		image = tvrd(/true)
		if keyword_set(png) then begin
			if not keyword_set(filename) then $
				filename = dialog_pickfile(path = miscData.savedDataPath, default_extension = 'png')
			if filename ne '' then write_png, filename, image
		endif
		if keyword_set(jpg) then begin
			if not keyword_set(filename) then $
				filename = dialog_pickfile(path = miscData.savedDataPath, default_extension = 'jpg')
			if filename ne '' then write_jpeg, filename, image, /true, quality = 100
		endif

		if keyword_set(eps) then begin
			set_plot, 'ps'
			if not keyword_set(filename) then $
				filename = dialog_pickfile(path = miscData.savedDataPath, default_extension = 'eps')
			if filename ne '' then begin
				device, filename = filename, xs = 10, ys = 10, /color, /encaps, bits = 8
					miscData.epsDraw = 1
					MIWF_Refresh
					miscData.epsDraw = 0
				device, /close
				set_plot, 'win'
			endif
		endif
	endif else begin

		if miscData.nStations eq 0 then return

		dirname = dialog_pickfile(path = miscData.savedDataPath, /directory)
		if file_test(dirname, /directory) eq 1 then begin
			for t = 0, n_elements(*miscData.allTimes) - 1 do begin
				miscData.timeIndex = t
				widget_control, guiData.timeSlider, set_value = t
				MIWF_Refresh

				dateStr = date_str_from_js((*miscData.windData[0])[0].start_time, separator = "_")
				filename = dirname + 'ImageSequence_' + dateStr + '_' + string(t, f='(i04)')
				if keyword_set(png) then MIWF_ScreenCapture, /png, filename = filename + '.png'
				if keyword_set(jpg) then MIWF_ScreenCapture, /jpg, filename = filename + '.jpg'
			endfor
		endif
	endelse

end


;\\ INTERPOLATE STATION DATA TO THE GIVEN TIME INDEX
pro MIWF_GetInterpolates, stationIndex, timeIndex, interpolates

	common miwf_common, guiData, miscData
	s = stationIndex

	idx = timeIndex
	expIdx = (*miscData.stnIndices[s])[idx]

	if (expIdx eq 0) or (expIdx eq max(*miscData.stnIndices[s])) or $
	   ((*miscData.stnTimes[s])[idx] eq (*miscData.allTimes)[idx]) then begin
		merid = reform((*miscData.windData[s])[expIdx].meridional_wind)
		zonal = reform((*miscData.windData[s])[expIdx].zonal_wind)
		los = 	reform((*miscData.spekDataX[s])[expIdx].velocity)
		sigmalos = 	reform((*miscData.spekDataX[s])[expIdx].sigma_velocity)
		intens=	reform((*miscData.spekDataX[s])[expIdx].intensity)
		sigmaintens=reform((*miscData.spekDataX[s])[expIdx].sigma_intensities)
		temp = 	reform((*miscData.spekDataX[s])[expIdx].temperature)
		interpolated = 0
	endif else begin

		stUt = (*miscData.stnTimes[s])
		stIdx = (*miscData.stnIndices[s])
		needUt = (*miscData.allTimes)[idx]

		jumble = [stUt, needUt]
		jumble = jumble[sort(jumble)]
		pt = (where(jumble eq needUt))[0]
		loPt = pt - 1
		hiPt = pt

		uts = stUt[[loPt, hiPt]]
		ids = stIdx[[loPt, hiPt]]

		merid = 	fltarr((*miscData.metaData[s]).nzones)
		zonal = 	fltarr((*miscData.metaData[s]).nzones)
		los = 		fltarr((*miscData.metaData[s]).nzones)
		sigmalos = 	fltarr((*miscData.metaData[s]).nzones)
		intens = 	fltarr((*miscData.metaData[s]).nzones)
		sigmaintens=fltarr((*miscData.metaData[s]).nzones)
		temp = 		fltarr((*miscData.metaData[s]).nzones)

		for z = 0, (*miscData.metaData[s]).nzones - 1 do begin
			merid[z] = 	interpol(reform((*miscData.windData[s])[ids].meridional_wind[z]), uts, needUt)
			zonal[z] = 	interpol(reform((*miscData.windData[s])[ids].zonal_wind[z]), uts, needUt)
			los[z] = 	interpol(reform((*miscData.spekDataX[s])[ids].velocity[z]), uts, needUt)
			sigmalos[z] = 	interpol(reform((*miscData.spekDataX[s])[ids].sigma_velocity[z]), uts, needUt)
			intens[z] = interpol(reform((*miscData.spekDataX[s])[ids].intensity[z]), uts, needUt)
			sigmaintens[z] = interpol(reform((*miscData.spekDataX[s])[ids].sigma_intensities[z]), uts, needUt)
			temp[z] = 	interpol(reform((*miscData.spekDataX[s])[ids].temperature[z]), uts, needUt)
		endfor
		interpolated = 1
	endelse

	interpolates = {merid:merid, $
					zonal:zonal, $
					los:los, $
					sigma_los:sigmalos, $
					intensity:intens, $
					sigma_intens:sigmaintens, $
					temperature:temp, $
					interpolated:interpolated}
end



;\\ SAVE THE MISCDATA STRUCTURE TO AN IDL SAVE FILE - QUICK AND DIRTY DATA EXPORT
pro MIWF_IDLSaveData

	common miwf_common, guiData, miscData

	filename = dialog_pickfile(path = miscData.savedDataPath, default_extension = 'png')
	if filename ne '' then save, filename = filename, miscData, /compress
end


;\\ SET UP A DATA COORDINATE SYSTEM IN AN EPS FILE FOR EASIER PLOTTING
pro MIWF_SetEpsCoords, unset=unset

	common miwf_common, guiData, miscData

	if not keyword_set(unset) then begin
		;\\ Store the current coordinate structures
		miscData.coordStore = {x:!x, y:!y}
		;\\ Create a data coordinate plot equivalent to the screen device
		plot, /nodata, /noerase, [0,guiData.drawX], [0, guiData.drawY], $
			  xstyle=5, ystyle=5, pos = [0,0,1,1]
	endif else begin
		!x = miscData.coordStore.x
		!y = miscData.coordStore.y
	endelse
end


;\\ ROUTINE ENTRY POINT - CREATE DATA STRUCTURES, INITIATE GUI, LOAD SOME INITIAL DATA...
pro Multiple_Instrument_Wind_Fit

	common miwf_common, guiData, miscData

	maxStations = 10

	vectorOpts = {thick:2., hsize:10., solid:1, scale:1000., $
				  biColor:150, triColor:150, blendColor:255}

	miscOpts = {tempMin:500., tempMax:1100., intensMin:0., intensMax:1E6, losMin:-300., losMax:300.}

	mapOpts = {gridOn:0, lonDelta:20, latDelta:10, lonLabels:65., latLabels:-147., $
			   backCtable:0, backColor:180, $
			   continentCtable:0, continentColor:255, $
			   coastCtable:0, coastColor:100}

	blendFitOpts = {iters:1, monoFactor:1.0, biFactor:10.0, monoFalloff:3., biFallOff:1., $
					biAngleCutoff:30., biMaxVerticalAngle:2.5, biMaxDotProduct:0.83, biZoneOverlap:0.1, $
					biMaxPercentageError:.3, biMaxAbsError:30.}

	coordStore = {x:!x, y:!y}

	miscData = {maxStations:maxStations, $
				nStations:0, $
				defaultDataPath:'E:\', $
				dataFilenames:strarr(maxStations), $
				dataFullpaths:strarr(maxStations), $
				dataValid:bytarr(maxStations), $
				metaData:ptrarr(maxStations, /alloc), $
				windData:ptrarr(maxStations, /alloc), $
				spekData:ptrarr(maxStations, /alloc), $
				spekDataX:ptrarr(maxStations, /alloc), $
				zoneCenters:ptrarr(maxStations, /alloc), $
				intensGains:fltarr(maxStations), $
				colors:intarr(maxStations), $
				ctables:intarr(maxStations), $
				mapCenter:[63.5, -146.], $
				mapZoom:7., $
				mapXoffset:0., $
				mapYoffset:0., $
				mapAxes:{x:[0D,0D], y:[0D,0D]}, $
				mapStructure:ptr_new(/alloc), $
				mapOpts:mapOpts, $
				allTimes:ptr_new(/alloc), $
				stnTimes:ptrarr(maxStations, /alloc), $
				stnIndices:ptrarr(maxStations, /alloc), $
				timeIndex:0L, $
				plotOpts:bytarr(maxStations, 10), $	;\\ 0 mono, 1 los, 2 zmap, 3 temp, 4 brite, 5 monoInterp
													;\\ 6 bistatic overlap, 7 tristatic overlap
				vectorOpts:vectorOpts, $
				miscOpts:miscOpts, $
				blendFitOpts:blendFitOpts, $
				monoFits:ptr_new(/alloc), $
				polyFit:ptr_new(/alloc), $
				biFits:ptr_new(/alloc), $
				triFits:ptr_new(/alloc), $
				blendFit:ptr_new(/alloc), $
				polyPlot:0, $
				biPlot:0, $
				biPlotOverlap:0, $
				triPlot:0, $
				triPlotOverlap:0, $
				blendPlot:0, $
				savedDataPath:'C:\cal\IDLSource\NewAlaskaCode\WindFit\WindFitSavedData\', $
				epsDraw:0, $
				coordStore:coordStore, $
				interpData:1, $
				list_selected:-1, $
				potentialData:ptr_new(/alloc)}

	miscData.ctables[*] = 39
	miscData.colors[0:1] = [190, 70]

	;\\ Load a couple of files because i am lazy...
	miscData.dataFullpaths[0] = where_is('gakona_data') + 'HRP_2011_095_Elvey_630nm_Red_Sky_Date_04_05.nc'
	miscData.dataFullpaths[1] = where_is('poker_data') + 'PKR 2011_095_Poker_630nm_Red_Sky_Date_04_05.nc'
	miscData.dataFilenames[0:1] = file_basename(miscData.dataFullpaths[0:1])

	MIWF_Gui
	MIWF_DrawMap
	;MIWF_OverlayPotentials, /generate
	MIWF_LoadData, 0
	MIWF_LoadData, 1

	xmanager, 'Multiple_Instrument_Wind_Fit', guiData.base, event_handle='MIWF_Event', $
			  cleanup='MIWF_EndSession', /no_block

end
