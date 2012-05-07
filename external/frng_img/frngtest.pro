@frngprox.pro

load_pal, culz, idl=[3,1]
readlaser, ltest
lref = ltest
nx = n_elements(ltest(*,0))
ny = n_elements(ltest(0,*))


;--First, run a fit that does not allow any distortions. Save the result as 'phq':
frnginit, php, nx, ny, mag=[ 0.00024, 0.00024, 0.], $
                       warp = [0.0,  0.], $
                       center=[132.88, 127.327], $
                       ordwin=[0.1,6.1], $
                       phisq =0.0, $
                       R=0.85, $
                       xcpsave='NO'
php.xwstp  = 0.
php.ywstp  = 0.
php.xymstp = 0.
php.phistp = 0.
frng_fit, ltest, php, culz
phq = php
phq.xmag = (phq.xmag + phq.ymag)/2.
phq.ymag = phq.xmag

;--Now fit with distortions allowed. Save the result as 'php':
frnginit, php, nx, ny, mag=[ 0.000240070, 0.0002406, 1.75241e-008], $
                       warp = [0.000137784,  -0.0316878], $
                       center=[132.88, 127.327], $
                       ordwin=[0.1,6.1], $
                       phisq =0.003329, $
                       R=0.85, $
                       xcpsave='d:\users\conde\main\idl\frng_img\zerph_search.gif'
frng_fit, ltest, php, culz

stop ; ########

npts = 32
llas = lref

frng_spx, lref, llas, php, npts, [0.8, 2.8], 0.99, culz, insprof
insprof = insprof - min(insprof)
insprof = insprof/max(insprof)
empty


PLOOP:
readlaser, lsky
wshow, 0
empty

lref = lsky
frng_spx, lref, lsky, php, 32, [0.8, 2.8], 0.96, culz, skyspec
cen = where(skyspec eq max(skyspec))
skyspec = shift(skyspec, n_elements(skyspec)/2 - cen(0))
empty

img = congrid(lsky, 2*php.nx, 2*php.ny, /interp)
view  = culz.imgmin + bytscl(img, top=culz.imgmax-culz.imgmin)
window, 2, xsize=2*php.nx, ysize=2*php.ny, xpos=2, ypos=2, title='Sky Image'
tv, view
gif_this, file='d:\users\conde\main\idl\frng_img\sky_image.gif'



;  Specify the diagnostics that we'd like:
    diagz = ['dummy']
;   diagz = [diagz, 'main_plot_answer(window, 0)']
   diagz = [diagz, 'main_print_answer']
   diagz = [diagz, 'main_plot_fitz(window, 0)']

  ;  Specify initial guesses for fit routine, along with
  ;  the mask indicating which of these will remain fixed:
     fitpars   = [0., 0., 0., 0., 100.]
     fix_mask  = [0, 1, 0, 0., 0.]
  
  ;  Describe the molecular scattering species:
     species = {s_spec, name: 'O', $
                          mass:  16., $
                        relint: 1.}
  
  ;  Describe the instrument.  Initially assume 20 mm
  ;  etalon gap, 1 order scan range, 128 channel spectrum:
     cal = {s_cal,   delta_lambda: 0.775e-13, $
                   nominal_lambda: 630.03e-9}
  

       skyspec = skyspec/max(skyspec)
       spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
       
;plot, skyspec, /xstyle, /ystyle, color=culz.white
;oplot, quality.fitfunc, color=culz.green

gap = 20e-3
lambda = 630e-9
fsr = lambda^2/(2*gap)
lambda = fsr*((findgen(n_elements(skyspec)) - n_elements(skyspec)/2)/n_elements(skyspec))/1e-12

           

           window, 2, xsize=1100, ysize=800, xpos=100, ypos=50, title="Derived spectrum and fit"
           erase, color=culz.white
           plot, lambda, skyspec, $
                 xtitle='!6Wavelength [pm]!3', ytitle='!6Normalized Intensity!3', $
                /xstyle, /ystyle, yminor=2, color=culz.black, $
                /noerase, xthick=3, ythick=3, thick=4, charthick=3, charsize=3.5, $
                ytickformat='(f3.1)', xrange=[-6,6], yrange=[0.6, 1.05]
;           oplot, lambda, quality.fitfunc, color=culz.black, thick=4, linestyle=2
           gif_this, file='d:\users\conde\main\idl\frng_img\derived_spectra.gif'


stop
goto, PLOOP


end