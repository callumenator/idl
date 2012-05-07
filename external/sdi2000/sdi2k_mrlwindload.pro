pro sdi2k_mrlwindload, exposure=exposure, noshow=noshow
@mrlinc.pro
@sdi2kinc.pro

common windstuff, windfit, tcen, tlist

 sdi2k_data_init, culz
 if n_elements(windfile) eq 0 then windfile = 'Bound to not exist, I hope'
 sdi_ffil = "sky*.pf"

NEW_FILE:
 if not(fexist(string(sdi.name))) then begin
    pth = sdi.path
    mrl_get_filename, windfile, ok, /must_exist, /read, $
       path=pth, filter=sdi_ffil, prompt="Select an SDI netCDF file:"
    sdi.path = pth
    sdi.name = windfile
    sdi2k_ncopen, windfile, ncid, 0
    sdi2k_build_windres, ncid, windfit
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    record = 0
    tlist = strarr(maxrec)
    tcen  = dblarr(maxrec)
    for rec=record,maxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        tcen(rec) = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
        hhmm = dt_tm_mk(js2jd(0d)+1, tcen(rec), format='h$:m$')
        tlist(rec) =  hhmm
    endfor
    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1
 endif
 datestr = dt_tm_mk(js2jd(0d)+1, tcen(0), format='0d$ n$ Y$')

 if n_elements(exposure) eq 0 then begin
    mcchoice, "Select a time on " + datestr, $
        [tlist, 'New Day'], choice

    if choice.name eq 'New Day' then sdi.name = 'Not Loaded'
    if choice.name eq 'New Day' then goto, NEW_FILE
    exposure = choice.index
 endif


 sdi.sectime = tcen(exposure)
 now.hour  = dt_tm_mk(js2jd(0d)+1, tcen(exposure), format='h$')
 now.min   = dt_tm_mk(js2jd(0d)+1, tcen(exposure), format='m$')
 now.year  = dt_tm_mk(js2jd(0d)+1, tcen(exposure), format='Y$')
 now.month = dt_tm_mk(js2jd(0d)+1, tcen(exposure), format='n$')
 now.day   = dt_tm_mk(js2jd(0d)+1, tcen(exposure), format='0d$')

 set_plot, 'Z'
 xsize = 800
 ysize = xsize
 xcen  = xsize/2
 ycen  = ysize/2
 rr    = xsize*0.3
 device, set_resolution=[xsize, ysize]
 geo = {xcen: xsize/2, ycen: ysize/2, radius: rr, wscale: sdi.windscale, $
	       perspective: 'Map', orientation: 'Geographic North at Top'}
 erase, color=culz.white
 sdi2k_one_windplot, windfit, tcen, exposure, geo, thick=6, color=culz.green, zone_mask=zone_mask

 img_sdi   = tvrd()
 sdi.left  = xcen  - rr
 sdi.right = xcen  + rr
 sdi.bottom = ycen - rr
 sdi.top    = ycen + rr
 sdi.lon_pix = xsize
 sdi.lat_pix = ysize

 hdist   = max(windfit.zonal_distances)/1000.
 degdist = hdist/111.12
 sdi.minlat = site.latitude - degdist
 sdi.maxlat = site.latitude + degdist
 sdi.minlon = site.longitude - degdist/cos(site.latitude*!dtor)
 sdi.maxlon = site.longitude + degdist/cos(site.latitude*!dtor)
 if sdi.minlon lt 0 then sdi.minlon = sdi.minlon + 360.
 if sdi.maxlon lt 0 then sdi.maxlon = sdi.maxlon + 360.
 sdi.lat_res = (sdi.maxlat - sdi.minlat)/(sdi.top - sdi.bottom)
 sdi.lon_res = (sdi.maxlon - sdi.minlon)/(sdi.right - sdi.left)
 set_plot, 'win'
end