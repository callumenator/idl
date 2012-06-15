
pro tally_davis_spectra

	path = 'c:\cal\fpsdata\davis\'
	file = file_search(path + '*', count = nfiles)

	lasCount = 0L
	skyCount = 0L
	for j = 0, nfiles - 1 do begin

		restore, file[j]
		skyCount += nSky
		lasCount += nLas

		wait, 0.001
		print, j, nfiles
	endfor

	print, lasCount, skyCount

end