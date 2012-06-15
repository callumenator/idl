
;\\ Fit bistatic winds
pro MIWF_FitBiStatic_Usolve, force_redo=force_redo

	common miwf_common, guiData, miscData

	biFits = (*miscData.biFits)

	;\\ Make sure we have bistatic fits
	if size(biFits, /n_dimensions) ne 2 then return
	if n_elements(biFits[0,*]) eq 0 then return

		stationName = strarr(miscData.nStations)
		stationPos = fltarr(miscData.nStations, 2)
		for s = 0, miscData.nStations - 1 do stationName[s] = (*miscData.metaData[s]).site_code

		dateStr = date_str_from_js((*miscData.windData[0])[0].start_time[0], /forfile)
		stnName = stationName[sort(stationName)]
		usolveSaveName = 'USolveFits_'
		for k = 0, miscData.nStations - 1 do usolveSaveName += stnName[k] + '_'
		usolveSaveName += dateStr + '.saved'
		if file_test(where_is('usolve_fits') + usolveSaveName) eq 1 then begin
			if not keyword_set(force_redo) then return
		endif

	;\\ Check for saved data
		if file_test(where_is('usolve_fits') + usolveSaveName) eq 1 then begin

		endif

		bistatic_usolve, biFits, 40., usolve_out, filter = {obsdot:0.83, overlap:0.1, merr:30, lerr:30}, $
						 gradient_spacesmooth = [.1, .1], component_timesmooth = 10./60.

		usolve = usolve_out
		save, filename = where_is('usolve_fits') + usolveSaveName, usolve, /compress

end