function sdi_interp, valbefore, valafter, timebefore, timeafter, when
         return, valbefore + (valafter - valbefore)*(when - timebefore)/(timeafter - timebefore)
end

pro overplot_wind_vectors, zon, mer, zone_centers, scale, mm, culz
    pix = min([mm.rows, mm.columns])
    zx  = zone_centers(*,0)*mm.columns
    zy  = zone_centers(*,1)*mm.rows
        x0 = zx - 0.25*pix*zon/scale
        x1 = zx + 0.25*pix*zon/scale
        y0 = zy + 0.25*pix*mer/scale
        y1 = zy - 0.25*pix*mer/scale
        arrow, x0, y0,x1, y1, color=culz.green, thick=2, hthick=2
end

fills         = 10
sdi_img_gain  = 0.012
wind_vecscale = 900
data_path = 'c:\users\sdi3000\data\spectra\'
if getenv('computername') eq 'VERTEX'   then data_path = 'd:\'
if getenv('computername') eq 'FLYWHEEL' then data_path = 'D:\users\SDI3000\Data\Spectra\'
ncfile = dialog_pickfile(path=data_path, get_path=data_path, /read, /must_exist)

sdi3k_read_netcdf_data, ncfile, metadata=mm, winds=winds, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges
timelis = dt_tm_mk(js2jd(0d)+1, (winds.start_time + winds.end_time)/2, format='h$:m$:s$')
mcchoice, 'Start Time: ', timelis, choice, $
           heading = {text: 'Start Movie at What Time?', font: 'Helvetica*Bold*Proof*30'}
jlo = choice.index
mcchoice, 'End Time: ', timelis, choice, $
           heading = {text: 'End Movie at What Time?', font: 'Helvetica*Bold*Proof*30'}
jhi = choice.index

scale = 0.
for j=jlo,jhi, 3 do begin
    sdi3k_read_netcdf_data, ncfile, winds=winds, images=images, range=[j,j]
    iimg  = smooth(images(0).scene, 50)
    range = max(iimg) - min(iimg)
    if range gt scale then scale = range
endfor

load_pal, culz, prop=0.5, idl=[3,0]

scale = 2*(culz.greymax - culz.greymin -1)/float(scale)
mcchoice, 'Image Scaling: ', ['Auto Scale', 'Manual Scale'], choice, $
           heading = {text: 'Auto or Manual Scaling?', font: 'Helvetica*Bold*Proof*30'}, $
           help='Auto scale factor is: ' + strcompress(string(scale, format='(f12.4)'), /remove_all) + '  Manual scale is: ' + strcompress(string(sdi_img_gain, format='(f12.4)'), /remove_all)
if choice.index eq 0 then sdi_img_gain = scale

wscales = [300, 400,  500, 600, 700, 800, 1000, 1200, 1500]
mcchoice, 'Wind scale: ', string(wscales, format='(i4)'), choice, $
           heading = {text: 'Scale factor for wind arrows?', font: 'Helvetica*Bold*Proof*30'}
wind_vecscale = wscales(choice.index)



mcchoice, 'Fills: ', string(indgen(20)+1, format='(i2)'), choice, $
           heading = {text: 'How many fill frames?', font: 'Helvetica*Bold*Proof*30'}
fills = choice.index


while !d.window gt 0 do wdelete, !d.window
window, xsize=mm.columns, ysize=mm.rows
progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Movie...')
progressBar->Start


for j=jlo,jhi < n_elements(timelis) -2 do begin
    sdi3k_read_netcdf_data, ncfile, winds=winds, images=images, range=[j,j+1]
    iimg0  = sdi_img_gain*(images(0).scene - min(smooth(images(0).scene, 15))) < (culz.imgmax - culz.imgmin -1)
    iimg1  = sdi_img_gain*(images(1).scene - min(smooth(images(1).scene, 15))) < (culz.imgmax - culz.imgmin -1)

    for ff=0,fills-1 do begin
        ct0  = (images(0).start_time + images(0).end_time)/2
        ct1  = (images(1).start_time + images(1).end_time)/2
        iimg = sdi_interp(iimg0,                    iimg1,                    ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        zon  = sdi_interp(winds(0).zonal_wind,      winds(1).zonal_wind,      ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        mer  = sdi_interp(winds(0).meridional_wind, winds(1).meridional_wind, ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        scene = culz.imgmin + iimg
        scene(zone_edges) = culz.yellow
        tv, scene
        overplot_wind_vectors, zon, mer, zone_centers, wind_vecscale, mm, culz
        js = (winds(0).start_time + winds(0).end_time)/2
		xyouts, /normal, .04, .93,  dt_tm_mk(js2jd(0d)+1, js, format='Y$-0n$-0d$'), color=culz.white, charsize=1.2
		xyouts, /normal, .96, .93,  dt_tm_mk(js2jd(0d)+1, js, format='h$:m$:s$'),   color=culz.white, charsize=1.8, align=1
		xyouts, /normal, .04, .03, 'Poker Flat, Alaksa',                            color=culz.white, charsize=1.2
		xyouts, /normal, .96, .03, 'Conde/Hampton',                                 color=culz.white, charsize=1.2, align=1
		xyouts, /normal, .50, .96, '!5S!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .50, .01, '!5N!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .02, .50, '!5W!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .98, .50, '!5E!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		empty
        wait, 0.004
    endfor
    progressbar->update, 100.*(j - jlo)/float(jhi - jlo)
endfor
progressBar->Destroy
Obj_Destroy, progressBar
sdi3k_read_netcdf_data, ncfile, /close
end
