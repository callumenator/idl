
pro plot_zone_spectra

	file = 'C:\cal\FPSData\Gakona_Realtime\HRP_2011_081_HAARP_Campaign_Laser6328_Red_Cal_Date_03_22.nc'
	file = 'C:\cal\FPSData\Gakona_Realtime\HRP_2011_081_HAARP_Campaign_630nm_Red_Sky_Date_03_22.nc'
	file = 'C:\cal\FPSData\Gakona_Realtime\HRP_2011_082_HAARP_Campaign_630nm_Red_Sky_Date_03_23.nc'
	file = dp()
	sdi3k_read_netcdf_data, file, spekfits=fits, spex=spex, meta=meta;, zone_centers=centers
stop
	win = 600.
	loadct, 39, /silent
	window, 0, xs = win, ys = win
	for t = 0, meta.maxrec - 1 do begin

		erase, 0
		for z = 0, meta.nzones - 1 do begin

			cn = reform(centers[z,0:1])
			pos = [cn[0]-20/win, cn[1]-20/win, cn[0]+20/win, cn[1]+20/win]
			plot, indgen(meta.scan_channels), spex[t].spectra[z,*] - min(spex[t].spectra[z,*]), pos=pos, /noerase, $
				xstyle=5, ystyle=5, psym=3, color = 255, xrange = [30, 120], title = string(z,f='(i0)')

		endfor

		wait, 0.2
	endfor
end