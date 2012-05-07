	xx = 'D:\users\SDI3000\Data\HAARP\HRP_2009_360_Elvey_630nm_Red_Sky_Date_12_26.nc'
	drift_mode = 'data'

    sdi3k_read_netcdf_data, xx, metadata=mm, zonemap=zonemap, winds=winds, spekfits=spekfits, windpars=windpars, zone_centers=zone_centers

    year      = strcompress(string(mm.year),             /remove_all)
    doy       = strcompress(string(mm.start_day_ut, format='(i3.3)'),     /remove_all)
    spekfits.velocity = spekfits.velocity*mm.channels_to_velocity
    speksave  = spekfits
    sdi3k_drift_correct, spekfits, mm

;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')
    thr    = dt_tm_mk(js2jd(0d)+1, tcen, format='sam$')/3600.

    load_pal, culz
	plot, thr, speksave.velocity(0,*)
	oplot, thr, spekfits.velocity(0,*), color=culz.red

end