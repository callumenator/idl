pro time_clip, indata, timewin
    js2ymds, indata.start_time, y, m, d, s
    s = s + 86400.*(d - min(d))
    keepers = where(s ge 3600.*min(timewin) and s le 3600.*max(timewin), nn)
    if nn gt 0 then indata = indata(keepers)
end

;=====================================================================================

; data_path = 'C:\users\conde\main\Poker_SDI\Publications_and_Presentations\CEDAR_2009\Crowley_neutral_winds'
data_path = 'D:\users\SDI3000\Data\Poker\'
ncfile = dialog_pickfile(path=data_path, get_path=data_path, /read, /must_exist)


sdi3k_read_netcdf_data, ncfile, metadata=mm, winds=winds, spekfits=spekfits, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges
timelis = dt_tm_mk(js2jd(0d)+1, (winds.start_time + winds.end_time)/2, format='h$:m$:s$')
mcchoice, 'Start Time: ', timelis, choice, $
           heading = {text: 'Start Plotting at What Time?', font: 'Helvetica*Bold*Proof*30'}
jlo = choice.index
mcchoice, 'End Time: ', timelis, choice, $
           heading = {text: 'End Plotting at What Time?', font: 'Helvetica*Bold*Proof*30'}
jhi = choice.index

scale = 0.


;scale = 2*(culz.greymax - culz.greymin -1)/float(scale)
;mcchoice, 'Image Scaling: ', ['Auto Scale', 'Manual Scale'], choice, $
;           heading = {text: 'Auto or Manual Scaling?', font: 'Helvetica*Bold*Proof*30'}, $
;           help='Auto scale factor is: ' + strcompress(string(scale, format='(f12.4)'), /remove_all) + '  Manual scale is: ' + strcompress(string(sdi_img_gain, format='(f12.4)'), /remove_all)
;if choice.index eq 0 then sdi_img_gain = scale

wscales = [100, 200, 300, 400,  500, 600, 700, 800, 1000, 1200, 1500]
mcchoice, 'Wind scale: ', string(wscales, format='(i4)'), choice, $
           heading = {text: 'Scale factor for wind arrows?', font: 'Helvetica*Bold*Proof*30'}
wind_vecscale = wscales(choice.index)

    sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY'
    sdi3k_remove_radial_residual, mm, spekfits, parname='TEMPERATURE', /zero_mean
    sdi3k_remove_radial_residual, mm, spekfits, parname='INTENSITY',   /multiplicative

    tsm = 0.10
    ssm = 0.08
    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, tsm, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, ssm, mm, zone_centers
    spekfits.temperature = tprarr


;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')
    timewin = [-24., 48.]

;---Setup the wind mapping:
    load_pal, culz, prop=0.5, idl=[3,0]
    britearr   = reform(spekfits.intensity)
    intord     = sort(britearr)
    britescale = [0., 1.2*britearr(intord(0.97*n_elements(intord)))]
    medtemp = 100*fix(median(spekfits.temperature)/100)
    tprscale = [medtemp - 200. > 0, medtemp + 200.]
    scale = {yrange: wind_vecscale, auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}

    nmaps    = jhi - jlo
    cads = indgen(10 < (nmaps)/4) + 1
    mcchoice, 'Cadence: ', string(cads, format='(i2)'), choice, $
               heading = {text: 'Cadence for Wind Plotting?', font: 'Helvetica*Bold*Proof*30'}
    cadence  = choice.index + 1
    thumsize = 300
    xsize    = 1500
    ysize    = 2*thumsize + (thumsize*nmaps/(1 + xsize/thumsize))/cadence
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    geo   = {xsize:  xsize, ysize: ysize}
    pp  = 'Map'
    oo  = 'Magnetic Noon at Top'
    oo  = 'Dummy'
    windmap_settings = {scale: scale, perspective: pp, orientation: oo, black_bgnd: 1, geometry: geo, records: [jlo,jhi]}
    sdi3k_read_netcdf_data, ncfile, metadata=mm_dummy, images=images, cadence=cadence
    if n_elements(images) gt 2 then time_clip, images, timewin
    sdi3k_wind_mapper, tlist, tcen, mm, winds, windmap_settings, culz, spekfits, zonemap, images=images, cadence=cadence
;    sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Vector_Maps', plot_folder=plot_folder
end
