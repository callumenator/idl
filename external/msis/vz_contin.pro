pro vz_wotnext, pdev, wot, help=help
    common tri_png_fspec, fpath
    if n_elements(fpath) eq 0 then fpath = 'd:\users\conde\main\hex\hex-2a\'
    wot = 'Continue'
    if pdev ne 'PS' then begin
           mcchoice, 'Choose an action: ', ['Continue', 'Save .png file', 'Exit'], choice, $
       	       heading = {text: 'Keep Plotting?', font: 'Helvetica*Bold*Proof*30'}, $
       	       help=help
       	   wot = choice.name
           if choice.name eq 'Save .png file' then begin

              fname = dialog_pickfile(filter='*.png', path=fpath, get_path=fpath)
              if fname ne '' then begin
                 img = tvrd(/true)
		 write_png, fname, img
              endif
           endif
    endif
end


a  = 155.
b  = 18.
hu = 12.
v0 = -16.
q0 = 1e-6

zlo   = 80.
zhi   = 200.
nz    = 1000

result= 0L
boltz = 1.380658e-23
amu   = 1.6726231e-27
sig1 = 4e-10
sig2 = 3.65e-10
sigo = sqrt(5e-19)

yyddd = 98010L
sec = 0.
lat = 65.
lon = -150.
f107a = 120.
f107 = 120.
ap = fltarr(7)
mass = 48L
t = fltarr(2)
d = fltarr(8)

lst = sec/3600. + lon/15.

mc_input, v0, title='Model Parameter Input', prompt='Vz peak value: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 240., min:60., value: a, ysize:100}, $
       heading = {text: 'Max Vertical Wind', font: 'Helvetica*Bold*Proof*30'}


mc_input, a, title='Model Parameter Input', prompt='Vz layer height km: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 240., min:60., value: a, ysize:100}, $
       heading = {text: 'Layer Height', font: 'Helvetica*Bold*Proof*30'}

apz = 15

mc_input, b, title='Model Parameter Input', prompt='Vz lower layer thickness km: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 100., min:0., value: b, ysize:100}, $
       heading = {text: 'Layer Lower Thickness', font: 'Helvetica*Bold*Proof*30'}

mc_input, hu, title='Model Parameter Input', prompt='Vz upper layer thickness km: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 100., min:0., value: hu, ysize:100}, $
       heading = {text: 'Layer Upper Thickness', font: 'Helvetica*Bold*Proof*30'}
ap(0) = apz

head = 'MSIS-90 Model for F10.7=' + strcompress(string(f107, format='(i8)'), /remove_all) + ', Ap=' + strcompress(string(apz, format='(i8)'), /remove_all)

print, hu, b
denarr = fltarr(nz)
altarr = fltarr(nz)
temarr = fltarr(nz)
mmmarr = fltarr(nz)
o2n2   = fltarr(nz)
vzarr  = fltarr(nz)
qarr   = fltarr(nz)
dpdz   = fltarr(nz)
dvdz   = fltarr(nz)
oden   = fltarr(nz)
n2den  = fltarr(nz)

; Calculate the MSIS neutral densities:
inc = (zhi - zlo)/nz
zz         = zlo + inc*findgen(nz)
for j=0,nz-1 do begin
    altarr(j) = zlo + j*inc
    alt = altarr(j)
    result = call_external('d:\users\conde\main\idl\msis\idlmsis.dll','msis90', $
                        yyddd,sec,alt,lat,lon,lst,f107a,f107,ap,mass,d,t)
    mmm = (d(0)*4. + d(1)*16. + d(2)*28. + d(3)*32.)/(d(0) + d(1) + d(2) + d(3))
    mmmarr(j) = mmm
    denarr(j) = total(d(0:4))
    o2n2(j)   = d(1)/d(2)
    oden(j)   = d(1)
    n2den(j)  = d(2)
    temarr(j) = t(1)
    gl        = exp(-((altarr(j) - a)/b)^2)
    gu        = exp(-((altarr(j) - a)/hu)^2)
    hh = [1. + abs(altarr(j) - a), gu^2]
    hq = b
    if altarr(j) ge a then begin
       hh = [gl^2, 1. + abs(altarr(j) - a)]
       hq = hu
    endif
    vzarr(j)  = v0*(hh(0)*(gl) + hh(1)*(gu))/total(hh)
    qarr(j)   = q0*exp(-((altarr(j) - a)/hq)^2)
endfor

;vzarr = v0*chaplayr(zz, a, hu, b)


;-------Fit HEX vertical winds:
;hvz   = [-1.51291, -2.35240, -7.50879, -7.62721, -15.4903, -1.46310, -6.91714, 1.97432]
;hzz   = [129.753,   136.387,  144.313,  151.167,  158.246,  164.682,  171.034, 177.404]

;chunk = where(altarr ge min(hzz) and altarr le max(hzz))
;hiz   = interpol(hvz, hzz, altarr(chunk))
;cfs   = poly_fit(altarr(chunk), hiz, 8, yfit=vzfit)

;vzarr = fltarr(nz)
;vzarr(chunk) = vzfit

denarr     = median(denarr, 5)

dpdz       = (shift(denarr, 1) - denarr)/inc
dpdz(0)    = dpdz(1)
dpdz(nz-1) = dpdz(nz-2)
dpdz       = median(dpdz, 5)

dvdz       = (shift(vzarr, 1) - vzarr)/inc
dvdz(0)    = dvdz(1)
dvdz(nz-1) = dvdz(nz-2)
dvdz       = median(dvdz, 5)

s          = -vzarr*dpdz/denarr - dvdz
s = median(s, 5)

;------------------ Fire up a window:
load_pal, culz
window, xsize=1000, ysize=800



erase, color=culz.white

!p.position = [0.1, 0.20, 0.48, 0.98]
xx = vzarr
plot, xx, zz, ytitle='Height [km]', xtitle='Vertical Wind [m/s]', /noerase, $
      xthick=3, ythick=3, thick=4, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = [min(xx), max(xx)] + [-.1*(max(xx)-min(xx)), .1*(max(xx)-min(xx))], /xstyle

plot, denarr, zz, ytitle='Height [km]', xtitle=' ', /noerase, $
      xthick=3, ythick=3, thick=2, charsize=1.5, color=culz.blue, charthick=3, /ystyle, $
      yrange=[zlo,zhi], xticks=2, xticklen=0.001, xtickname=replicate(' ', 3), /xlog, /xstyle
      pp = convert_coord(min(denarr), 35., /data, /to_normal)

axis, pp(0), 0.1, xaxis=0, /xlog, color=culz.blue, xthick=3, ythick=3, charsize=1.5, charthick=3, $
      ymargin=[10,3], xtitle='Number Density [cm!U-3!N]', /normal

xx = vzarr
plot, xx, zz, ytitle='Height [km]', xtitle='Vertical Wind [m/s]', /noerase, $
      xthick=3, ythick=3, thick=4, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = [min(xx), max(xx)] + [-.1*(max(xx)-min(xx)), .1*(max(xx)-min(xx))], /xstyle

!p.position = [0.6, 0.20, 0.98, 0.98]

rr = [min([s, -dvdz, -vzarr*dpdz/denarr]), max([s, -dvdz, -vzarr*dpdz/denarr])]
rl = rr(1) - rr(0)
xx = s
plot, xx, zz, ytitle='Height [km]', xtitle='1000 x Source function [s!U-1!N]', /noerase, $
      xthick=3, ythick=3, thick=3, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = rr + [-.1*rl, .1*rl], /xstyle

xx = -dvdz
plot, xx, zz, ytitle='Height [km]', xtitle=' ', /noerase, $
      xthick=3, ythick=3, thick=2, charsize=1.5, color=culz.red, charthick=3, /ystyle, $
      yrange=[zlo,zhi], xticks=2, xticklen=0.001, xtickname=replicate(' ', 3), $
      xrange = rr + [-.1*rl, .1*rl], /xstyle

xx = -vzarr*dpdz/denarr
plot, xx, zz, ytitle='Height [km]', xtitle=' ', /noerase, $
      xthick=3, ythick=3, thick=2, charsize=1.5, color=culz.blue, charthick=3, /ystyle, $
      yrange=[zlo,zhi], xticks=2, xticklen=0.001, xtickname=replicate(' ', 3), $
      xrange = rr + [-.1*rl, .1*rl], /xstyle

xx = s
plot, xx, zz, ytitle='Height [km]', xtitle='1000 x Source function [s!U-1!N]', /noerase, $
      xthick=3, ythick=3, thick=4, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = rr + [-.1*rl, .1*rl], /xstyle

spot = convert_coord(rr(0) - 0.1*rl, 0, /data, /to_normal)

xyouts, spot(0), 0.1,  'Red: Vertical divergence term', color=culz.red, align=0, charsize=1.5, charthick=3, /normal
xyouts, spot(0), 0.07, 'Blue: Vertical advection term', color=culz.blue, align=0, charsize=1.5, charthick=3, /normal
xyouts, spot(0), 0.04, 'Black: Total', color=culz.black, align=0, charsize=1.5, charthick=3, /normal

    vz_wotnext, 'WIN', choice, help='Next: Close-up Longitude-Latitude Map'
    if choice eq 'Exit' then goto, Done

erase, color=culz.white

!p.position = [0.1, 0.20, 0.48, 0.98]
xx = 1e6*qarr
plot, xx, zz, ytitle='Height [km]', xtitle='Heat input [micro J m!U-3!N s!U-1!N]', /noerase, $
      xthick=3, ythick=3, thick=4, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = [min(xx), max(xx)] + [-.1*(max(xx)-min(xx)), .1*(max(xx)-min(xx))], /xstyle

xx = temarr
plot, xx, zz, ytitle='Height [km]', xtitle=' ', /noerase, $
      xthick=3, ythick=3, thick=2, charsize=1.5, color=culz.blue, charthick=3, /ystyle, $
      yrange=[zlo,zhi], xticks=2, xticklen=0.001, xtickname=replicate(' ', 3), $
      xrange = [min(xx), max(xx)] + [-.1*(max(xx)-min(xx)), .1*(max(xx)-min(xx))], /xstyle
      pp = convert_coord(min(xx), 35., /data, /to_normal)

axis, pp(0), 0.1, xaxis=0, color=culz.blue, xthick=3, ythick=3, charsize=1.5, charthick=3, $
      ymargin=[10,3], xtitle='Temperature [K]', /normal

xx = 1e6*qarr
plot, xx, zz, ytitle='Height [km]', xtitle='Heat input [micro J m!U-3!N s!U-1!N]', /noerase, $
      xthick=3, ythick=3, thick=4, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = [min(xx), max(xx)] + [-.1*(max(xx)-min(xx)), .1*(max(xx)-min(xx))], /xstyle

!p.position = [0.6, 0.20, 0.98, 0.98]

xx = -1000.*((2*qarr)/(8.3144*temarr))*((oden+n2den)/(5.*oden+7.*n2den))*6.022e23/(1e6*(oden+n2den))
plot, xx, zz, ytitle='Height [km]', xtitle='1000 x Heating term [s!U-1!N]', /noerase, $
      xthick=3, ythick=3, thick=3, charsize=1.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], $
      xrange = rr + [-.1*rl, .1*rl], /xstyle

Done:
!p.position = 0


end