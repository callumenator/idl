
@resolve_nStatic_wind

;\\ Blend the various wind estimates together
pro MIWF_WindFitBlend, batch = batch, $
					   force_all = force_all, $
					   outside_call = outside_call, sim=sim

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

	;\\ Create a directory to store blended fit images and data
		if keyword_set(batch) then begin
			stnNames = strarr(miscData.nStations)
			for s = 0, miscData.nStations - 1 do stnNames[s] = (*miscData.metaData[s]).site_code
			stnNames = stnNames[sort(stnNames)]
			dateStr = date_str_from_js((*miscData.windData[0])[0].start_time[0], /forfile)
			defaultFolderName = miscData.savedDataPath + 'BatchBlends\' + 'BatchBlend_'
			for s = 0, miscData.nStations - 1 do defaultFolderName += stnNames[s] + '_'
			defaultFolderName += dateStr

	 		file_mkdir, defaultFolderName
	 		file_mkdir, defaultFolderName + '\Images'
	 		file_mkdir, defaultFolderName + '\Data'
	 		for i = 0, iterMax - 1 do begin
	 			file_mkdir, defaultFolderName + '\Images\Iter' + string(i, f='(i0)')
	 			file_mkdir, defaultFolderName + '\Data\Iter' + string(i, f='(i0)')
	 		endfor

			;\\ Ask what time range to batch blend...
			index_range = [0, n_elements(*miscData.allTimes)-1]
			if not keyword_set(force_all) then begin
				xvaredit, index_range, name = 'Select Exposure Range...', group = guiData.base
				index_range[0] = index_range[0] > 0
				index_range[1] = index_range[1] < (n_elements(*miscData.allTimes)-1)
			endif

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

	;\\ Set for-loop time bounds
		if keyword_set(batch) then begin
			tIndexMin = index_range[0]
			tIndexMax = index_range[1]
		endif else begin
			tIndexMin = miscData.timeIndex
			tIndexMax = miscData.timeIndex
		endelse

	;\\ Loop through times...
	for tIndex = tIndexMin, tIndexMax do begin

		verticalWind = fltarr(gridx, gridy)
		miscData.timeIndex = tIndex

		if keyword_set(batch) then begin
			miscData.timeIndex = tIndex
			widget_control, guiData.timeSlider, set_value = tIndex
			MIWF_Refresh
		endif

		;\\ Begin iterating...
		for iter = 0, iterMax - 1 do begin

			;\\ Compute the weights and distances on the first iteration
				if (tIndex-tIndexMin) eq 0 and iter eq 0 then begin
					for xx = 0, gridx - 1 do begin
					for yy = 0, gridy - 1 do begin

						xdist = 0
						ydist = 0
						if xx gt 0 then xdist = map_2points(xout[xx], yout[yy], xout[xx-1], yout[yy], /meters)/1000.
						if yy gt 0 then ydist = map_2points(xout[xx], yout[yy], xout[xx], yout[yy-1], /meters)/1000.
						dists(xx,yy,*) = [xdist, ydist]

						;\\ Update the progress bar
						if not keyword_set(outside_call) then begin
							MIWF_UpdateProgress, ((xx+1)*(yy+1)) / float(gridx * gridy), 'Iteration ' + $
								string(iter+1,f='(i0)') + ' of ' + string(iterMax, f='(i0)') + ', Computing distances...'
						endif

					endfor
					endfor

					if not keyword_set(outside_call) then MIWF_UpdateProgress, /reset
				endif


			;\\ Calculate the monostatic fits using current vertical wind estimates...
				blendFitData = {timeIndex:tIndex, $
								lats:yout, $
								lons:xout, $
								verticalWind:verticalWind}
				if keyword_set(sim) then begin
					burnside_sim_windfit, blendfitdata, vertical, outFits = monoFitsOut
				endif else begin
					MIWF_FitMonostatic, blendFitData = blendFitData, outFits = monoFitsOut
				endelse


			;\\ Spatially interpolate Monostatic Fits...
				allMonoFits = monoFitsOut
				;zonal = allMonoFits.zonal
				;merid = allMonoFits.merid
				;monoZonalGrid = trigrid(monolon, monolat, zonal, monoTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
				;monoMeridGrid = trigrid(monolon, monolat, merid, monoTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)


			;\\ Spatially interpolate Bistatic Fits...
				if biStaticAvailable eq 1 then begin

					allBiFits = reform(BiFits[tIndex, keepBiFits])

					;\\ Check for percentage error here
					mag = sqrt(allBiFits.mcomp*allBiFits.mcomp + allBiFits.lcomp*allBiFits.lcomp)
					keep2 = where(abs(allBiFits.merr) le miscData.blendFitOpts.biMaxAbsError and $
								  abs(allBiFits.lerr) le miscData.blendFitOpts.biMaxAbsError, nKeep2)

					if nKeep2 eq 0 then begin
						print, 'No BiStatic Fits with Low-enough Uncertainty!'
						continue
					endif

					biStruc = {zonal:0.0D, merid:0.0D, lat:0.0, lon:0.0}
					biArray = replicate(biStruc, nKeep2)

					zonal = fltarr(nKeep2)
					merid = fltarr(nKeep2)
					for kk = 0L, nKeep2 - 1 do begin

						k = keep2[kk]

						lat = allBiFits[k].lat
						lon = allBiFits[k].lon

						latDiff  = (lat - yout)*(lat - yout)
						lonDiff  = (lon - xout)*(lon - xout)
						latPt = (where(latDiff eq min(latDiff)))[0]
						lonPt = (where(lonDiff eq min(lonDiff)))[0]
						vz = verticalWind[lonPt, latPt]

						out = project_bistatic_fit(allBiFits[k], vz)
						merid[kk] = out[1]
						zonal[kk] = out[0]

						biArray[kk] = {zonal:out[0], merid:out[1], $
									  lat:allBiFits[k].lat, lon:allBiFits[k].lon}

					endfor	;\\ bifits loop

					ppbizon = zonal
					ppbimer = merid
					ppbilat = allBiFits[keep2].lat
					ppbilon = allBiFits[keep2].lon
					biFitsStore = {lat:ppbilat, $
								   lon:ppbilon, $
								   zonal:zonal, $
								   merid:merid}

					triangulate, bilon[keep2], bilat[keep2], biTriangles, biBoundary
					biZonalGrid = trigrid(bilon[keep2], bilat[keep2], zonal, biTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
					biMeridGrid = trigrid(bilon[keep2], bilat[keep2], merid, biTriangles, missing=missingVal, xout=xout, yout=yout, /quintic)
					biPts = array_indices(biMeridGrid, where(biMeridGrid ne missingVal, complement = biMissing))

				endif else begin

					;biMeridGrid = fltarr(gridx, gridy)
					;biZonalGrid = fltarr(gridx, gridy)
				endelse


				;\\ Define/clear the blended arrays
				meridBlended = fltarr(gridx, gridy)
				zonalBlended = fltarr(gridx, gridy)

				;\\ Loop through and produce a blended windfield

				outIndices = monoPts
				noutPts = n_elements(outIndices[0,*])
				for outIdx = 0, nOutPts - 1 do begin

					xx = outIndices[0, outIdx]
					yy = outIndices[1, outIdx]

					rad = cos(yout[yy]*!dtor)

					monoDist = double(rad*(xout[xx]-allMonoFits.lon)*(xout[xx]-allMonoFits.lon) + $
						 	   		  (yout[yy]-allMonoFits.lat)*(yout[yy]-allMonoFits.lat))
					moSigma = miscData.blendFitOpts.monoFalloff
					moStWgt = miscData.blendFitOpts.monoFactor*exp(-(monoDist)/(2*moSigma^2.0))

					if biStaticAvailable eq 1 then begin
						biDist = double(rad*(xout[xx]-biArray.lon)*(xout[xx]-biArray.lon) + $
							 	 		(yout[yy]-biArray.lat)*(yout[yy]-biArray.lat))

						biSigma = miscData.blendFitOpts.biFalloff
						biStWgt = miscData.blendFitOpts.biFactor*exp(-(biDist)/(2*biSigma^2.0))
					endif else begin
						biStWgt = 0
						biArray = {merid:0., zonal:0.}
					endelse

					meridBlended[xx,yy] = (total(moStWgt*allMonoFits.merid) + total(biStWgt*biArray.merid))/(total(moStWgt) + total(biStWgt))
					zonalBlended[xx,yy] = (total(moStWgt*allMonoFits.zonal) + total(biStWgt*biArray.zonal))/(total(moStWgt) + total(biStWgt))

					;\\ Update the progress bar
					if not keyword_set(outside_call) then begin
						MIWF_UpdateProgress, (outIdx)/float(nOutPts), $
						string(iter+1,f='(i0)') + ' of ' + string(iterMax, f='(i0)') + ', Blending Fits...'
					endif

					wait, 0.0001
				endfor	;\\ Blending loop


				meridBlended[moMissing] = missingVal
				zonalBlended[moMissing] = missingVal


				if not keyword_set(outside_call) then MIWF_UpdateProgress, /reset

				;\\ Calculate the horizontal divergence, use this to generate a vertical wind estimate
				boxWid = 20	;\\ box width in pixels, over which average divergence is calculated.
				scaleHeight = 40.	;\\ kilometers

				delM_x = (meridBlended - shift(meridBlended, 1, 0)) / reform(dists[*,*,0])
				delM_y = (meridBlended - shift(meridBlended, 0, 1)) / reform(dists[*,*,1])
				delZ_x = (zonalBlended - shift(zonalBlended, 1, 0)) / reform(dists[*,*,0])
				delZ_y = (zonalBlended - shift(zonalBlended, 0, 1)) / reform(dists[*,*,1])

				vBurnside = scaleHeight*(delM_y + delZ_x)

				good = where( meridBlended ne missingVal and $
								shift(meridBlended, 1, 0) ne missingVal and $
		 							shift(meridBlended, 0, 1) ne missingVal, nGood, comp = missPts)

				delM_x[missPts] = missingVal
				delM_y[missPts] = missingVal
				delZ_x[missPts] = missingVal
				delZ_y[missPts] = missingVal

		 		goodPts = array_indices(meridBlended, good)

				for jj = 0, nGood - 1 do begin
					;\\ Get the largest box up to boxWid in size, and get average over it
						xCen = goodPts[0,jj]
						yCen = goodPts[1,jj]
						xMin = (xCen - boxWid/2) > 0
						yMin = (yCen - boxWid/2) > 0
						xMax = (xCen + boxWid/2) < gridx - 1
						yMax = (yCen + boxWid/2) < gridy - 1

						subVer = vBurnside[xMin:xMax, yMin:yMax]
						useMer = meridBlended[xMin:xMax, yMin:yMax]
						useMerR = (shift(meridBlended, 1, 0))[xMin:xMax, yMin:yMax]
						useMerU = (shift(meridBlended, 0, 1))[xMin:xMax, yMin:yMax]
						use = where(useMer ne missingVal and useMerU ne missingVal and useMerR ne missingVal, nuse)
						if nuse gt 0 then begin
							if abs(mean(subVer[use])) gt .01 then begin
								verticalWind[xCen, yCen] = verticalWind[xCen, yCen] + (mean(subVer[use]))
							endif
						endif else begin
							verticalWind[xCen, yCen] = missingVal
						endelse

					;\\ Update the progress bar
					if not keyword_set(outside_call) then begin
						MIWF_UpdateProgress, (jj+1)/float(nGood), $
							string(iter+1,f='(i0)') + ' of ' + string(iterMax, f='(i0)') + ', Computing Vz...'
					endif
				endfor

				if not keyword_set(outside_call) then MIWF_UpdateProgress, /reset

				fitDelta = 0

				;\\ Copy the data into the common block now so we can see the wind fields updated each iteration
					thisStruc = blendFitStruc
					thisStruc.merid = meridBlended
					thisStruc.zonal = zonalBlended
					thisStruc.vertical = verticalWind
					;thisStruc.monoMerid = monoMeridGrid
					;thisStruc.monoZonal = monoZonalGrid
					;thisStruc.biMerid = biMeridGrid
					;thisStruc.biZonal = biZonalGrid
					thisStruc.dudx = delZ_x
					thisStruc.dudy = delZ_y
					thisStruc.dvdx = delM_x
					thisStruc.dvdy = delM_y
					thisStruc.lat = yout
					thisStruc.lon = xout
					thisStruc.missing = missingVal
					thisStruc.monoWinds = ptr_new(monoFitsOut)
					thisStruc.monoBounds = ptr_new([[monolat[monoboundary]], [monolon[monoboundary]]])
					if biStaticAvailable eq 1 then begin
						thisStruc.biWinds = ptr_new(biFitsStore)
						thisStruc.biBounds = ptr_new([[bilat[biboundary]], [bilon[biboundary]]])
					endif
					thisStruc.fitted = 1
					thisStruc.dataUsed = [monoStaticAvailable, biStaticAvailable, triStaticAvailable]

					(*miscData.blendFit)[tIndex] = thisStruc


				;\\ Grab a capture of the various fields to compare between iterations...
					nPanels = 8
					nRows = 2
					nCols = nPanels/nRows
					barWid = 30
					wd = 300.
					scOff = 150
					scBar = fltarr(15, 256)
					for kk = 0, 14 do scBar[kk,*] = indgen(256)
					scbar = congrid(scBar, barWid/2., 150, /interp)
					miss = where(mnLatGrid eq missingVal)

					winX = (nPanels/nRows) * (wd + barWid)
					winY = nRows * wd
					window, 1, xs = winX, ys = winY

					red = [intarr(128), 2*indgen(128)]
					gre = intarr(256)
					blu = [255 - 2*indgen(128), intarr(128)]

					!p.charsize = 1.5
					!p.thick = 1.5

					for k = 0, nPanels - 1 do begin
						case k of
							0: begin & scale = [-200,200] & name = 'u (m/s)' & param = zonalBlended & missCol = 0 & end
							1: begin & scale = [-200,200] & name = 'v (m/s)' & param = meridBlended & missCol = 0 & end
							2: begin & scale = [-50,50] & name = 'w (m/s)' & param = verticalWind & missCol = 128 & end
							3: name = 'blank'
							4: begin & scale = [-1,1] & name = 'du/dx (10!E-3!Ns!E-1!N)' & param = delZ_x & missCol = 128 & end
							5: begin & scale = [-1,1] & name = 'dv/dy (10!E-3!Ns!E-1!N)' & param = delM_y & missCol = 128 & end
							6: begin & scale = [-1,1] & name = 'du/dy (10!E-3!Ns!E-1!N)' & param = delZ_y & missCol = 128 & end
							7: begin & scale = [-1,1] & name = 'dv/dx (10!E-3!Ns!E-1!N)' & param = delM_x & missCol = 128 & end
							else:
						endcase

						if name eq 'blank' then continue

						if k lt 2 then scale_to_range, param, scale[0], scale[1], out, scaleto=[0,254] $
							else scale_to_range, param, scale[0], scale[1], out
						out[miss] = missCol

						if k ge 2 then tvlct, red, gre, blu else loadct, 39, /silent

						tv, congrid(out, wd, wd, /interp), (k - (nCols)*(k/nCols))*(wd + barWid), winY - ((k/nCols) + 1)*wd
						tv, scbar, (k - (nCols)*(k/nCols))*(wd + barWid) + wd + 5, winY - ((k/nCols) + 1)*wd + (wd/2. - 75)

						loadct, 39, /silent
						xyouts,  (k - (nCols)*(k/nCols))*(wd + barWid) + 5,  winY - ((k/nCols) + 1)*wd + 10, $
								name, color = 255, /device, align = 0
						xyouts, (k - (nCols)*(k/nCols))*(wd + barWid) + wd + 10,  winY - ((k/nCols) + 1)*wd + (wd/2.) - 90, $
								string(scale[0], f='(i0)'), color = 255, /device, align=.5, chars = 1
						xyouts, (k - (nCols)*(k/nCols))*(wd + barWid) + wd + 10,  winY - ((k/nCols) + 1)*wd + (wd/2.) + 78, $
								string(scale[1], f='(i0)'), color = 255, /device, align=.5, chars = 1
						plots, (k - (nCols)*(k/nCols))*(wd + barWid) + [0,0,wd+barWid,wd+barWid], $
							   winY - ((k/nCols) + 1)*wd + [0, wd, wd, 0], color = 255, /device, thick= 1
					endfor
					paramsPic = tvrd(/true)

					window, 1, xs = 1200, ys = 400
					loadct, 39, /silent
					colors = [100, 150, 255]
					for ppk = 0, 2 do begin
						bounds = [ppk*400./1200, 0, (ppk*400. + 400.)/1200., 400./400.]
						case ppk of
							0: begin
								draw = 1
								pplats = monoFitsOut.lat & pplons = monoFitsOut.lon
								ppmer = monoFitsOut.merid & ppzon = monoFitsOut.zonal
							end
							1: begin
								if biStaticAvailable eq 1 then begin
									draw = 1
									pplats = ppbilat & pplons = ppbilon
									ppmer = ppbimer &  ppzon = ppbizon
								endif else begin
									draw = 0
								endelse
							end
							2: begin
								draw = 1
								sub = lindgen(floor(n_elements(mnLatGrid)/17.3))*17.3
								pplats = mnLatGrid[sub]
								pplons = mnLonGrid[sub]
								ppmer = meridBlended[sub]
								ppzon = zonalBlended[sub]
							end
						endcase

						plot_simple_map, 63.5, -146., 7., 1., 1., bounds=bounds, map=map
						if draw eq 0 then continue

						if ppk eq 2 then step = 5 else step = 1

						for k = 0, n_elements(pplats) - 1, step do begin

							if ppk eq 2 and pplats[k] eq missingVal then continue
							if ppk eq 0 then begin
								if monoFitsOut[k].station eq 'HRP' then col = 190
								if monoFitsOut[k].station eq 'PKR' then col = 90

							endif else begin
								col = colors[ppk]
							endelse

							mag = sqrt(ppmer[k]*ppmer[k] + ppzon[k]*ppzon[k])*miscData.vectorOpts.scale
							azi = atan(ppzon[k], ppmer[k])/!dtor

							get_mapped_vector_components, map, pplats[k], pplons[k], mag, azi, $
											  mapXBase, mapYBase, mapXlen, mapYlen

							arrow, 	mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
								   	mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   				color = col, thick = 1, $
					   				/data, $
					   				hsize = 5
						endfor

						for s = 0, miscData.nstations - 1 do begin
							xyouts, 440 + 320*s, 10, (*miscData.metaData[s]).site_code + ': ' + $
									time_str_from_decimalut((*miscData.stnTimes[s])[miscData.timeIndex]) + ' UT', $
									color = 255, /device, align = 0, chars = 1, chart = 1
						endfor
					endfor
					fitsPic = tvrd(/true)

					!p.charsize = 0
					!p.thick = 0

					if keyword_set(batch) then begin
						path = defaultFolderName + '\Images\Iter' + string(iter, f='(i0)') + '\'
						pname = 'Params_' + string(tIndex, f='(i04)') + '.png'
						fname = 'Field_' + string(tIndex, f='(i04)') + '.png'
						write_png, path + pname, paramsPic
						write_png, path + fname, fitsPic
					endif else begin
						path = 'C:\cal\IDLSource\NewAlaskaCode\WindFit\WindFitSavedData\Pics\'
						pname = 'Params_' + string(iter, f='(i03)') + '_' + string(boxWid,f='(i0)') + '.png'
						fname = 'Field_' + string(iter, f='(i03)') + '_' + string(boxWid,f='(i0)') + '.png
						write_png, path + pname, paramsPic
						write_png, path + fname, fitsPic
					endelse

		endfor	;\\ iteration loop

		if keyword_set(batch) then begin
			save, filename = defaultFolderName + '\Data\MiscDataSave.idlsave', miscData, /compress
		endif

	endfor	;\\ time index loop (for batch blending)

	;\\ Clear the progress bar
	if not keyword_set(outside_call) then MIWF_UpdateProgress, /reset

end