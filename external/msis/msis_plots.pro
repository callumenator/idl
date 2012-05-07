
zlo   = 0.
zhi   = 1500.
nz    = 1500

mc_input, zlo, title='Height Input', prompt='Bottom Height: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 400., min:0., value: zlo, ysize:100}, $
       heading = {text: 'Base Height', font: 'Helvetica*Bold*Proof*30'}

mc_input, zhi, title='Height Input', prompt='Top Height: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 2000., min:zlo, value: zhi, ysize:100}, $
       heading = {text: 'Upper Height', font: 'Helvetica*Bold*Proof*30'}

result= 0L
boltz = 1.380658e-23
amu   = 1.6726231e-27
sig1 = 4e-10
sig2 = 3.65e-10
sigo = sqrt(5e-19)

yyddd = 98010L
sec = 0.
lat = -67.6
lon = 62.87
f107a = 75.
f107 = 75.
ap = fltarr(7)
mass = 48L
t = fltarr(2)
d = fltarr(8)

lst = sec/3600. + lon/15.

mc_input, f107, title='Model Parameter Input', prompt='F10.7 value: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 240., min:60., value: f107, ysize:100}, $
       heading = {text: '10.7 cm Solar Flux', font: 'Helvetica*Bold*Proof*30'}
f107  = float(f107)
f107a = f107

apz = 15
mc_input, apz, title='Model Parameter Input', prompt='Ap value: ', $
       help='You may use either the entry box or the slider to provide a value.', $
       slider = {format: '(f5.1)', max: 100., min:0., value: apz, ysize:100}, $
       heading = {text: 'Ap Index', font: 'Helvetica*Bold*Proof*30'}
ap(0) = apz

head = 'MSIS-90 Model for F10.7=' + strcompress(string(f107, format='(i8)'), /remove_all) + ', Ap=' + strcompress(string(apz, format='(i8)'), /remove_all)

; Fire up a window:
load_pal, culz
window, xsize=700, ysize=600

denarr = fltarr(nz)
altarr = fltarr(nz)
temarr = fltarr(nz)
mmmarr = fltarr(nz)
o2n2   = fltarr(nz)

; Calculate the MSIS neutral densities:
inc = (zhi - zlo)/nz
for j=0,nz-1 do begin
    altarr(j) = zlo + j*inc
    alt = altarr(j)
    result = call_external('C:\Cal\IdlSource\Code\msis\idlmsis.dll','msis90', $
                        yyddd,sec,alt,lat,lon,lst,f107a,f107,ap,mass,d,t)
    mmm = (d(0)*4. + d(1)*16. + d(2)*28. + d(3)*32.)/(d(0) + d(1) + d(2) + d(3))
    mmmarr(j) = mmm
    denarr(j) = total(d(0:4))
    o2n2(j)   = d(1)/d(2)
    temarr(j) = t(1)
endfor

hh = boltz*temarr/(mmmarr*amu*9.8)

zz      = zlo + inc*findgen(nz)
stop
erase, color=culz.white
plot, temarr, zz, ytitle='Height [km]', xtitle='Neutral Temperature [K]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

erase, color=culz.white
plot, denarr, zz, ytitle='Height [km]', xtitle='Total Number Density [cm!E-3!N]', /noerase,title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
mc_message

erase, color=culz.white
parr = 1e6*temarr*8.31*denarr/(6.02e23)
;parr = parr/101300. ; (to convert to Bar)
plot, parr, zz, ytitle='Height [km]', xtitle='Pressure [Pa]', /noerase,title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
mc_message

erase, color=culz.white
plot, hh/1000., zz, ytitle='Height [km]', xtitle='Scale Height [km]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

erase, color=culz.white
plot, mmmarr, zz, ytitle='Height [km]', xtitle='Mean Molecular Mass [AMU]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

erase, color=culz.white
plot, 1e6*denarr*mmmarr*1.6605402e-27, zz, ytitle='Height [km]', xtitle='Total Mass Density [kg m!E-3!N]', /noerase,title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
mc_message


erase, color=culz.white
plot, o2n2, zz, ytitle='Height [km]', xtitle='[O]/[N!D2!N] Ratio', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

erase, color=culz.white
plot, sqrt(3*boltz*temarr/(mmmarr*amu)), zz, ytitle='Height [km]', xtitle='Mean Thermal Velocity [m/s]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi]
mc_message

erase, color=culz.white
n2  = denarr*1e6
plot, (1./3.)*sqrt(3*boltz*temarr/(mmmarr*amu))/(n2*sigo^2), zz, ytitle='Height [km]', xtitle='Kinematic Viscosity [m!U2!N s!U-1!N]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
mc_message

erase, color=culz.white
n2  = denarr*1e6
plot, 1./(n2*sigo^2), zz, ytitle='Height [km]', xtitle='O-O Mean Free Path [m]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
mc_message

;-----Note: Really need mean collision cross section, not O cross section!
erase, color=culz.white
plot, n2*sigo^2*sqrt(8*boltz*temarr/(!pi*mmmarr*amu)), zz, ytitle='Height [km]', xtitle='Collision Frequency [Hz]', /noerase, title=head, $
      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
      yrange=[zlo,zhi], /xlog
end
