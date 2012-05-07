function d_by_dz, pararr, zinc
deriv = (pararr - shift(pararr, 1))/zinc
deriv(0) = deriv(1)
deriv = median(deriv, 5)
return, deriv
end

New_pars:
zlo   = 100.
zhi   = 400.
nz    = 1000

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
lat = 65.
lon = -150.
f107a = 120.
f107 = 120.
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
window, xsize=1000, ysize=800

denarr = fltarr(nz)
altarr = fltarr(nz)
temarr = fltarr(nz)
mmmarr = fltarr(nz)
o2n2   = fltarr(nz)

o2 = fltarr(nz)
n2 = fltarr(nz)
o  = fltarr(nz)
n  = fltarr(nz)
ar = fltarr(nz)
h  = fltarr(nz)
he = fltarr(nz)

; Calculate the MSIS neutral densities:
inc = (zhi - zlo)/nz
for j=0,nz-1 do begin
    altarr(j) = zlo + j*inc
    alt = altarr(j)
    result = call_external('c:\cal\idlsource\code\msis\idlmsis.dll','msis90', $
                        yyddd,sec,alt,lat,lon,lst,f107a,f107,ap,mass,d,t)
    mmm = (d(0)*4. + d(1)*16. + d(2)*28. + d(3)*32.)/(d(0) + d(1) + d(2) + d(3))
    mmmarr(j) = mmm
    denarr(j) = total(d(0:4))
    o2n2(j)   = d(1)/d(2)
    temarr(j) = t(1)

    o(j)  = d(1)
    n2(j) = d(2)
    o2(j) = d(3)
    ar(j) = d(4)
    h(j)  = d(6)
    he(j) = d(0)
    n(j)  = d(7)

endfor


zz  = zlo + inc*findgen(nz)
hh  = boltz*temarr/(mmmarr*amu*(9.8*(6371./(6371.+zz))^2))
;n2  = denarr*1e6
gma = (1.4 + o2n2*1.67)/(1 + o2n2)
massden = 1e6*denarr*mmmarr*1.6605402e-27
soundspd = sqrt(gma*(9.8*(6371./(6371.+zz))^2)*hh)
grad_ln_den = (alog(massden) - shift(alog(massden), 1))/(1000.*inc)
grad_ln_den(0) = grad_ln_den(1)
bvfreq   = sqrt(-(9.8*(6371./(6371.+zz))^2)*(grad_ln_den + 9.8/(gma*(9.8*(6371./(6371.+zz))^2)*hh)))
bvperiod = 2*!pi/bvfreq
bvperiod = median(bvperiod, 5)
accper = 2*!pi/((9.8*(6371./(6371.+zz))^2)*gma/(2*soundspd))
kinvisc = (1./3.)*sqrt(3*boltz*temarr/(mmmarr*amu))/(n2*sigo^2)

Optsel:
options = ['Temperature', 'Number Density', 'Pressure', 'Scale Height', 'Mean Molecular Mass', 'Mass Density', $
           '[O]/[N2]', 'Thermal Velocity', 'Viscosity', 'Kinematic Viscosity', 'O-O Mean Free Path', 'Collision Frequency', 'Sound Speed', $
           'Brunt-Vaisala Period', 'Accoustic Cutoff Period', 'User Expression', 'Make PNG File', 'New Parameters', 'Exit']


mcchoice, 'Choose an option: ', options, choice, $
       	       heading = {text: 'MSIS-derived parameter to plot?', font: 'Helvetica*Bold*Proof*20'}, $
       	       help='The selected parameter will be plotted as a function of altitude, for the MSIS model run using the parameters that you supplied earlier. The last two options allow you change the MSIS parameters or exit, respectively'
if choice.name eq 'New Parameters' then goto, New_pars
if choice.name eq 'Exit' then goto, bailer


;#####################################################################################################

;set_plot, 'ps'
;
;DEVICE, FILE = 'c:\dens.ps', /COLOR, BITS=8, xsize=20, ysize=28, xoffset=0, yoffset=1
;
;erase, 255
;
;!p.multi = [0,1,1] & !p.charsize = 1.5 & !p.charthick = 3
;!p.thick = 2 & !x.thick = 3 & !y.thick = 3
;
;
;;!p.position = [.3,.1,.8,.4]
;;plot, temarr, zz, title = 'Temperature', ytitle = 'Altitude (km)', xtitle = 'Temperature (K)',  /nodata
;;oplot, temarr, zz, color=71, thick=5
;;
;;parr = 1e6*temarr*8.31*denarr/(6.02e23)
;;!p.position = [.3,.5,.8,.8]
;;plot, parr, zz, title = 'Pressure', ytitle = 'Altitude (km)', xtitle = 'Pressure (Pa)', yrange=[zlo,zhi], /xlog, /ystyle, /nodata
;;oplot, parr, zz, color=255, thick=5
;
;dmin = min(o) < min(o2) < min(n) < min(n2) < min(ar) < min(he) < min(h)
;dmax = max(o) > max(o2) > max(n) > max(n2) > max(ar) > max(he) > max(h)
;
;!p.position = [.3,.1,.8,.4]
;!p.thick=6
;plot, n2, zz, /xlog, color=0, ytitle='Altitude (km)'
;oplot, o2, zz, color=255 ;red
;oplot, n, zz, color=64, linestyle=2
;oplot, o, zz,color=64 ;blue
;oplot, ar, zz, color=0, linestyle=2 ;black
;oplot, he, zz, color=255, linestyle=2
;oplot, h, zz, color=172 ;green
;
;
;device, /close_file
;
;
;set_plot, 'win'
;
;!p.multi = 0 & !p.position = 0 & !p.charsize = 1
;!p.charthick = 1 & !p.thick = 1 & !x.thick = 1
;!y.thick = 1 & !y.ticks = 0 & !x.style = 0
;!x.ticks = 0


;#########################################################################################################
stop
case choice.name of
	'Temperature': begin
	erase, color=culz.white
	plot, temarr, zz, ytitle='Height [km]', xtitle='Neutral Temperature [K]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]

	end
	'Number Density': begin
	erase, color=culz.white
	plot, denarr, zz, ytitle='Height [km]', xtitle='Total Number Density [cm!E-3!N]', /noerase,title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'Pressure': begin
	erase, color=culz.white
	parr = 1e6*temarr*8.31*denarr/(6.02e23)
	;parr = parr/101300. ; (to convert to Bar)
	plot, parr, zz, ytitle='Height [km]', xtitle='Pressure [Pa]', /noerase,title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'Scale Height': begin
	erase, color=culz.white
	plot, hh/1000., zz, ytitle='Height [km]', xtitle='Scale Height [km]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Mean Molecular Mass': begin
	erase, color=culz.white
	plot, mmmarr, zz, ytitle='Height [km]', xtitle='Mean Molecular Mass [AMU]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Mass Density': begin
	erase, color=culz.white
	plot, 1e6*denarr*mmmarr*1.6605402e-27, zz, ytitle='Height [km]', xtitle='Total Mass Density [kg m!E-3!N]', /noerase,title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'[O]/[N2]': begin
	erase, color=culz.white
	plot, o2n2, zz, ytitle='Height [km]', xtitle='[O]/[N!D2!N] Ratio', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Thermal Velocity': begin
	erase, color=culz.white
	plot, sqrt(3*boltz*temarr/(mmmarr*amu)), zz, ytitle='Height [km]', xtitle='Mean Thermal Velocity [m/s]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Viscosity': begin
	erase, color=culz.white
	plot, 1e6*1e6*denarr*mmmarr*1.6605402e-27*kinvisc, zz, ytitle='Height [km]', xtitle='10!U6!N x Viscosity [ kg m!U2!N s!U-1!N]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Kinematic Viscosity': begin
	erase, color=culz.white
	plot, kinvisc, zz, ytitle='Height [km]', xtitle='Kinematic Viscosity [m!U2!N s!U-1!N]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'O-O Mean Free Path': begin
	erase, color=culz.white
	n2  = denarr*1e6
	plot, 1./(n2*sigo^2), zz, ytitle='Height [km]', xtitle='O-O Mean Free Path [m]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'Collision Frequency': begin
	;-----Note: Really need mean collision cross section, not O cross section!
	erase, color=culz.white
	plot, n2*sigo^2*sqrt(8*boltz*temarr/(!pi*mmmarr*amu)), zz, ytitle='Height [km]', xtitle='Collision Frequency [Hz]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], /xlog
	end
	'Sound Speed': begin
        erase, color=culz.white
	plot, soundspd, zz, ytitle='Height [km]', xtitle='Sound Speed [m/s]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end
	'Brunt-Vaisala Period': begin
	isobv = 2*!pi/(sqrt(((gma - 1)*((9.8*(6371./(6371.+zz))^2))^2)/soundspd^2))/60.
	xra   = [min([bvperiod/60., isobv]), max([bvperiod/60., isobv])]
        erase, color=culz.white
	plot, bvperiod/60., zz, ytitle='Height [km]', xtitle='Brunt-Vaisala Period [Minutes]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], xrange=xra
	oplot, isobv, zz, linestyle=2, color=culz.black, thick=2
	xyouts, 0.22, 0.83, 'Solid: Actual temperature gradient', color=culz.black, charsize=2, charthick=3, align=0, /normal
	xyouts, 0.22, 0.86, 'Dashed: Isothermal approximation', color=culz.black, charsize=2, charthick=3, align=0., /normal
	end
	'Accoustic Cutoff Period': begin
        erase, color=culz.white
	plot, accper/60., zz, ytitle='Height [km]', xtitle='Accoustic Cutoff Period [Minutes]', /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi]
	end

	'User Expression': begin
	 uex = ' '
         mc_input, uex, title='User input', prompt='Expression ', $
	                   help='Enter a valid IDL-syntax expression of current program variables.', $
	                   heading = {text: 'User-expression to plot', font: 'Helvetica*Bold*Proof*30'}
	 print, 'Plotting expression:  ', uex
	 xlab = ' '
         mc_input, xlab, title='User input', prompt='Label ', $
	                   help='Enter a valid IDL-syntax string to be used as the X-axis label.', $
	                   heading = {text: 'X-axis Label String', font: 'Helvetica*Bold*Proof*30'}
        print, 'Unit string is: ', xlab
        mcchoice, 'Plot Style Selector', ['Linear', 'Log'], choice, $
                     heading = {text: 'X-Axis Type:', font: 'Helvetica*Bold*Proof*30'}
        status = execute('udata = ' + uex)
        erase, color=culz.white
	plot, udata, zz, ytitle='Height [km]', xtitle=xlab, /noerase, title=head, $
	      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, $
	      yrange=[zlo,zhi], xlog=choice.index
	end
	'Make PNG File': gif_this, /png
endcase
goto, optsel

Bailer:
end
