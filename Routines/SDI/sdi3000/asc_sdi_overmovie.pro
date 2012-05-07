function sdi_interp, valbefore, valafter, timebefore, timeafter, when
         return, valbefore + (valafter - valbefore)*(when - timebefore)/(timeafter - timebefore)
end

function overead_asc, fname, js=js, max=asc_fsd
    asc = readfits(fname, hdr)
    asc = asc - min(asc)
    asc = bytscl(asc, max=asc_fsd)
    asc = rotate(asc, 2)
    tt  = str_sep(hdr(40), "'")
    tt  = tt(1)
    yr  = fix(strmid(tt, 0, 4))
    mm  = fix(strmid(tt, 5, 2))
    dd  = fix(strmid(tt, 8, 2))
    ss  = 3600L*strmid(tt, 11, 2) + 60L*strmid(tt, 14, 2) + strmid(tt, 17, 2)
    js = ymds2js(yr, mm, dd, ss)
    return, asc
end

pro rename_stills
    flis = findfile('C:\idl_mpegs\stills\*.png')
    for j=0,n_elements(flis)-1 do file_move, flis(j), 'C:\idl_mpegs\stills\frame_' + string(j, format='(i4.4)') + '.png'
end

;========================================================================================
ascmag  = 1.35
asc_step = 1
;xcen    = 0.47  ; for doy 087
;ycen    = 0.57  ; for doy 087
xcen    = 0.50
ycen    = 0.48
scale   = 1000.
asc_fsd = 800 ; Use 800 for DOY 061, 2008. 1500 is good for DOY 041, 2008
sdi_img_gain = 0.002 ;Use 0.04 for DOY 061, 2008. 15 is good for DOY 041, 2008
emission_height = 240. ; km

;ncfile  = 'D:\users\SDI3000\Data\Spectra\PKR 2008_087_Poker_558nm_Green_Sky_Date_03_27.nc'
ncfile  = 'D:\users\SDI3000\Data\Spectra\spectra_2008_fall\PKR 2008_088_Poker_630nm_Red_Sky_Date_03_28.nc'
fitsdir = 'D:\Poker_ASC_data\20100203\'
ncfile  = dialog_pickfile(path='D:\users\SDI3000\Data\poker', filter='*.nc')
fitsdir = dialog_pickfile(path='D:\Poker_ASC_data', /dir)

sdi3k_read_netcdf_data,  ncfile, $
                         metadata=meta, zone_centers=zone_centers, zone_edges=zone_edges, zonemap=zonemap, $
                         winds=winds
sdiclip = where(zonemap lt 0)
zedge  = intarr(meta.columns, meta.rows)
zedge(zone_edges) = 150
asclis = findfile(fitsdir + '*.fits')
asclis = asclis(sort(asclis))

timelis = strmid(asclis, strlen(asclis(0)) - 15, 2) + '-' + strmid(asclis, strlen(asclis(0)) - 13, 2) + '-' + strmid(asclis, strlen(asclis(0)) - 11, 2)
mcchoice, 'Start Time: ', timelis, choice, $
           heading = {text: 'Start Movie at What Time?', font: 'Helvetica*Bold*Proof*30'}
jlo = choice.index
mcchoice, 'End Time: ', timelis, choice, $
           heading = {text: 'End Movie at What Time?', font: 'Helvetica*Bold*Proof*30'}
jhi = choice.index


wscales = [100, 200, 300, 400, 500, 600, 800, 1000, 1200, 1500]
mcchoice, 'Wind scale: ', string(wscales, format='(i4)'), choice, $
           heading = {text: 'Scale factor for wind arrows?', font: 'Helvetica*Bold*Proof*30'}
scale  = wscales(choice.index)

pfisplot = 0
pfisfiles = dialog_pickfile(path='D:\users\conde\main\Poker_SDI\Publications_and_Presentations\pfisr_2010_workshop\', $
                            filter='*.txt', title='Add PFISR files?', /multi)
if pfisfiles(0) ne '' then begin
   read_pfisr_convection, pfisfiles, pfiscon
   pfisbeams = uniq_elz(pfiscon.beam)
   pfisbeams = pfisbeams(sort(pfisbeams))
   pfisplot  = 1
endif


mcchoice, 'Fills: ', string(indgen(20), format='(i2)'), choice, $
           heading = {text: 'How many fill frames?', font: 'Helvetica*Bold*Proof*30'}
fills = choice.index + 1

mcchoice, 'Output: ', ['None', 'Movie Only', 'Stills Only', 'Both Movie and Stills'], choice, $
           heading = {text: 'Output Type?', font: 'Helvetica*Bold*Proof*30'}
outz = choice.index


fname = 'sdi_asc_DOY' + dt_tm_mk(js2jd(0d)+1, meta.start_time, format='doy$_Y$_(n$_0d$)') + '.mpg'

sdixpix = meta.columns
sdiypix = meta.rows
xpix    = 2*fix(sdixpix*ascmag/2)
ypix    = 2*fix(sdiypix*ascmag/2)
centime = (winds.start_time + winds.end_time)/2

if outz eq 2 then begin
   mcchoice, 'Step: ', string(indgen(20)+1, format='(i2)'), choice, $
              heading = {text: 'ASC frame step size?', font: 'Helvetica*Bold*Proof*30'}
   asc_step = 1 + choice.index
endif

mcchoice, 'Dial Plot: ', ["No, don't add a dial plot", "Yes, do add a dial plot"], choice, $
           heading = {text: 'Add a Dial Plot Panel?', font: 'Helvetica*Bold*Proof*30'}

plotdial = choice.index
if plotdial then begin
   sdi3k_simple_cirplot, ncfile, dialplot
   dialplot(*, 375:*, 600:*) = 0
endif


while !d.window gt 0 do wdelete, !d.window
if plotdial then begin
   xadd = n_elements(dialplot(0,*,0)) + 50
   window, xsize=xpix + xadd, ysize=ypix
endif else begin
   xadd = 0
   window, xsize=xpix, ysize=ypix
endelse
xshrink = float(xpix)/float(xpix + xadd)

;ompg  = mpeg_open([xpix, ypix], iframe_gap=1, FILENAME='c:\idl_mpegs\' + fname, quality=99)
if outz eq 1 or outz eq 3 then ompg  = mpeg_open([xpix + xadd, ypix*1.08], FILENAME='c:\idl_mpegs\' + fname, quality=95, bitrate=20000000L)

load_pal, culz
bsave = -2

vframe = 0L
for j=jlo,(jhi < (n_elements(asclis)-2)), asc_step do begin
    if n_elements(aschi) eq 0 then asclo = overead_asc(asclis(j),   js=jslo, max=asc_fsd) else begin
       asclo = aschi
       jslo  = jshi
    endelse
    aschi = overead_asc(asclis(j+1), js=jshi, max=asc_fsd)
    fill_here = fills
;    if jshi - jslo gt 1+10*asc_step then stop
    if jshi - jslo gt 1+10*asc_step then fill_here = fills*(jshi - jslo)/(10*asc_step) > 1

    for k=0,fill_here-1 do begin
        js     = jslo + k*(jshi - jslo)/fill_here
        if fill_here eq 1 then asc = asclo else asc    = sdi_interp(float(asclo), float(aschi), jslo, jshi, js)
        after  = where(centime gt js)
        after  = after(0)
        before = after - 1
        if before lt 0 then goto, skipper
        if before ne bsave then sdi3k_read_netcdf_data,  ncfile, image=imgsdi, range=[before, after]
        bsave  = before
        merid  = sdi_interp(winds(before).meridional_wind, winds(after).meridional_wind, centime(before), centime(after), js)
        zon    = sdi_interp(winds(before).zonal_wind,      winds(after).zonal_wind,      centime(before), centime(after), js)
        iimg   = sdi_interp(imgsdi(0).scene,               imgsdi(1).scene,              centime(before), centime(after), js)
        iimg   = sdi_img_gain*(iimg - min(smooth(iimg, 15))) < 255
        iimg(sdiclip) = 0.

        green  = congrid(asc, xpix, ypix, /interp)
        red    = green*0.
        blue   = green*0.

        sdibase = [xcen*xpix - sdixpix/2, ycen*ypix - sdixpix/2]
        red(sdibase(0):sdibase(0)+sdixpix-1, sdibase(1):sdibase(1)+sdixpix-1)  = iimg
        blue(sdibase(0):sdibase(0)+sdixpix-1, sdibase(1):sdibase(1)+sdixpix-1) = zedge

        erase
        tv, [[[red]], [[green]], [[blue]]], 0, 0, true=3
        if plotdial then begin
           tv, dialplot, 691 + 50, 0, /true
           maghrang = !dtor*15.*(float(dt_tm_mk(js2jd(0d)+1, js, format='sam$')) - meta.magnetic_midnight*3600.)/3600.
           rxc = xpix + xadd - n_elements(dialplot(0,*,0))/2
           ryc = n_elements(dialplot(0,*,0))/2
           x0  = rxc + 80.*sin(maghrang)
           y0  = ryc - 80.*cos(maghrang)
           x1  = rxc + 180.*sin(maghrang)
           y1  = ryc - 180.*cos(maghrang)
           arrow, x0, y0,x1, y1, color=culz.green, thick=8, hthick=8, hsize=20
        endif

;-------Draw the wind vectors:
        pix = min([meta.rows, meta.columns])
        zx  = zone_centers(*,0)*meta.columns + sdibase(0)
        zy  = zone_centers(*,1)*meta.rows    + sdibase(1)
        x0 = zx - 0.25*pix*zon/scale
        x1 = zx + 0.25*pix*zon/scale
        y0 = zy + 0.25*pix*merid/scale
        y1 = zy - 0.25*pix*merid/scale
        arrow, x0, y0,x1, y1, color=culz.yellow, thick=2, hthick=2, hsize=10

;-------Draw the PFISR convection, if available:
        if pfisplot then begin
           for bidx=0,n_elements(pfisbeams)-1 do begin
              thisbeam = where(pfiscon.beam eq pfisbeams(bidx))
              thisbeam = pfiscon(thisbeam)
              after = where((thisbeam.start_time + thisbeam.end_time)/2 gt js, nn)
              after = after(0)
              if after gt 1 and nn gt 0 then begin
                 before = after - 1
                 merid  = sdi_interp(thisbeam(before).meridional_velocity, thisbeam(after).meridional_velocity, $
                                    (thisbeam(before).start_time + thisbeam(before).end_time)/2, $
                                    (thisbeam(after).start_time  + thisbeam(after).end_time)/2,  js)
                 zon    = sdi_interp(thisbeam(before).zonal_velocity, thisbeam(after).zonal_velocity, $
                                    (thisbeam(before).start_time + thisbeam(before).end_time)/2, $
                                    (thisbeam(after).start_time  + thisbeam(after).end_time)/2,  js)
                 zx     = xpix/2
                 delykm = ((thisbeam(before).lo_lat + thisbeam(before).hi_lat)/2. - 65.1192)*111.12
                 zenang = atan(delykm/emission_height)/!dtor
                 zy     = ypix/2 - zenang*0.93*ypix/(2.*90.)
                 print, pfisbeams(bidx), (thisbeam(before).lo_lat + thisbeam(before).hi_lat)/2., delykm, zenang, zy, ypix
                 x0 = zx
                 x1 = zx + 0.5*pix*zon/(4*scale)
                 y0 = zy
                 y1 = zy - 0.5*pix*merid/(4*scale)
                 arrow, x0, y0,x1, y1, color=culz.cyan, thick=5, hthick=5, hsize=20
              endif
           endfor
        endif

;-------Add the annotation in eah of the four corners:
        attribution = 'Conde/Hampton'
        if pfisplot then attribution = 'Conde/Hampton/Nicolls'
		xyouts, /normal, .04*xshrink, .93,  dt_tm_mk(js2jd(0d)+1, js, format='Y$-0n$-0d$'), color=culz.white, charsize=1.8
		xyouts, /normal, .96*xshrink, .93,  dt_tm_mk(js2jd(0d)+1, js, format='h$:m$:s$'),   color=culz.white, charsize=1.8, align=1
		xyouts, /normal, .04*xshrink, .03, 'Poker Flat, Alaska',                            color=culz.white, charsize=1.8
		xyouts, /normal, .96*xshrink, .03,  attribution,                                    color=culz.white, charsize=1.4,   align=1
		xyouts, /normal, .50*xshrink, .96, '!5S!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .50*xshrink, .01, '!5N!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .02*xshrink, .50, '!5W!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		xyouts, /normal, .98*xshrink, .50, '!5E!3', charsize = 1.8, charthick = 2, color=culz.white, align=0.5
		if plotdial then begin
		   xyouts, /normal, .80, .96, 'Yellow Arrows: ',             color=culz.yellow, charsize=1.4, align=1
		   xyouts, /normal, .80, .96, 'FPS Neutral Winds',           color=culz.yellow, charsize=1.4, align=0
		   xyouts, /normal, .80, .93, 'Cyan Arrows: ',               color=culz.cyan,   charsize=1.4, align=1
		   xyouts, /normal, .80, .93, 'PFISR Convection Velocities', color=culz.cyan,   charsize=1.4, align=0
		   xyouts, /normal, .80, .90, 'Note: ',                      color=culz.white,  charsize=1.4, align=1
		   xyouts, /normal, .80, .90, 'FPS & PFISR scales differ',   color=culz.white,  charsize=1.4, align=0
		endif

;-------Add the wind velocity scale marker:
        windcolor = culz.white
        if pfisplot then windcolor = culz.yellow
        x0 = xpix - 30 - 0.125*pix
        x1 = xpix - 30
        y0 = 80
        y1 = y0
        arrow, x0, y0,x1, y1, color=windcolor, thick=2, hthick=2, hsize=20
		xyouts, /normal, .96*xshrink, .08,  strcompress(string(scale/4., format='(i4)'), /remove_all) + ' m/s', color=windcolor, charsize=1.4, align=1

;-------Add the convection velocity scale marker:
        if pfisplot then begin
           x1 = 30 + 0.125*pix
           x0 = 30
           y0 = 80
           y1 = y0
           arrow, x0, y0,x1, y1, color=culz.cyan, thick=2, hthick=2, hsize=20
	   	   xyouts, /normal, .03*xshrink, .08,  strcompress(string(scale, format='(i4)'), /remove_all) + ' m/s', color=culz.cyan, charsize=1.4, align=0
		endif

		empty
;		iimg = congrid(tvrd( /true), 3, 480,480)
		iimg = tvrd( /true)
		if outz eq 1 or outz eq 3 then mpeg_put, ompg, image=iimg, frame = vframe, /order
        vframe = vframe + 1
    endfor
    frame_name = 'sdi_asc_DOY' + dt_tm_mk(js2jd(0d)+1, js, format='doy$_Y$_(n$_0d$)_at_h$-m$-s$UT') + '.png'
    if outz eq 2 or outz eq 3 then gif_this, file='c:\idl_mpegs\stills\' + frame_name, /png
skipper:
    wait, 0.001
endfor

sdi3k_read_netcdf_data, ncfile, /close
if outz eq 1 or outz eq 3 then mpeg_save,  ompg, FILENAME='c:\idl_mpegs\' + fname
if outz eq 1 or outz eq 3 then mpeg_close, ompg
end
