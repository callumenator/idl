pro sdi3k_batch_wind_summary, ncfile, culz, wscale, hwm, box=box, drift_mode=drift_mode

if not(keyword_set(box)) then box = [1800, 1200]
if not(keyword_set(drift_mode)) then drift_mode = 'data'
data_based_drift = strupcase(drift_mode) eq 'DATA'

sdi3k_read_netcdf_data, ncfile, metadata=mm, winds=winds
jlo = 0
jhi = mm.maxrec - 1
sdi3k_read_netcdf_data, ncfile, metadata=mm, winds=winds, spekfits=spekfits, windpars=windpars, range=[jlo,jhi]
    goods = where(median(spekfits.signal2noise, dim=1) gt 150, ng)
    if ng gt 0 then begin
       winds = winds(goods)
       spekfits = spekfits(goods)
       windpars = windpars(goods)
    endif
    mm.maxrec = n_elements(spekfits)
timlimz = [(min(winds.start_time) + min(winds.end_time))/2, (max(winds.start_time) + max(winds.end_time))/2]
deltime = timlimz(1) - timlimz(0)
if deltime eq 0 then return

wrange = 1.11*wscale
vscale = 0.5*[-wrange, wrange]
vscale = [-167, 167]

     coords = {index: 0, name: ['Magnetic']}
     zonal  = windpars.mag_zonal_wind
     merid  = windpars.mag_meridional_wind
     sigzon = windpars.sigmagzon
     sigmer = windpars.sigmagmer
     if coords.index eq 1 then begin
        zonal  = windpars.geo_zonal_wind
        merid  = windpars.geo_meridional_wind
        sigzon = windpars.siggeozon
        sigmer = windpars.siggeomer
     endif

;---Setup the HWM stuff:
    hwm_dll  = 'C:\cal\IDLSource\Code\HWM\nrlhwm93.dll'
    if not(file_test(hwm_dll)) then hwm_dll = 'c:\users\conde\main\idl\hwm\nrlhwm93.dll'
    nhwm     = 32
    hwm_vals = fltarr(2, 3, nhwm)
    tmx       = findgen(nhwm)*deltime/(nhwm-1) + timlimz(0)
    sec   = 0.
    lat   = float(mm.latitude)
    lon   = float(mm.longitude)
    if lon lt 0 then lon = lon+360.
;    hwm   = {altitude: 240., F107: 100., ap: 15}
;    obj_edt, hwm, title='HWM Parameters'
    f107  = hwm.f10pt7
    alt   = hwm.hwm_height
    f107a = f107
    ap    = fltarr(7)
    ap(0) = hwm.ap
    magrot= !dtor*(mm.oval_angle)
    if coords.index eq 1 then magrot = 0.
    mass  = 48L
    t     = fltarr(2)
    d     = fltarr(8)
    delz  = 20.
    if alt lt 180. then delz = 10.
    if alt lt 115. then delz = 5.
    flags = fltarr(25) + 1; Control flags (see HWM-93 FORTRAN source code for usage)
    w     = fltarr(2)
    aplab    = strcompress(string(ap(0), format='(i8)'), /remove_all)
    f107lab  = strcompress(string(f107,  format='(i8)'), /remove_all)
    hwm_lab  = 'NRL-HWM93 model at ' + 'Ap=' + aplab + ', F10.7=' + f107lab

    for idz=-1,1  do begin
        for j=0,nhwm-1 do begin
            yyddd  = long(dt_tm_mk(js2jd(0d)+1, tmx(j), format='y$doy$'))
            js2ymds, tmx(j), yy, mmm, dd, ss
            ss     = float(ss)
            lst    = ss/3600. + lon/15.
            if lst lt 0  then lst = lst + 24.
            if lst gt 24 then lst = lst - 24.
            zv     = alt + idz*delz
            w      = fltarr(2)
            result = call_external(hwm_dll,'nrlhwm93', yyddd, ss, zv, lat, lon, lst, f107a, f107, ap, flags,w)
;            print, yyddd, ss, zv, lat, lon, lst, f107a, f107, ap, flags,w
            hwm_vals(1, idz+1, j) = w(1)*cos(magrot) - w(0)*sin(magrot)
            hwm_vals(0, idz+1, j) = w(0)*cos(magrot) + w(1)*sin(magrot)
;            hwm_vals(0, idz+1, j) = w(0)
;            hwm_vals(1, idz+1, j) = w(1)
            wait, 0.002
         endfor
     endfor

;--Now start plotting:
while !d.window gt 0 do wdelete, !d.window
window, xsize=box(0), ysize=box(1)
erase, color=culz.white

lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
posarr = spekfits.velocity
sdi3k_timesmooth_fits,  posarr, 1.5, mm
;drftfit   = poly_fit((spekfits.start_time + spekfits.end_time)/2 - spekfits(0).start_time, posarr(0,*), 4, measure_errors=1.+spekfits.sigma_velocity(0), yfit=drift, /double)
;vz      = mm.channels_to_velocity*(spekfits.velocity(0) - drift)

sdi3k_drift_correct, spekfits, mm, /force, data_based=data_based_drift, insfile=drift_mode ;########

;sdi3k_drift_correct, spekfits, mm, /force, /data
vz = mm.channels_to_velocity*spekfits.velocity(0)
deg_tik,  timlimz, ttvals, nttix, minor, minimum=5
xtn     = dt_tm_mk(js2jd(0d)+1, ttvals, format='h$:m$')

    !p.position = [0.14, 0.65, 0.88, 0.93]
    plot, timlimz, [-wrange, wrange], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          title=mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, timlimz(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          ytitle=coords.name + ' Zonal!C!CWind [m s!U-1!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2

          tvlct, rr, gg, bb, /get
          ;pastel_palette, factor=0.3
          load_pal, idl=[39], culz
          for j=1,n_elements(winds(0).zonal_wind)-1 do begin
              oplot, (winds.start_time + winds.end_time)/2, winds.zonal_wind(j), $
                      color=culz.imgmin + float(j)*(culz.imgmax - culz.imgmin - 1)/mm.nzones, $
                      psym=6, symsize=0.4, thick=2
          endfor
          tvlct, rr, gg, bb

          mc_oploterr, (windpars.start_time + windpars.end_time)/2, zonal, sigzon, $
                        bar_color=culz.black, thick=4, symbol_color=culz.slate, line_color=culz.blue, /two, psym=6


        tm       = timlimz(0) + 0.97*deltime
        ym       = 0.8*wrange
        for idz=-1,1 do begin
            thk = 1 + (idz eq 0)
            oplot, tmx, hwm_vals(1, idz+1, *), thick=thk, linestyle=1, color=culz.orange
            zlab = strcompress(string(alt + idz*delz, format='(i8)'), /remove_all)
            t1   = timlimz(1) - 0.03*deltime
            sgn  = 0
            if idz ne 0 then sgn  = (hwm_vals(0, idz+1, nhwm-1) - hwm_vals(0, 1, nhwm-1))/abs(hwm_vals(0, idz+1, nhwm-1) - hwm_vals(0, 1, nhwm-1))
            y1   = hwm_vals(1, 1, nhwm-4) + abs(idz)*sgn*wrange*0.09; - 0.06*wrange
            xyouts, t1, y1, zlab +' km', charsize=0.9, color=culz.orange, align=1
        endfor
    xyouts, tm, ym, hwm_lab, charsize=1.2, color=culz.orange, align=1

    !p.position = [0.14, 0.37, 0.88, 0.65]
    plot, timlimz, [-wrange, wrange], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle=coords.name + ' Meridional!C!CWind [m s!U-1!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2

          tvlct, rr, gg, bb, /get
          load_pal, culz, idl=[39]
          for j=1,n_elements(winds(0).meridional_wind)-1 do begin
              oplot, (winds.start_time + winds.end_time)/2, winds.meridional_wind(j), $
                      color=culz.imgmin + float(j)*(culz.imgmax - culz.imgmin - 1)/mm.nzones, $
                      psym=6, symsize=0.4, thick=2
          endfor
          tvlct, rr, gg, bb

          mc_oploterr, (windpars.start_time + windpars.end_time)/2, merid, sigmer, $
                        bar_color=culz.black, thick=4, symbol_color=culz.rose, line_color=culz.red, /two, psym=6

        tm       = timlimz(0) + 0.97*deltime
        ym       = 0.8*wrange
        for idz=-1,1 do begin
            thk = 1 + (idz eq 0)
            oplot, tmx, hwm_vals(0, idz+1, *), thick=thk, linestyle=1, color=culz.orange
            zlab = strcompress(string(alt + idz*delz, format='(i8)'), /remove_all)
            t1   = timlimz(1) - 0.03*deltime
            sgn  = 0
            if idz ne 0 then sgn  = (hwm_vals(0, idz+1, nhwm-1) - hwm_vals(0, 1, nhwm-1))/abs(hwm_vals(0, idz+1, nhwm-1) - hwm_vals(0, 1, nhwm-1))
            y1   = hwm_vals(0, 1, nhwm-4) + abs(idz)*sgn*wrange*0.09; - 0.06*wrange
            xyouts, t1, y1, zlab +' km', charsize=0.9, color=culz.orange, align=1
        endfor
    xyouts, tm, ym, hwm_lab, charsize=1.2, color=culz.orange, align=1

    !p.position = [0.14, 0.09, 0.88, 0.37]
     plot, timlimz, vscale, /noerase, color=culz.black, /nodata, /xstyle, ystyle=9, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle='Vertical!C!CWind [m s!U-1!N]'
          axis, xaxis=0, xtickname=xtn, color=culz.black, xtitle='Time [Hours UT]', charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2
          mc_oploterr, (spekfits.start_time + spekfits.end_time)/2, vz, mm.channels_to_velocity*spekfits.sigma_velocity(0), $
                        bar_color=culz.ash, thick=1, symbol_color=culz.black, line_color=culz.olive, /two, psym=6
    plot, timlimz, [-1.1, 1.1], /noerase, color=culz.white, /nodata, /xstyle, ystyle=9, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle='Vertical!C!CWind [m s!U-1!N]'
    axis, yaxis=1, color=culz.rose, $
          ytitle='1000 x Divergence [s!U-1!N]!C!C1000 x Vorticity [s!U-1!N]', $
          charsize=2, charthick=3, ythick=3
    axis, yaxis=1, color=culz.slate, $
          ytitle='1000 x Divergence [s!U-1!N]', $
          charsize=2, charthick=3, ythick=3
    axis, yaxis=1, color=culz.black, $
          charsize=2, charthick=3, ythick=3
    oplot,(windpars.start_time + windpars.end_time)/2, windpars.divergence,    color=culz.slate, thick=3
    oplot,(windpars.start_time + windpars.end_time)/2, windpars.vorticity,     color=culz.rose,  thick=3
;    xyouts, timlimz(0) + 0.08*(timlimz(1) - timlimz(0)), -0.9, 'Vertical Wind', color=culz.olive, charsize=1.5, charthick=2
;    xyouts, timlimz(0) + 0.22*(timlimz(1) - timlimz(0)), -0.9, 'Divergence',    color=culz.slate, charsize=1.5, charthick=2
;    xyouts, timlimz(0) + 0.34*(timlimz(1) - timlimz(0)), -0.9, 'Vorticity',     color=culz.rose,  charsize=1.5, charthick=2

    plot, timlimz, vscale, /noerase, color=culz.black, /nodata, /xstyle, ystyle=9, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle='Vertical!C!CWind [m s!U-1!N]', ytick_get=tkv
    axis, yaxis=0, color=culz.olive, $
          ytitle='Vertical!C!CWind [m s!U-1!N]', $
          charsize=2, charthick=3, ythick=3, ytickv=tkv, yminor=1, yticks=n_elements(tkv)+1
    axis, yaxis=0, color=culz.black, $
          charsize=2, charthick=3, ythick=3, ytickv=tkv, yminor=1, yticks=n_elements(tkv)+1

    xyouts, 0.89, 0.91, 'Note: Error bars !Cdenote standard !Cdeviations !C(across all zones) !Cof zonal and !Cmeridional wind !Ccomponents at !Ceach observation !Ctime.', $
            color=culz.black, charsize=1.3, charthick=2, /normal
    empty
!p.position = 0
sdi3k_read_netcdf_data, ncfile, /close
end
