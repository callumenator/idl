
pro drift_correct, metaData, inSpeks, correctedLos

	filename = metaData.fullname
	splitName = strsplit(file_basename(filename), '_', /extract)
	lasName = file_dirname(filename) + '\' + splitName[0] + '_' + $
			  splitName[1] + '_' + splitName[2] + '_' + splitname[3] + '_Laser*'


	search = file_search(lasName, count = nfound)

	skyLos = inSpeks.velocity

	if nfound eq 1 then begin
		sdi3k_read_netcdf_data, search[0], metadata=lasMeta, spekfits=lasSpeks
		drift = median(lasSpeks.velocity*(632.8/630.0), dim=1)
		drift = smooth(drift, 5, /edge)
		drift = interpol(drift, lasSpeks.start_time, inSpeks.start_time)

		;\\ Correct the zenith wind first, and then check for residual drift
			vz = skyLos[0,*] - drift
			cf = linfit(inSpeks.start_time, vz, yfit = line)
			;line = smooth(vz, 20, /edge)

		for z = 0, metaData.nzones - 1 do begin
			skyLos[z,*] = skyLos[z,*] - drift - line
		endfor
	endif else begin
		;\\ No laser for drift correction
		stop
	endelse

	correctedLos = skyLos

end