ncfile  = dialog_pickfile(path='D:\users\SDI3000\Data\poker', filter='*.nc')
pfisfiles = dialog_pickfile(path='D:\users\conde\main\Poker_SDI\Publications_and_Presentations\pfisr_2010_workshop\', $
                            filter='*.txt', title='Add PFISR files?', /multi)

sdi3k_read_netcdf_data,  ncfile, $
                         metadata=mm, zone_centers=zone_centers, zone_edges=zone_edges, zonemap=zonemap, $
                         winds=winds
read_pfisr_convection, pfisfiles, pfiscon
pfisbeams = uniq_elz(pfiscon.beam)
pfisbeams = pfisbeams(sort(pfisbeams))

while !d.window gt 0 do wdelete, !d.window
window, xsize=1500, ysize=1000
load_pal, culz


;---Get a time array:
    tt = (winds.start_time + winds.end_time)/2.
    timlimz = [min(winds.start_time), max(winds.end_time)]
    parlimz = [-330., 330.]

    erase, color=culz.white
    lamlab  = ' !4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    date_form = '0d$-n$-Y$'
    if abs(timlimz(1) - timlimz(0)) gt 86400L*1.5 then date_form = 'n$-Y$, '
    if abs(timlimz(1) - timlimz(0)) gt 86400L*32. then date_form = ' '


   !p.position = [0.12, 0.51, 0.95, 0.93]
    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=4, ythick=4, $
          charsize=2.3, charthick=3, $
          title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format=date_form)  + lamlab, $
          ytitle='Magnetic Zonal Wind [ms!u-1!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2.3, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2.3, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
    oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2
    for j=1,n_elements(winds(0).zonal_wind)-1 do begin
        oplot, tt, winds.zonal_wind(j), color=culz.imgmin + float(j)*(culz.imgmax - culz.imgmin)/120.
    endfor
    oplot, tt, (winds.zonal_wind(57) + winds.zonal_wind(58))/2, color=culz.black, thick=4
    xyouts, /normal, .60, .87, '!5Colors: All FPS Zones!3',              color=culz.black, charsize=2.5, align=0, charthick=3
    xyouts, /normal, .60, .83, '!5Black: Zones Near PFISR Beams!3',  color=culz.black, charsize=2.5, align=0, charthick=3

    parlimz = [-2200, 2200]
    !p.position = [0.12, 0.09, 0.95, 0.51]
    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=4, ythick=4, $
          charsize=2.3, charthick=3, $
          title = ' ', $
          ytitle='Zonal Ion Drift [ms!u-1!N]'
    oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2

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

          axis, xaxis=0, xtickname=xtn, color=culz.black, xtitle=xttl, charsize=2.3, charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
;          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2, charthick=3, $
;                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4

           for bidx=0,n_elements(pfisbeams)-1 do begin
              thisbeam = where(pfiscon.beam eq pfisbeams(bidx))
              thisbeam = pfiscon(thisbeam)
              tp = (thisbeam.start_time + thisbeam.end_time)/2.
;              oplot, tp, mc_im_sm(thisbeam.zonal_velocity, 9), color=culz.imgmin + float(bidx)*(culz.imgmax - culz.imgmin)/12., thick=2
              oplot, tp, thisbeam.zonal_velocity, color=culz.imgmin + float(bidx)*(culz.imgmax - culz.imgmin)/9., thick=2
           endfor
           xyouts, /normal, .60, .45, '!5All PFISR Beams!3',              color=culz.black, charsize=2.5, align=0, charthick=3
     !p.position = 0

end