
nz    = n_elements(ua)
result= 0L
boltz = 1.380658e-23
amu   = 1.6726231e-27

yyddd = 98010L
sec = 0.
lat = 65.
lon = -150.
f107a = 220.
f107 = 220.
ap = fltarr(7)
mass = 48L
t = fltarr(2)
d = fltarr(8)

sig1 = 4e-10
sig2 = 3.65e-10
sigo = sqrt(5e-19)

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

; Fire up a window:
load_pal, culz
window, xsize=1000, ysize=800
!p.multi=0
!p.position = [0, 0, 0, 0]


; Calculate the MSIS neutral densities:
for j=0,nz-1 do begin
    result  = call_external('d:\users\conde\main\idl\msis\idlmsis.dll','msis90', $
                            ua(j)._date, ua(j).time_ut, ua(j).altitude, ua(j).latitude, ua(j).longitude, ua(j).loc_sol_time, f107a, f107, ap, mass, d, t)
    mmm     = (d(0)*4. + d(1)*16. + d(2)*28. + d(3)*32.)/(d(0) + d(1) + d(2) + d(3))
    density = total(d(0:4))
    n2      = density*1e6
    
    atrec = {ua: ua(j), $
            mmm:mmm, $
        density: density, $
           o2n2: d(1)/d(2), $
          O_den: d(1), $
         N2_den: d(2), $
    temperature: t(1), $
              H: boltz*t(1)/(mmm*amu*9.8), $
         vtherm: sqrt(3*boltz*t(1)/(mmm*amu)), $
          OOmfp: 1./(n2*sigo^2), $
     collisfreq: n2*sigo^2*sqrt(8*boltz*t(1)/(!pi*mmm*amu))}
     if j eq 0 then atrex = atrec else atrex = [atrex, atrec]
endfor

plot_loop:

erase, color=culz.white

   orbs = string(atrex.ua._orbit)
   orbs = uniq_elz(orbs)
   mcchoice, 'Choose an orbit: ', orbs, choice, $
	       heading = {text: 'Orbit Selection', font: 'Helvetica*Bold*Proof*30'}, $
	      help='Subsequent plots will show data from this orbit only.'
	      
   keepers = where(string(atrex.ua._orbit) eq orbs(choice.index))
selrex = atrex(keepers)

o2n2_rat = (selrex.ua.o_density/selrex.ua.n2_density)/selrex.o2n2
head     = 'DE2 orbit number ' +  strcompress(orbs(choice.index), /remove_all)


    dely     = 0.9/3
    !p.charsize = 1.8
    !p.charthick=2
    !p.position = [0.12, 0.08, 0.98, 0.98]

    timlimz = [min(selrex.ua.time_ut), max(selrex.ua.time_ut)]
    timrange = timlimz(1) - timlimz(0)
    timlimz = timlimz + [-0.05*timrange, 0.05*timrange]
    
    timlimz = [14.8, 15.7] ;#######################

    plot, timlimz, [0,1], $
	  color=culz.ash, /nodata, /xstyle, /ystyle, $
	  yticks=1, ytickname=[' ', ' '], yminor=1, $
	  xminor=1, xthick=1, ythick=1, /noerase, xtitle="Time [Hours UT]", xticklen=1., yticklen=1.
    plot, timlimz, [0,1], $
	  color=culz.black, /nodata, /xstyle, /ystyle, $
	  yticks=1, ytickname=[' ', ' '], yminor=1, $
	  xticks=1, xtickname=[' ', ' '], xminor=1, xthick=4, ythick=4, /noerase, xtitle="Time [Hours UT]"

    !p.charthick=2
    
    ylimz = [-80, 120]
    !p.position = [0.12, 0.98-dely*1, 0.98, 0.98]
    plot, timlimz, ylimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, ytitle="Vertical Wind [m/s]", xthick=4, xtickname=replicate(' ', 30)
	  oplot, timlimz, [0,0], color=culz.ash, thick=1, linestyle=1
	  oplot, selrex.ua.time_ut, selrex.ua.upward_wind, thick=2, color=culz.black
	  

    ylimz = [0.1, 1.]
    !p.position = [0.12, 0.98-dely*2, 0.98, 0.98-dely]
    plot, timlimz, ylimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, ytitle="DE2/MSIS N2 Density", xthick=4, xtickname=replicate(' ', 30)
	  oplot, selrex.ua.time_ut, selrex.ua.n2_density/selrex.n2_den, thick=2, color=culz.black

    ylimz = [0, 7000]
    !p.position = [0.12, 0.98-dely*3, 0.98, 0.98-dely*2]
    plot, timlimz, ylimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, ytitle="Ion Temperature [K]", xthick=4
	  oplot, selrex.ua.time_ut, selrex.ua.ion_temp, thick=2, color=culz.black

;plot, selrex.ua.time_ut, o2n2_rat, xtitle='Time [Hours UT]', /noerase, ytitle='DE2 to MSIS [O]/[N2] Ratio', title=head, /xstyle, $
;      xthick=3, ythick=3, thick=3, charsize=2.5, color=culz.black, charthick=3, /ystyle, psym=1, yrange=[0, 6] 

           mcchoice, 'Choose an action: ', ['Continue', 'Exit'], choice, $
       	       heading = {text: 'Keep Plotting?', font: 'Helvetica*Bold*Proof*30'}, $
       	       help='Continuing will allow you to choose a different orbit number'
           if choice.name eq 'Continue' then goto, plot_loop


end
