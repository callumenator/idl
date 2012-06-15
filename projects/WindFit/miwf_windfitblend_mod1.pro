
pro MIWF_WindFitBlend_Mod1

	common miwf_common, guiData, miscData

	;\\ Check what data is available...
		if size(*miscData.monoFits, /type) ne 0 then $
			monoStaticAvailable = 1 else monoStaticAvailable = 0

		if size(*miscData.biFits, /type) ne 0 then $
			biStaticAvailable = 1 else biStaticAvailable = 0

		if size(*miscData.triFits, /type) ne 0 then $
			triStaticAvailable = 1 else triStaticAvailable = 0

	;\\ Make sure we have at least got monostatic fits...
		print, 'MonoStatic: ', monoStaticAvailable
		print, 'BiStatic: ', biStaticAvailable
		print, 'TriStatic: ', triStaticAvailable
		if monoStaticAvailable eq 0 then begin
			print, 'No Monostatic Data!'
			return
		endif

	;\\ Some initial variables and time-independent stuff
		gridx = 100.
		gridy = 100.
		missingVal = -9999
		iterMax = miscData.blendFitOpts.iters
		MonoFits = *miscData.monoFits
		if biStaticAvailable eq 1 then BiFits = *miscData.biFits

		blendFitStruc = {merid:fltarr(gridx, gridy), $
						 zonal:fltarr(gridx, gridy), $
						 vertical:fltarr(gridx, gridy), $
						 ;monoMerid:fltarr(gridx, gridy), $
						 ;monoZonal:fltarr(gridx, gridy), $
						 ;biMerid:fltarr(gridx, gridy), $
						 ;biZonal:fltarr(gridx, gridy), $
						 dudx:fltarr(gridx, gridy), $
						 dudy:fltarr(gridx, gridy), $
						 dvdx:fltarr(gridx, gridy), $
						 dvdy:fltarr(gridx, gridy), $
						 lat:fltarr(gridy), $
						 lon:fltarr(gridx), $
						 missing:missingVal, $
						 monoWinds:ptr_new(), $
						 monoBounds:ptr_new(), $
						 biWinds:ptr_new(), $
						 biBounds:ptr_new(), $
						 fitted:0, $
						 dataUsed:intarr(3)}

			if size(*miscData.blendFit, /n_dimensions) eq 0 then begin
				*miscData.blendFit = replicate(blendFitStruc, n_elements(*miscData.allTimes))
			endif


	;\\ Monostatic fits are used to find the data boundary...
		monolon = MonoFits[0,*].lon
		monolat = MonoFits[0,*].lat
		limits = [min(monolon), min(monolat), max(monolon), max(monolat)]
		xout = (findgen(gridx)/(gridx-1))*(limits[2]-limits[0]) + limits[0]
		yout = (findgen(gridy)/(gridy-1))*(limits[3]-limits[1]) + limits[1]
		triangulate, monolon, monolat, monoTriangles, monoBoundary

		mnLatGrid = trigrid(monolon, monolat, monolat, monoTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
		mnLonGrid = trigrid(monolon, monolat, monolon, monoTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
		monoPts = array_indices(mnLatGrid, where(mnLatGrid ne missingVal, complement = moMissing))

	;\\ Use bistatic fits which are off-zenith
		if biStaticAvailable eq 1 then begin
			keepBiFits = where(abs(BiFits[0,*].mAngle) gt miscData.blendFitOpts.biAngleCutoff and $
							   max(reform(BiFits[0,*].overlap), dimension=1) gt miscData.blendFitOpts.biZoneOverlap and $
							   abs(BiFits[0,*].obsDot) le miscData.blendFitOpts.biMaxDotProduct, nBiFits)

			bilon = BiFits[0, keepBiFits].lon
			bilat = BiFits[0, keepBiFits].lat
			triangulate, bilon, bilat, biTriangles, biBoundary

			biLatGrid = trigrid(bilon, bilat, bilat, biTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
			biLonGrid = trigrid(bilon, bilat, bilon, biTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
			biDotGrid = trigrid(bilon, bilat, reform(biFits[0,keepBiFits].mangle), biTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
			biPts = array_indices(biLatGrid, where(biLatGrid ne missingVal, complement = biMissing))
		endif

		;\\ Declare these now, and fill in values on first iteration/time loop
			dists = fltarr(gridx, gridy, 2)

end