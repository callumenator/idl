pro NTC, change_array

change_array = long(change_array)
negs = where(change_array lt 0, np)
        if (np gt 0) then change_array(negs) = change_array(negs) + 65536
end

pro getmdl, mdldata, monname
    mfile = dialog_pickfile(path="C:\users\conde\main\Poker_SDI\Qian_Wu_December_08_Campaign\", $
                            filter="*.sav", /must_exist, title="Select a model data file")
    restore, mfile
    day   = 355
    monname = 'DEC'
    if strpos(mfile, '2008nov') ge 0 then begin
       day = 322
       monname = "NOV"
    endif
    ydn2md, 2008, day, month, day
    js0 = ymds2js(2008, month, day, 0)
    js  = js0 + 3600L*time_out
    mdldata = {sectime: js(0), temp: 0., zon: 0., mer: 0.}
    mdldata = replicate(mdldata, n_elements(time_out))
    mdldata(*).sectime = js
    mdldata(*).temp = tn_fpi(*, 2)
    mdldata(*).zon  = un_fpi(*, 2)
    mdldata(*).mer  = vn_fpi(*, 2)
end

pro getmsp, msp558
flis = findfile("C:\users\conde\main\Poker_SDI\Qian_Wu_December_08_Campaign\pkr_msp\msp*.pf")

mcchoice, 'Start File: ', flis, choice, $
           heading = {text: 'First day of MSP data to read?', font: 'Helvetica*Bold*Proof*30'}
jlo = choice.index
mcchoice, 'End File: ', flis, choice, $
           heading = {text: 'Last day of MSP data to read?', font: 'Helvetica*Bold*Proof*30'}
jhi = choice.index


for j= jlo,jhi do begin
   print, flis(j)
   ncid = ncdf_open (flis(j), /nowrite)
   ncdf_diminq, ncid, ncdf_dimid (ncid, 'Time'), dummy, ncmaxrec
   ncdf_attget, ncid, 'Start_Day_UT', ncdoy,     /GLOBAL
   comma  = strpos(ncdoy, ",")
   ncyear = strmid(ncdoy, comma+2, 4)
   ncdoy  = strmid(string(ncdoy), 4, comma-4)

;   peaki = uintarr(180, 6,ncmaxrec)
;   basei = uintarr(180, 6,ncmaxrec)

   ncdf_varget, ncid, ncdf_varid (ncid, 'FilterFactor'), filfac, offset=[0], count=[6]
   ncdf_varget, ncid, ncdf_varid (ncid, 'Time'), sectime, offset=[0],  count=[ncmaxrec]
   ncdf_varget, ncid, ncdf_varid (ncid, 'PeakIntensity'), peaki, offset=[0,0,0], count=[180, 6,ncmaxrec]
   ncdf_varget, ncid, ncdf_varid (ncid, 'BaseIntensity'), basei, offset=[0,0,0], count=[180, 6,ncmaxrec]
   ntc, peaki
   ntc, basei

   i558 = (peaki - basei)*filfac(0)/128.
   i558 = reform(i558(*,0,*))

   msp = {sectime: sectime(0), brite: i558(*,0)}
   msp = replicate(msp, ncmaxrec)
   for k=0,ncmaxrec-1 do begin
       ydn2md, ncyear, ncdoy, month, day
       js = ymds2js(ncyear, month, day, sectime(k))
       msp(k).sectime = js
       msp(k).brite = smooth(i558(*,k), 3)
   endfor
   if j eq jlo then msp558 = msp else msp558 = [msp558, msp]
   ncdf_close, ncid
   wait, 0.01
endfor
end

pro getsdi, mm, winds, spekfits, windpars
flis = findfile("C:\users\conde\main\Poker_SDI\Qian_Wu_December_08_Campaign\pkr_sdi\pkr*.nc")


mcchoice, 'Start File: ', flis, choice, $
           heading = {text: 'First day of SDI data to read?', font: 'Helvetica*Bold*Proof*30'}
jlo = choice.index
mcchoice, 'End File: ', flis, choice, $
           heading = {text: 'Last day of SDI data to read?', font: 'Helvetica*Bold*Proof*30'}
jhi = choice.index

for j=jlo,jhi do begin
    sdi3k_read_netcdf_data, flis(j), metadata=mm, winds=awind, spekfits=afit, windpars=awpar
    if j eq jlo then begin
       winds = awind
       spekfits = afit
       windpars = awpar
    endif else begin
       winds = [winds, awind]
       spekfits = [spekfits, afit]
       windpars = [windpars, awpar]
    endelse
    sdi3k_read_netcdf_data, flis(j), /close
endfor

end

;=========================================================
;  Main program starts here:

getsdi, mm, winds, spekfits, windpars
getmsp, msp558
getmdl, mdldata, monname

temperatures = median(spekfits.temperature, dimension=1)
sigtem = fltarr(n_elements(temperatures))
for j=0, n_elements(temperatures)-1 do begin
    sigtem(j) = stddev(spekfits(j).temperature)/sqrt(n_elements(spekfits(j).temperature))
endfor
chisq = median(spekfits.chi_squared, dimension=1)
goods = where(chisq gt 0.6 and chisq lt 1.4)
winds = winds(goods)
spekfits = spekfits(goods)
windpars = windpars(goods)
temperatures = temperatures(goods)
sigtem = sigtem(goods)


timlimz = [(min(winds.start_time) + min(winds.end_time))/2, (max(winds.start_time) + max(winds.end_time))/2]
deltime = timlimz(1) - timlimz(0)

load_pal, culz, prop=0.8

;wscales = [10, 15, 20, 30, 50,  80, 100, 120, 150, 200, 250, 300, 400, 500, 600, 800, 1000, 1200, 1500, 2000]
;mcchoice, 'Wind scale: ', string(wscales, format='(i4)'), choice, $
;           heading = {text: 'Scale factor for wind plot?', font: 'Helvetica*Bold*Proof*30'}
;wrange = 1.11*wscales(choice.index)
wrange = 222.
tscale = [477, 923]
mspscale = 8000.

;----Determine whether we're plotting magnetic or geographic wind components:
     mcchoice, 'Plot Coordinates: ', ['Magnetic', 'Geographic'], coords, $
                heading = {text: 'Magnetic or Geographic Wind Components?', font: 'Helvetica*Bold*Proof*30'}
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
    hwm_dll  = 'd:\users\conde\main\idl\hwm\nrlhwm93.dll'
    if not(file_test(hwm_dll)) then hwm_dll = 'c:\users\conde\main\idl\hwm\nrlhwm93.dll'
    nhwm     = 256
    hwm_vals = fltarr(2, 3, nhwm)
    tmx       = findgen(nhwm)*deltime/(nhwm-1) + timlimz(0)
    sec   = 0.
    lat   = float(mm.latitude)
    lon   = float(mm.longitude)
    if lon lt 0 then lon = lon+360.
    hwm   = {altitude: 240., F107: 100., ap: 15}
;    obj_edt, hwm, title='HWM Parameters'
    f107  = hwm.f107
    alt   = hwm.altitude
    f107a = f107
    ap    = fltarr(7)
    ap(0) = hwm.ap
    magrot= !dtor*(mm.oval_angle + mm.rotation_from_oval)
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
window, xsize=1800, ysize=1200
erase, color=culz.white

lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
posarr = spekfits.velocity
sdi3k_timesmooth_fits,  posarr, 1.5, mm
drftfit   = poly_fit((spekfits.start_time + spekfits.end_time)/2 - spekfits(0).start_time, posarr(0,*), 4, measure_errors=1.+spekfits.sigma_velocity(0), yfit=drift, /double)
vz      = mm.channels_to_velocity*(spekfits.velocity(0) - drift)
deg_tik,  timlimz, ttvals, nttix, minor, minimum=5
xtn     = dt_tm_mk(js2jd(0d)+1, ttvals, format='n$ 0d$')

crange = culz.imgmax - culz.imgmin

    !p.position = [0.14, 0.72, 0.88, 0.93]
    plot, timlimz, [0, 180], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          title=mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, timlimz(0), format='n$-Y$') + ', ' + lamlab, $
          yticks=4, ytickv=[30, 60, 90, 120, 150], ytickname=['150', '120', '90', '60', '30'], $
          ytitle='Scan Angle [Deg]'
    for k=0l,n_elements(msp558)-1 do begin
        plots, msp558(k).sectime, 180
        for l=0,179 do begin
            clr = culz.imgmin + crange*msp558(k).brite(l)/mspscale < culz.imgmax-4
            clr = clr > culz.imgmin+1
            plots, msp558(k).sectime, 180-l, /continue, color=clr
        endfor
    endfor
    plot, timlimz, [0, 180], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          title=mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, timlimz(0), format='n$-Y$') + ', ' + lamlab, $
          yticks=4, ytickv=[30, 60, 90, 120, 150], ytickname=['150', '120', '90', '60', '30'], $
          ytitle='Scan Angle [Deg]'

    !p.position = [0.14, 0.51, 0.88, 0.72]
    plot, timlimz, [-wrange, wrange], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
;          title=mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, timlimz(0), format='n$-Y$') + ', ' + lamlab, $
          ytitle=coords.name + ' Zonal!C!CWind [m s!U-1!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2
          mc_oploterr, (windpars.start_time + windpars.end_time)/2, zonal, sigzon, $
                        bar_color=culz.ash, thick=2, symbol_color=culz.slate, line_color=culz.white, /two, psym=6, symsize=.3
          oplot, mdldata.sectime, mdldata.zon, color=culz.black, thick=2

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
    empty

    !p.position = [0.14, 0.30, 0.88, 0.51]
    plot, timlimz, [-wrange, wrange], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle=coords.name + ' Meridional!C!CWind [m s!U-1!N]'
          axis, xaxis=0, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          oplot, timlimz, [0., 0.], color=culz.ash, linestyle=2
          mc_oploterr, (windpars.start_time + windpars.end_time)/2, merid, sigmer, $
                        bar_color=culz.ash, thick=2, symbol_color=culz.rose, line_color=culz.white, /two, psym=6, symsize=.3
          oplot, mdldata.sectime, mdldata.mer, color=culz.black, thick=2
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
    empty

    !p.position = [0.14, 0.09, 0.88, 0.30]

     plot, timlimz, tscale, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          ytitle='Temperature [K]'
          axis, xaxis=0, xtickname=xtn, color=culz.black, xtitle='UT Date', charsize=2., charthick=3, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          mc_oploterr, (spekfits.start_time + spekfits.end_time)/2, temperatures, sigtem, $
                        bar_color=culz.ash, thick=1, symbol_color=culz.black, line_color=culz.white, /two, psym=6, symsize=.3
          oplot, mdldata.sectime, mdldata.temp, color=culz.black, thick=2


    xyouts, 0.89, 0.65, 'Note: Error bars !Cdenote standard !Cdeviations !C(across all zones) !Cof zonal and !Cmeridional wind !Ccomponents at !Ceach observation !Ctime.', $
            color=culz.black, charsize=1.3, charthick=2, /normal

    barbox = [0.895, 0.75, 0.92, 0.92]
    mccolbar, barbox, culz.imgmin, culz.imgmax, 0., mspscale/1000., parname=' ', unit='  kR', /both, $
              color=culz.black, thick=2, charsize=1.8, format='(i5)'


    empty
!p.position = 0
gif_this, /png, file="C:\users\conde\main\Poker_SDI\Qian_Wu_December_08_Campaign\pkr_SDI_model_" + monname + ".png"
end
