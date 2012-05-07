
;========================================================================================

local_path = dialog_pickfile(path='D:\users\SDI3000\Data\', /dir)
;local_path = 'D:\users\SDI3000\Data\Poker\'
;local_path = 'D:\sdi_archive\2004\'
;local_path = 'D:\mawson\2007_Data\'
;local_path = 'D:\users\SDI3000\realtime_data'
;local_path = 'd:\users\sdi3000\data\haarp\'
filter     = ['*.nc', '*.pf', '*.las', '*_sky*.sky']
;filter     = ['*sodium*.nc', '*laser*.pf']
sdi3k_batch_ncquery, file_desc, path=local_path, filter=filter, /verbose

skylis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'SKY'))
calz   = where(strupcase(file_desc.metadata.viewtype) eq 'CAL', nncal)
if nncal gt 0 then begin
   callis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'CAL'))
   skylis = skylis(sort(skylis.name))
   callis = callis(sort(callis.name))
endif

mcchoice, 'File to process?', skylis.preferred_name, choice
fidx = choice.index
insinf   = mc_fileparse(skylis(fidx).metadata.path + strmid(skylis(fidx).insfile, 0, 4) + strmid(skylis(fidx).insfile, 9, 999))
insname  = insinf.name_only
insinf   = mc_fileparse(skylis(fidx).metadata.path + strmid(callis.insfile,    0, 4) + strmid(callis.insfile,    9, 999))
insz     = insinf.name_only
this_ins = where(insz eq insname, nn)
if nn gt 0 then this_ins = callis(this_ins(0)).name

local_path = insinf(this_ins).path
   flats    = findfile(local_path + "Wind_flat_field*.sav")
   mcchoice, 'Wind flat field?', [flats, 'None'], choice, help='This flat field correction will be applied regardless of wavelelength'
   if choice.name ne 'None' then flatfield = flats(choice.index) else flatfield = 'None'


sdi3k_read_netcdf_data,  skylis(fidx).name, $
                         metadata=mm, zone_centers=zone_centers, zonemap=zonemap, zone_edges=zone_edges, $
                         spex=spex, spekfits=spekfits, winds=winds

           if flatfield ne 'None' then begin
              restore, flatfield
              for j=0, n_elements(spekfits) -1 do spekfits(j).velocity = spekfits(j).velocity - wind_offset
           endif


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
    if abs(mm.wavelength_nm - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
    endif
    if abs(mm.wavelength_nm - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
    endif
    if abs(mm.wavelength_nm - 630.03) lt 5. then begin
       lamda = '6300'
       doing_red = 1
    endif

    flatcorr = 0
    wind_offset = fltarr(mm.nzones)
    if doing_green then begin
       flats    = findfile(local_path + "wind_flat*.sav")
       mcchoice, 'Wind flat field file?', [flats, 'None'], choice, help='The flat field correction will only be applied to 5577 winds'
       if choice.name ne 'None' then begin
          flatcorr = 1
          restore, choice.name
          print, 'Using vzero map: ', choice.name
       endif
    endif

    sdi3k_drift_correct, spekfits, mm, /force, /data_based ;########

    if doing_green and getenv('SDI_ZERO_VELOCITY_FILE') ne '' then begin
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif

    sdi3k_remove_radial_residual, mm, spekfits, parname='TEMPERATURE', /zero_mean
    sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY'
    spekfits.velocity = mm.channels_to_velocity*spekfits.velocity


    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, 1.2, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, 0.11, mm, zone_centers
    spekfits.temperature = tprarr

ipeak = fltarr(mm.nzones)
sdi3k_zenav_peakpos, spex, mm, cpos, widths=widths
sdi3k_load_insprofs, this_ins, insprofs, norm=inorm
phse_x  = cos(findgen(mm.scan_channels)*2.*!pi/mm.scan_channels)
phse_y  = sin(findgen(mm.scan_channels)*2.*!pi/mm.scan_channels)
for j=0,mm.nzones-1 do ipeak(j) = atan(total(phse_y*insprofs(j)), total(phse_x*insprofs(j)))*mm.scan_channels/(2*!pi)


wscales = [300, 400, 500, 600, 800, 1000, 1200, 1500]
mcchoice, 'Wind scale: ', string(wscales, format='(i4)'), choice, $
           heading = {text: 'Scale factor for wind arrows?', font: 'Helvetica*Bold*Proof*30'}
scale  = wscales(choice.index)
plot_options = {plot_images: 1, plot_temperature: 1, plot_LOS_winds: 0, plot_insprofs: 1, plot_wind_vectors:1, $
                image_scale: [0.04, 0.98], histogram_auto_scale: 1, image_smoothing: 12., temperature_range: [300,1000], wind_scale: scale} ;##########

medtemp = median(spekfits.temperature)
medtemp = 100*fix(medtemp/100)
tprscale = [medtemp - 200. > 0, medtemp + 200.]
if doing_red then tprscale = [medtemp - 300. > 0, medtemp + 300.]

;los_scale = [-150., 150.]
;los_scale = [-60., 60.] ;#######
los_scale = 0.5*[-plot_options.wind_scale, plot_options.wind_scale]

tpr  = spekfits.temperature
nt   = n_elements(tpr)
tord = sort(tpr)
tlo  = 50*fix(tpr(tord(0.03*nt))/50.) -50
thi  = 50*fix(tpr(tord(0.97*nt))/50.) + 50
tprscale = [tlo>0, thi<1500]

brt  = spekfits.intensity
nb   = n_elements(brt)
bord = sort(brt)
bhi  = brt(bord(0.97*nb))
brtscale = [0, bhi]

xpix    = mm.columns
ypix    = mm.rows
centime = (winds.start_time + winds.end_time)/2
; centime = winds.start_time + 1.3*3600. ;########### for comparison with cal

hhmm    = dt_tm_mk(js2jd(0d)+1, centime, format='h$:m$')

skewarr = fltarr(mm.maxrec, mm.nzones)
for rec=0,mm.maxrec-1 do begin
    for zidx=0,mm.nzones-1 do begin
        ospec = reform(spex(rec).spectra(zidx,*))
        ospec = shift(ospec, mm.scan_channels/2 - cpos - wind_offset(zidx)) - ipeak(zidx)
        mc_moment, findgen(mm.scan_channels), ospec, mu, sigma, skew
        skewarr(rec, zidx) = skew
    endfor
endfor
medskew = median(skewarr)
skewdev = stddev(skewarr)
print, 'Median skewness for all spectra is: ', medskew
print, 'Standard deviation of skewness for all spectra is: ', skewdev

load_pal, culz
while !d.window gt 0 do wdelete, !d.window
window, xsize=xpix, ysize=ypix, title="GI/UAF All-Sky Fabry-Perot Composite Display"

rec = 0
repeat begin
   scale = plot_options.wind_scale
   mcchoice, 'Exposure central time:', ['Prev', 'Next', hhmm, 'Options', 'Save', 'Done'], choice
   case choice.name of
        'Done':    goto, all_done
        'Prev':    rec = (rec - 1) > 0
        'Next':    rec = (rec + 1) < (mm.maxrec-1)
        'Save':    begin
                   js = centime(rec)
                   dt = dt_tm_mk(js2jd(0d)+1, js, format='_Y$n$0d$')
                   tm = dt_tm_mk(js2jd(0d)+1, js, format='_h$m$s$')
                   gif_this, /png, /ask, file='SPEX_' + mm.site_code + '_' + string(fix(10*mm.wavelength_nm), format='(i4.4)') + $
                             dt + tm + '.png', path=path
                   end
        'Options': obj_edt, plot_options
         else:     rec = choice.index - 2
   endcase
   sdi3k_read_netcdf_data, skylis(fidx).name, image=image, range=[rec, rec]
        image  = image(0)
        merid  = winds(rec).meridional_wind
        zon    = winds(rec).zonal_wind
;---Setup scaling and a mask for the useful area of the image:
        los_scale = 0.5*[-plot_options.wind_scale, plot_options.wind_scale]
        itest = size(image(0), /tname)
        if itest eq 'STRUCT' then begin
           rad = shift(dist(xpix, xpix), xpix/2, xpix/2)
           outerz = where(rad gt xpix/2-2)
           innerz = where(rad lt xpix/2-2)
           brites = median(image.scene, 5)
           brites = brites(innerz)
           brites = brites(sort(brites))

           srange = abs(image.scale(1) - image.scale(0))
           if abs(mm.rotation_from_oval) lt 2. then iimg = image.scene else  iimg = rot(image.scene, -mm.rotation_from_oval, cubic=-0.5)
           if plot_options.image_smoothing gt 0 then iimg = mc_im_sm(iimg, plot_options.image_smoothing)
           iimg   = rebin(iimg, mm.rows, mm.columns)
           imlo   = image.scale(0)-srange/10.
           imhi   = image.scale(1)+srange/10.
           print, imlo, imhi
           if plot_options.image_scale(0) ne 0. then imlo = plot_options.image_scale(0)
           if plot_options.image_scale(1) ne 0. then imhi = plot_options.image_scale(1)
           if plot_options.histogram_auto_scale then begin
              imlo = brites((n_elements(brites) - 1)*plot_options.image_scale(0))
              imhi = brites((n_elements(brites) - 1)*plot_options.image_scale(1))
           endif
           green  = bytscl(iimg, min=imlo, max=imhi, top=254)
           green(outerz)  = 0
        endif
        rgblimz = [[0, 9e39], [brtscale] , [0, 9e39]]
        if plot_options.plot_temperature then begin
           if norm(plot_options.temperature_range) gt 2. then tms = plot_options.temperature_range else tms = tprscale

           rgblimz = [[tms], [brtscale] , [0, 9e39]]
           indata  = [[spekfits(rec).temperature], [spekfits(rec).intensity], [spekfits(rec).temperature]]
           sdi3k_one_rgbmap, mm, xpix, indata, rgblimz, zonemap, red, mapg, blue, azimuth_rotation=0
        endif
        if plot_options.plot_los_winds then begin
           rgblimz = [[los_scale], [brtscale] , [0, 9e39]]
           indata  = [[spekfits(rec).velocity], [spekfits(rec).intensity], [spekfits(rec).temperature]]

;restore, 'F:\users\SDI3000\Data\Poker\Wind_flat_field_PKR_5577A_created_2010_06_19_by_discard.sav'   ;###3
 ;          indata  = [[wind_offset*metadata(0).channels_to_velocity], [spekfits(rec).intensity], [spekfits(rec).temperature]] ; ##########


           sdi3k_one_rgbmap, mm, xpix, indata, rgblimz, zonemap, red, mapg, blue, azimuth_rotation=0
        endif

        if itest ne 'STRUCT' then green = mapg

        if not(plot_options.plot_images)      then green = green*0.0001
        if not(plot_options.plot_temperature) then blue  = blue*0.5
        loadct,0
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
        load_pal, culz
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
;goto, skip_spex  ; ##############
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
        ospec = shift(ospec, mm.scan_channels/2 - cpos - wind_offset(zidx)) - ipeak(zidx)
        yr    = [min(ospec), max(ospec)]
        inscul= culz.orange
        if not(plot_options.plot_temperature) then inscul =  culz.purple
        if plot_options.plot_insprofs then $
           plot, insprofs(zidx, *), color=inscul, xstyle=5, ystyle=5, /noerase, $
                 yrange=[min(insprofs(zidx, *)), max(insprofs(zidx, *))], thick=1;, psym=1, symsize=0.25
        skycul=culz.white
        if abs(skewarr(rec,zidx) - medskew) gt (2*skewdev > 0.16) or spekfits(rec).chi_squared(zidx) gt 20 then skycul = culz.cyan
;        if spekfits(rec).chi_squared(zidx) gt 20 then skycul = culz.cyan
        plot, ospec, color=skycul, xstyle=5, ystyle=5, /noerase, $
              yrange=yr, thick=2;, psym=1, symsize=0.25
        axis, xaxis=0, xstyle=1, color=culz.white, xticklen=.07, $
              xtickv = [0,31,63,95,127], xticks = 4, $
              xtickname = [' ',' ',' ',' ',' ']
        oplot, [xz, xz], [min(ospec), max(ospec)], color=culz.white
       !p.position =  0
    endfor
skip_spex:  ;##############

;-------Add the annotation in each of the four corners:
       js = centime(rec)
       sname = 'Poker Flat!CAlaska'
       exptime = strcompress(string((spex(rec).end_time - spex(rec).start_time)/60., format='(f9.1)'), /remove_all)
       if strpos(strupcase(mm.site), 'MAWSON') ge 0 then sname = 'Mawson!CAntarctica'
       if strpos(strupcase(mm.site), 'HAARP')  ge 0 then sname = 'HAARP!CGakona, Alaska'
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

;------Add the temperature color scale bar if needed:
    if plot_options.plot_temperature then begin
        unitz   = 'K'
        rgb_vex = {red: bytarr(255), green: bytarr(255), blue: bytarr(255)}
        rgb_vex.red   = 0.7*bindgen(255)
        rgb_vex.blue  = 0.7*(255 - bindgen(255))
        rgb_vex.green = bytarr(255)

        xlo = 0.04
        xhi = 0.20
        ylo = 0.06
        yhi = 0.08
        mccolbar, [xlo, ylo, xhi, yhi], 0, 255, tms(0), tms(1), $
                      parname=' ', units=unitz, $
                      color=culz.white, thick=3, charsize=2.5, format='(i6)', $
                     /horizontal, /both_units, rgb_vector=rgb_vex, reserved_colors=20
    endif

       empty
all_done:
    wait, 0.001
endrep until choice.name eq 'Done'

sdi3k_read_netcdf_data, skylis(fidx).name, /close
end
