
nz    = 50
nne   = 50
result= 0L
zlo   = 100
zhi   = 300
boltz = 1.380658e-23
amu   = 1.6726231e-27

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
ap(0) = 15.

; Fire up a window:
load_pal, culz
window, xsize=1000, ysize=800
erase, color=culz.white

denarr = fltarr(nz)
altarr = fltarr(nz)
temarr = fltarr(nz)
mmmarr = fltarr(nz)

; Calculate the MSIS neutral densities:
inc = (zhi - zlo)/nz
for j=0,nz-1 do begin
    altarr(j) = 150. + j*inc
    alt = altarr(j)
    result = call_external('d:\users\conde\main\idl\msis\idlmsis.dll','msis90', $
                        yyddd,sec,alt,lat,lon,lst,f107a,f107,ap,mass,d,t)
    mmm = (d(0)*4. + d(1)*16. + d(2)*28. + d(3)*32.)/(d(0) + d(1) + d(2) + d(3))
    mmmarr(j) = mmm
    denarr(j) = total(d(0:4))
    temarr(j) = t(1)
endfor

hh = boltz*temarr/(mmmarr*amu*9.8)

zz      = zlo + inc*findgen(nz)

plot, hh/1000., zz, ytitle='Height / km', xtitle='Scale Height / km', /noerase, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]      
mc_message

plot, temarr, zz, ytitle='Height / km', xtitle='Neutral Temperature / K', /noerase, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

plot, mmmarr, zz, ytitle='Height / km', xtitle='Mean Molecular Mass / AMU', /noerase, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]      
end
