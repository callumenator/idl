@frngprox.pro

device, decomposed=0
while !d.window ge 0 do wdelete, !d.window

load_pal, culz, idl=[3,1]
readlaser, ltest

; Remove any high-frequency noise from the image:
ltest = mc_im_sm(ltest, 3)

; Remove any low-frequecy background from the image:
ltest = ltest - mc_im_sm(ltest, 70)


lref = ltest
nx = n_elements(ltest(*,0))
ny = n_elements(ltest(0,*))

;--Now fit with distortions allowed. Save the result as 'php':
frnginit, php, nx, ny, mag=[ 0.000240070, 0.0002406, 1.75241e-008], $
                       warp = [0.000137784,  -0.0316878], $
                       center=[132.88, 127.327], $
                       ordwin=[0.1,5.1], $
                       phisq =0.003329, $
                       R=0.85, $
                       xcpsave='NO'
frng_fit, ltest, php, culz

wait, 4

npts = 32
llas = lref

frng_spx, lref, llas, php, npts, [0.8, 3.8], 0.99, culz, insprof
insprof = insprof - min(insprof)
insprof = insprof/max(insprof)
window, 3, xsize=500, ysize=400
plot, ltest(*, php.ycen), title="Image cross section through Y-center"
empty

wait, 4


PLOOP:
readlaser, lsky
; Remove any high-frequency noise from the image:
lsky = mc_im_sm(lsky, 3)

; Remove any low-frequecy background from the image:
lsky = lsky - mc_im_sm(lsky, 70)
wshow, 0
empty

lref = lsky
frng_spx, lref, lsky, php, 32, [0.5, 3.5], 0.96, culz, skyspec
cen = where(skyspec eq max(skyspec))
skyspec = shift(skyspec, n_elements(skyspec)/2 - cen(0))
window, 3, xsize=500, ysize=400
plot, lsky(*, php.ycen), title="Image cross section through Y-center"
empty

gap = 20e-3
lambda = 630e-9
fsr = lambda^2/(2*gap)

;  Specify the diagnostics that we'd like:
   diagz = ['dummy']
   diagz = [diagz, 'main_print_answer']
   diagz = [diagz, 'main_plot_fitz(window, 0)']

  ;  Specify initial guesses for fit routine, along with
  ;  the mask indicating which of these will remain fixed:
     fitpars   = [0., 0., 0., 0., 500.]
     fix_mask  = [0, 1, 0, 0., 0.]
  
  ;  Describe the molecular scattering species:
     species = {s_spec, name: 'O', $
                          mass:  16., $
                        relint: 1.}
  
  ;  Describe the instrument.  Initially assume 20 mm
  ;  etalon gap, 1 order scan range, 128 channel spectrum:
     cal = {s_cal,   delta_lambda: fsr/32., $
                   nominal_lambda: 630.03e-9}
  

       skyspec = skyspec/max(skyspec)
;    Call the fit 3 times, as these high sig/noise spectra often cause the fit loop to terminate early:       
       spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
       spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
       spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
       
lambda = fsr*((findgen(n_elements(skyspec)) - n_elements(skyspec)/2)/n_elements(skyspec))/1e-12

           

           window, 4, xsize=1100, ysize=800, xpos=100, ypos=50, title="Derived spectrum and fit"
           erase, color=culz.white
           plot, lambda, skyspec, $
                 xtitle='!6Wavelength [pm]!3', ytitle='!6Normalized Intensity!3', $
                /xstyle, /ystyle, yminor=2, color=culz.black, $
                /noerase, xthick=3, ythick=3, thick=4, charthick=3, charsize=3.5, $
                ytickformat='(f3.1)', xrange=[-6,6], yrange=[0.0, 1.05]
           oplot, lambda, quality.fitfunc, color=culz.black, thick=4, linestyle=2
 



end