

pro sdi3k_batch_plot_latest_spex, spekfile

plot_dir = 'c:\inetpub\wwwroot\conde\sdiplots\'

sdi3k_read_netcdf_data,  spekfile, $
                         metadata=mm, zone_centers=zone_centers, zonemap=zonemap, zone_edges=zone_edges, $
                         spex=spex, spekfits=spekfits, winds=winds, /preprocess_spekfits

fact = 2
if mm.columns lt 512 then fact = 3
mm.x_center_pix = mm.x_center_pix*fact
mm.y_center_pix = mm.y_center_pix*fact
mm.rows    = mm.rows*fact
mm.columns = mm.columns*fact
zonemap    = rebin(zonemap, mm.columns, mm.rows, /sample)
zone_edges = where(zonemap ne shift(zonemap, 1,0) or zonemap ne shift(zonemap, 0, 1))

;---Determine the wavelength:
    doing_sodium = 0
    doing_red    = 0
    doing_green  = 0
    scale        = 1000.
    if abs(mm.wavelength_nm - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
    endif
    if abs(mm.wavelength_nm - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
       scale = 500.
    endif
    if abs(mm.wavelength_nm - 630.03) lt 5. then begin
       lamda = '6300'
       doing_red = 1
    endif


    if doing_green and getenv('SDI_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_ZERO_VELOCITY_FILE')
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif

;    sdi3k_drift_correct, spekfits, mm, /force, /data_based ;########
;    sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY'
;    spekfits.velocity = mm.channels_to_velocity*spekfits.velocity

    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, 1.2, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, 0.08, mm, zone_centers
    spekfits.temperature = tprarr

    trange = 600.
    if doing_green then trange = 500.
    ipeak = fltarr(mm.nzones)
    sdi3k_zenav_peakpos, spex, mm, cpos, widths=widths
    plot_options = {plot_images: 1, plot_temperature: 0, plot_los_wind: 1, plot_insprofs: 0, plot_wind_vectors:1, auto_image_lo: 0., auto_image_hi: 0.}
    if plot_options.plot_los_wind then plot_options.plot_temperature = 0
    if doing_sodium then plot_options.plot_wind_vectors = 0
    tpr  = spekfits.temperature
    nt   = n_elements(tpr)
    tord = sort(tpr)
    tlo  = 50*fix(tpr(tord(0.03*nt))/50.) -50
    thi  = 50*fix(tpr(tord(0.97*nt))/50.) + 50

    while (thi - tlo) lt trange do begin
          tlo = (tlo - 50) > 0
          thi = thi + 50
    endwhile
    tprscale = [tlo>0, thi<1500]

    brt  = spekfits.intensity
    nb   = n_elements(brt)
    bord = sort(brt)
    bhi  = brt(bord(0.98*nb))
    brtscale = [0, bhi > 5e5]

    los_scale = [-250., 250.]

    xpix    = mm.columns
    ypix    = mm.rows
    centime = (winds.start_time + winds.end_time)/2
    hhmm    = dt_tm_mk(js2jd(0d)+1, centime, format='h$:m$')

    skewarr = fltarr(mm.maxrec, mm.nzones)
    for rec=0,mm.maxrec-1 do begin
        for zidx=0,mm.nzones-1 do begin
           ospec = reform(spex(rec).spectra(zidx,*))
           ospec = shift(ospec, mm.scan_channels/2 - cpos)
           mc_moment, findgen(mm.scan_channels), ospec, mu, sigma, skew
           skewarr(rec, zidx) = skew
        endfor
    endfor
    medskew = median(skewarr)
    skewdev = stddev(skewarr)
    print, 'Median skewness for all spectra is: ', medskew
    print, 'Satndard deviation of skewness for all spectra is: ', skewdev

    load_pal, culz
    while !d.window gt 0 do wdelete, !d.window
    window, xsize=xpix, ysize=ypix, title="GI/UAF All-Sky Fabry-Perot Composite Display"
    theta = -!dtor*mm.oval_angle

    rec = mm.maxrec - 1
        sdi3k_read_netcdf_data, spekfile, image=image, range=[rec, rec]
        image  = image(0)
        zon    = winds(rec).zonal_wind
        merid  = winds(rec).meridional_wind
;        zon    = winds(rec).zonal_wind*cos(theta) - winds(rec).meridional_wind*sin(theta)
;        merid  = winds(rec).zonal_wind*sin(theta) + winds(rec).meridional_wind*cos(theta)
;---Setup scaling and a mask for the useful area of the image:
        itest = size(image(0), /tname)
        if itest eq 'STRUCT' then begin
           rad = shift(dist(xpix, xpix), xpix/2, xpix/2)
           outerz = where(rad gt xpix/2-2)
           srange = abs(image.scale(1) - image.scale(0))
           if abs(mm.rotation_from_oval) lt 2. then iimg = image.scene else  iimg = rot(image.scene, -mm.rotation_from_oval, cubic=-0.5)
           iimg   = rebin(iimg, mm.rows, mm.columns)
           imlo   = image.scale(0)-srange/10.
           imhi   = image.scale(1)+srange/10.
           if plot_options.auto_image_lo ne 0. then imlo = plot_options.auto_image_lo
           if plot_options.auto_image_hi ne 0. then imhi = plot_options.auto_image_hi
           green  = bytscl(iimg, min=imlo, max=imhi, top=254)
           green(outerz)  = 0
        endif

        rgblimz = [[0, 9e39], [brtscale] , [0, 9e39]]
        indata  = [[spekfits(rec).temperature], [spekfits(rec).intensity], [spekfits(rec).temperature]]
        if plot_options.plot_temperature then begin
           rgblimz = [[tprscale], [brtscale] , [0, 9e39]]
        endif
        if plot_options.plot_los_wind then begin
           rgblimz = [[los_scale], [brtscale] , [0, 9e39]]
           indata  = [[spekfits(rec).velocity], [spekfits(rec).intensity], [spekfits(rec).temperature]]
        endif

        sdi3k_one_rgbmap, mm, xpix, indata, rgblimz, zonemap, red, mapg, blue, azimuth_rotation=0
        if itest ne 'STRUCT' then green = mapg

        if not(plot_options.plot_images)      then green = green*0.0001

        erase
        tv, [[[red]], [[green]], [[blue]]], 0, (ypix - xpix)/2 - (ypix/2 - mm.y_center_pix) , true=3
        screen = tvrd(/true)
        red    = reform(screen(0,*,*))
        green  = reform(screen(1,*,*))
        blue   = reform(screen(2,*,*))
        red(zone_edges)  = 0
        green(zone_edges) = 0
        blue(zone_edges) = 0
        tv, [[[red]], [[green]], [[blue]]], true=3

;-------Draw the wind vectors:
        pix = min([mm.rows, mm.columns])
        zx  = zone_centers(*,0)*mm.columns
        zy  = zone_centers(*,1)*mm.rows
        x0 = zx - 0.25*pix*zon/scale
        x1 = zx + 0.25*pix*zon/scale
        y0 = zy + 0.25*pix*merid/scale
        y1 = zy - 0.25*pix*merid/scale
        if plot_options.plot_wind_vectors then arrow, x0, y0,x1, y1, color=culz.yellow, thick=2, hthick=2
;---Plot the spectra:
    for zidx=0,mm.nzones-1 do begin
        xtwk = 0.22/mm.rings
        xtwk = 0.30/mm.rings
        ytwk = 0.18/mm.rings
        edge = [0.5, 0.5]
        j=zidx
        lolef = [1.0*zone_centers(j, 0) - xtwk, zone_centers(j, 1) - ytwk]; + edge
        uprgt = [1.0*zone_centers(j, 0) + xtwk, zone_centers(j, 1) + ytwk]; + edge
        cell  = [lolef(0:1), uprgt(0:1)]
        !p.position =  cell
        xz    = mm.scan_channels/2
        yz    = 0
        y1    = max(spex(rec).spectra(j,*))
        ospec = reform(spex(rec).spectra(zidx,*))
        ospec = shift(ospec, mm.scan_channels/2 - cpos)
        yr    = [min(ospec), max(ospec)]

        skycul=culz.white
        if (abs(skewarr(rec,zidx) - medskew) gt (2*skewdev > 0.16) or spekfits(rec).chi_squared(zidx) gt 20) and $
           not(doing_sodium) then skycul = culz.cyan
        plot, ospec, color=skycul, xstyle=5, ystyle=5, /noerase, $
              yrange=yr, thick=2;, psym=1, symsize=0.25
        axis, xaxis=0, xstyle=1, color=culz.white, xticklen=.07, $
              xtickv = [0,31,63,95,127], xticks = 4, $
              xtickname = [' ',' ',' ',' ',' ']
        oplot, [xz, xz], [min(ospec), max(ospec)], color=culz.white
       !p.position =  0
    endfor


;-------Add the annotation in each of the four corners:
       js = centime(rec)
       sname = 'Poker Flat!CAlaska'
       exptime = strcompress(string((spex(rec).end_time - spex(rec).start_time)/60., format='(f9.1)'), /remove_all)
       if strpos(strupcase(mm.site), 'MAWSON') ge 0 then sname = 'Mawson!CAntarctica'
       xyouts, /normal, .03, .96,  dt_tm_mk(js2jd(0d)+1, js, format='Y$-n$-0d$'), color=culz.white, charsize=2.5, charthick=3
       xyouts, /normal, .03, .925, dt_tm_mk(js2jd(0d)+1, js, format='h$:m$:s$'),  color=culz.white, charsize=2.5, charthick=3
       xyouts, /normal, .03, .890, exptime + ' min',                              color=culz.white, charsize=2.5, charthick=3
       xyouts, /normal, .97, .96, sname,                                          color=culz.white, charsize=2.5, charthick=3, align=1
       xyouts, /normal, .97, .88,  string(fix(10*mm.wavelength_nm), format='(i4.4)') + 'A', color=culz.white, charsize=2.5, charthick=3, align=1
       xyouts, /normal, .50, .96, '!5S!3', charsize = 3, charthick = 3, color=culz.white, align=0.5
       xyouts, /normal, .50, .01, '!5N!3', charsize = 3, charthick = 3, color=culz.white, align=0.5
       xyouts, /normal, .02, .50, '!5W!3', charsize = 3, charthick = 3, color=culz.white, align=0.5
       xyouts, /normal, .98, .50, '!5E!3', charsize = 3, charthick = 3, color=culz.white, align=0.5
;-------Add the velocity scale marker if needed:
        if plot_options.plot_wind_vectors then begin
           x0 = xpix - 30 - 0.125*pix
           x1 = xpix - 30
           y0 = 70
           y1 = y0
           arrow, x0, y0,x1, y1, color=culz.white, thick=3, hthick=2
           xyouts, /normal, .97, .03,  strcompress(string(scale/4., format='(i4)'), /remove_all) + ' m/s', $
                    color=culz.white, charsize=2.5, charthick=3, align=1
        endif

;-------The following will be used if either temperature or los_wind color bars are needed:
        xlo = 0.045
        xhi = 0.20
        ylo = 0.06
        yhi = 0.08
        rgb_vex = {red: bytarr(255), green: bytarr(255), blue: bytarr(255)}
        rgb_vex.green = bytarr(255)

;------Add the temperature color scale bar if needed:
    if plot_options.plot_temperature then begin
        unitz   = 'K'
        rgb_vex.red   = 0.7*bindgen(255)
        rgb_vex.blue  = 0.7*(255 - bindgen(255))
        mccolbar, [xlo, ylo, xhi, yhi], 0, 255, tprscale(0), tprscale(1), $
                      parname=' ', units=unitz, $
                      color=culz.white, thick=3, charsize=2.5, format='(i6)', $
                     /horizontal, /both_units, rgb_vector=rgb_vex, reserved_colors=20
    endif

;------Add the LOS_wind color scale bar if needed:
    if plot_options.plot_los_wind then begin
        unitz   = ' m/s'
        rgb_vex.red  =  2.*(bindgen(255) - 128) > 0
        rgb_vex.blue = -2.*(bindgen(255) - 128) > 0
        mccolbar, [xlo, ylo, xhi, yhi], 0, 255, los_scale(0), los_scale(1), $
                      parname=' ', units=unitz, $
                      color=culz.white, thick=3, charsize=1.5, format='(i6)', $
                     /horizontal, /both_units, rgb_vector=rgb_vex, reserved_colors=20
    endif
    empty
    sdi3k_batch_plotsave, plot_dir, mm, 'Latest_Spectra', plot_folder='RealTime'
    wait, 0.001
end
