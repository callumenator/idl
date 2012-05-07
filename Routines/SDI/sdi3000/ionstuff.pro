function sdi_interp, valbefore, valafter, timebefore, timeafter, when
         return, valbefore + (valafter - valbefore)*(when - timebefore)/(timeafter - timebefore)
end


;====================================================================================================
emission_height = 240.   ; km
ion_density     = 1d11   ; per cubic meter
neutral_density = 1.9d15 ; per cubic meter
reduced_mass    = 0.5*16.*1.6605402d-27

ncfile  = dialog_pickfile(path='D:\users\SDI3000\Data\poker', filter='*.nc')

sdi3k_read_netcdf_data,  ncfile, $
                         metadata=mm, zone_centers=zone_centers, zone_edges=zone_edges, zonemap=zonemap, $
                         winds=winds, spekfits = spekfits

pfisfiles = dialog_pickfile(path='D:\users\conde\main\Poker_SDI\Publications_and_Presentations\pfisr_2010_workshop\', $
                            filter='*.txt', title='Add PFISR files?', /multi)
if pfisfiles(0) eq '' then return
read_pfisr_convection, pfisfiles, pfiscon

overlap = where(spekfits.start_time gt pfiscon(0).end_time and spekfits.end_time lt pfiscon(n_elements(pfiscon)-1).start_time, nn)
if nn eq 0 then return
spekfits = spekfits(overlap)
winds    = winds(overlap)


;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')

    mcchoice, 'Start Time: ', tlist, choice, $
               heading = {text: 'Start at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jlo = choice.index
    mcchoice, 'End Time: ', tlist, choice, $
               heading = {text: 'End at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jhi = choice.index
    tcen = tcen(jlo:jhi)
    spekfits = spekfits(jlo:jhi)
    winds = winds(jlo:jhi)


;---Interpolate the ion drifts to the sdi observation times:
    iondrift = fltarr(2, n_elements(spekfits))
    concen = (pfiscon.start_time + pfiscon.end_time)/2.
    for j=0, n_elements(spekfits)-1 do begin
         after = where(concen gt  tcen(j))
         after = after(0)
         before = after - 1
         iondrift(0, j) = sdi_interp(pfiscon(before).zonal_velocity,      pfiscon(after).zonal_velocity,      concen(before), concen(after), tcen(j))
         iondrift(1, j) = sdi_interp(pfiscon(before).meridional_velocity, pfiscon(after).meridional_velocity, concen(before), concen(after), tcen(j))
    endfor


    temperatures = median(spekfits.temperature, dimension=1)
    collfreq = ion_density*3.42e-17*sqrt(temperatures)*(1.08 - 0.139*alog10(temperatures) + 4.51e-3*alog10(temperatures)*alog10(temperatures))
    nearlat  = where(abs((pfiscon(0).lo_lat + pfiscon(0).hi_lat)/2 - reform(winds(0).zone_latitudes)) lt 0.3, nn)
    x_vel_diff = reform(iondrift(0,*)) - total(winds.zonal_wind(nearlat), 1)/nn
    y_vel_diff = reform(iondrift(1,*)) - total(winds.meridional_wind(nearlat), 1)/nn
    xdrft = reform(iondrift(0,*))
    ydrft = reform(iondrift(1,*))
    x_acc = collfreq*xdrft
    y_acc = collfreq*ydrft
    x_acn = collfreq*x_vel_diff
    y_acn = collfreq*y_vel_diff

    joule   = reduced_mass*collfreq*neutral_density*((x_vel_diff)*(x_vel_diff) + (y_vel_diff)*(y_vel_diff))
    jstatic = reduced_mass*collfreq*neutral_density*((xdrft)*(xdrft)           + (ydrft)*(ydrft))

load_pal, culz
window, xsize=1400, ysize=700
erase, color=culz.white
lamlab  = ' !4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
date_form = '0d$-n$-Y$'
timlimz = [tcen(0)- 0.5*3600, tcen(n_elements(tcen)-1) + 0.25*3600]

   !p.position = [0.15, 0.51, 0.95, 0.93]
   parlimz = [-0.05, 1.]*1e-8
    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=4, ythick=4, $
          charsize=2., charthick=3, $
          title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format=date_form)  + lamlab, $
          ytitle='Volumetric Power!C !CDensity [Wm!u-3!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2.3, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2.3, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
    oplot,timlimz, [0., 0.], color=culz.ash, linestyle=2

    pastel_palette, factor=0.5
    oplot, tcen, jstatic, thick=3, color=culz.olive
    xyouts, 0.55, 0.83, 'Green: Joule heating, without wind', /normal, charsize=2, charthick=2, color=culz.olive, align=0
    pastel_palette, factor=-2.
    oplot, tcen, joule, thick=3, color=culz.red
    xyouts, 0.55, 0.87, 'Red: Joule heating, with wind', /normal, charsize=2, charthick=2, color=culz.red, align=0


   !p.position = [0.15, 0.09, 0.95, 0.51]
    parlimz = [-0.1, 0.1]
    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=4, ythick=4, $
          charsize=2, charthick=3, $
          title = ' ', $
          ytitle='Ion Drag Acceleration!C !CVector [m/s!U-2!N]'
          oplot,timlimz, [0., 0.], color=culz.ash, linestyle=2

          deg_tik, timlimz, ttvals, nttix, minor, minimum=5
          ttvals   = ttvals + 20.
          xttl     = 'Time [Hours UT]'
          tick_fmt = 'h$'
          if max(timlimz) - min(timlimz) lt  5L*3600L then tick_fmt = 'h$:m$'
          if max(timlimz) - min(timlimz) gt 48L*3600L then begin
             tick_fmt = 'n$-0d$'
             xttl     = 'UT Date'
          endif

          xtn = dt_tm_mk(js2jd(0d)+1, ttvals, format=tick_fmt)

          axis, xaxis=0, xtickname=xtn, color=culz.black, xtitle=xttl, charsize=2, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
;          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, 2, charthick=2, $
 ;               xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4


;-------Draw the velocity difference vectors:
        base  = convert_coord(tcen, fltarr(n_elements(tcen)), /data, /to_device)

        headx = convert_coord(tcen, x_acc, /data, /to_device)
        heady = convert_coord(tcen, y_acc, /data, /to_device)
        headx = base(0,*) + headx(1, *) - base(1,*)
        pastel_palette, factor=0.5
        arrow, base(0, *), base(1, *), reform(headx), heady(1, *), color=culz.blue, thick=3, hthick=3, hsize=10
        xyouts, 0.55, 0.41, 'Blue: Ion drag acceleration without wind', /normal, charsize=2, charthick=2, color=culz.blue, align=0
        pastel_palette, factor=-2.

        headx = convert_coord(tcen, x_acn, /data, /to_device)
        heady = convert_coord(tcen, y_acn, /data, /to_device)
        headx = base(0,*) + headx(1, *) - base(1,*)
        arrow, base(0, *), base(1, *), reform(headx), heady(1, *), color=culz.black, thick=2, hthick=2, hsize=10

        xyouts, 0.55, 0.45, 'Black: Ion drag acceleration with wind', /normal, charsize=2, charthick=2, color=culz.black, align=0

end
