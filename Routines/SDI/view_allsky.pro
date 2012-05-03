
pro view_allsky

	path = 'c:\cal\fpsdata\gakona_realtime\'
	filter = '*632*.nc'
	files = file_search(path + filter, count = nf)

	if nf gt 0 then begin
		sdi3k_read_netcdf_data, files[0], meta=meta, images=images
	endif
	stop

end