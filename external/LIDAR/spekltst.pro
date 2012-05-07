;=======================================================
;
;  This is a main program, used to test the lidar
;  "spek_fit" subroutine.

@spek_fit.pro

;   Make an instrument profile:
pro make_insprof, insprof, species, cal, npts, ipos
       itemp  = 8. ; Express the insprof width as an equivalent temperature
       inswid = spek_wdt(itemp, species(0).mass, $
                         cal.nominal_lambda, cal.delta_lambda)
       spekfgau, npts, 0.,   inswid, 1.,  gauft
       spekfgau, npts, 0., 5*inswid, .03, widegauft
       gauft   = gauft + widegauft
       spekfgau, npts, 0., 10*inswid, .01, widegauft
       gauft   = gauft + widegauft
       assym   = fltarr(npts)
       aswid   = fix(4*inswid)
       aslo    = ipos - aswid/2
       assym(aslo:aslo+aswid-1) = indgen(aswid)
       assym   = fft(assym, -1)
       insprof = ftdrl(gauft*assym)
       insprof = insprof/max(insprof)
end

;   Make a noise-free sky return spectrum:
pro make_obspec, obspec, insprof, species, cal, fitpars

   nspecies = n_elements(species)
   npts     = n_elements(insprof)
   obspec   = fltarr(npts)
   ftinsp   = fft(insprof, -1)
;  Create the aerosol basis function:
   aerosol = ftdrl(spekfshf(ftinsp, fitpars(3)))
   aerosol = aerosol/max(aerosol)

;  Create the molecular basis functions:
   for k=0,nspecies - 1 do begin
;      Compute the spectral width for species k, in channels:
       molewid = spek_wdt(fitpars(4), species(k).mass, $
                                  cal.nominal_lambda, cal.delta_lambda)
;      Generate the transform of the Gaussian for species k:
       spekfgau, npts, fitpars(3), molewid, 1., gauft
       molebas = ftdrl(gauft)
;      Accumulate the total molecular basis function by summing the kth
;      component with appropriate relative intensity:
       obspec = obspec + species(k).relint*ftdrl(ftinsp*gauft)
   endfor
   obspec = obspec/max(obspec)

   obspec = fitpars(2)*obspec + fitpars(1)*aerosol + fitpars(0)

end

pro addnoise, spek, namp
    common seedspot, seed
    spek = spek + namp*randomn(seed, n_elements(spek))
end

;   This procedure is called by spek_fit's main routine, once per iteration of the main loop.
;   Calling is triggered by supplying the diagnostic string 'main_call_external(ps_diagplot)'.
;   (Actually, ANY diagnostic string that includes the argument '(ps_diagplot)' will invoke
;   this procedure.)  It is used to make postscript files of some diagnostic plots.
pro ps_diagplot
common temporary, parhist, os
@spekinc.pro
    itzon3 = float(qalz.iters)/3.
    if itzon3 - fix(itzon3) gt 0.09 then return
    set_plot, 'PS'
    device, filename="d:\conde\lidar\parhist.ps", $
            /helvetica, $
            font_size=15, $
            /portrait

    for jj = dimz.npars - 1, 0, -1 do begin
        pos = [0.1, 0.15+float(jj)/(dimz.npars+1), 0.9, 0.15+float(jj+1)/(dimz.npars+1)]
        yr  = [min(parhist(jj, *)), max(parhist(jj, *))]
        yr  = yr + [yr(0)-yr(1), yr(1)-yr(0)]/10.
        if qalz.iters gt 1 and jj lt 3 then parhist(jj, 0) = parhist(jj, 1)
        if jj ne 0 then begin
           plot, parhist(jj, *), xtitle="", ytitle=namz.parz(jj), yrange=yr, /xstyle, $
                position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase, charsize=0.7
        endif else begin
           plot, parhist(jj, *), ytitle=namz.parz(jj), yrange=yr, /xstyle, $
                position=pos, /ystyle, /noerase, xtitle="Iteration number", charsize=0.7
        endelse
    endfor
    device, /close
    fn = "d:\conde\lidar\fit_"  + strcompress(string(qalz.iters, format='(i2.2)'), /remove_all) + ".ps"
    device, filename=fn, $
            /helvetica, $
            font_size=15, $
            /portrait
    pt = "Fitted function after " + strcompress(string(qalz.iters, format='(i2.2)'), /remove_all) + " iterations"
    plot,  os, psym=1,  title=pt, $
                        xtitle="Scan channel", $
                        ytitle="Signal counts"
    oplot, funz.fitfunc
    device, /close

    device, /close
    fn = "d:\conde\lidar\chihist.ps"
    device, filename=fn, $
            /helvetica, $
            font_size=15, $
            /portrait
    if qalz.iters gt 2 then plot,  qalz.chisq(0:qalz.iters-1)/(dimz.npts-qalz.df),  title="Chi-squared history", $
                                   xtitle="Iteration Number", $
                                   ytitle="Reduced Chi-Squared"
    device, /close
    set_plot, 'WIN'
end

;==================================================================
;
;  So begins the main program:
;
;==================================================================

;  Delete any pre-existing windows:
   while (!D.window ge 0) do wdelete, !D.window

   npts  = 128
   ipos  = 0.4*npts

;  Specify the diagnostics that we'd like:
    diagz = ['dummy']
;   diagz = [diagz, 'main_plot_answer(window, 0)']
   diagz = [diagz, 'main_print_answer']
;   diagz = [diagz, 'main_call_external(ps_diagplot)']
;   diagz = [diagz, 'main_plot_pars(window, 2)']
;   diagz = [diagz, 'main_plot_chisq(window, 1)']
   diagz = [diagz, 'main_loop_wait(ctlz.secwait = 0.15)']

  namz = ['Background', $
          'Aerosol', $
          'Molecular', $
          'Position', $
          'Temperature']

;  Describe results scatter plot:
   parlo = [30., -40.,  10., 15., 50.]
   parhi = [60.,  70., 90.,  25., 450.]
   sighi = [ 5.,  30., 20.,  2.5, 300.]
   psel  = [0, 1, 2, 3, 4]
   npars = n_elements(psel)
   xr    = [30, 5000]

;  Values for the parameters used to generate test data:
   genpars   = [45., 15., 50., 20., 250.]

;  Specify initial guesses for fit routine, along with
;  the mask indicating which of these will remain fixed:
   guess_pars= genpars + [0., 0., 0., 0., 50.]
   fix_mask  = [0, 0, 0, 0, 0]

;  Describe the molecular scattering species:
   spec_spec = {s_spec, name: 'N2', $
                        mass:  28., $
                      relint: .75}
   species = replicate(spec_spec, 2)
   species(1).name   = 'O2'
   species(1).mass   = 32.
   species(1).relint = .25

;  Describe the instrument.  Initially assume 10 mm
;  etalon gap, 0.9 order scan range, 128 channel spectrum:
   cal = {s_cal,   delta_lambda: 0.7e-13, $
                 nominal_lambda: 532e-9}

;  Make the insprof: and add some noise:
   make_insprof, insprof, species, cal, npts, ipos
   window, 0
   plot, insprof, title="Instrument profile", xtitle="Channel number", $
         ytitle="Signal counts", /ystyle, yrange=[-.2,1.1]

;  Make a template spectrum:
   make_obspec,  obspec, insprof, species, cal, genpars

;  Add noise to the measured insprof:
   noise_amp = 0.01
   addnoise, insprof, noise_amp
   oplot, insprof
   set_plot, 'PS'
   fn = "d:\users\conde\main\lidar\insprof.ps"
   device, filename=fn, $
           /helvetica, $
           font_size=15, $
           /portrait
   plot, insprof, title="Instrument profile", xtitle="Channel number", $
         ytitle="Signal counts", /ystyle, yrange=[-.2,1.1]
   device, /close
   set_plot, 'WIN'

   dummy = " "
   read, "Press RETURN to continue", dummy
   strtime = systime(1)

;  Now loop around adding noise to the template spectrum,
;  and then submit each result to the analysis routine:
   nspec     = 1500
   pcount    = 0
   itertot   = 0
   for j=0,nspec-1 do begin
       pcount = pcount + 1
       fitpars   = guess_pars
       fitpars(3) = fitpars(3) +  5.*randomn(seed)
       fitpars(4) = fitpars(4) + 80.*randomn(seed)
       noise_amp = 20.*(0.1 + randomu(seed))
       obs_spec = obspec
       addnoise, obs_spec, noise_amp
       stop
       spek_fit, obs_spec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
       if j eq 0 then begin
           parhist = fitpars
           sighist = sigpars
           qalhist = quality
       endif else begin
           if quality.status eq 'OK' then begin
              parhist   = [[parhist], [fitpars]]
              sighist   = [[sighist], [sigpars]]
              qalhist   = [ qalhist,   quality]
           endif
       endelse
       itertot = itertot + quality.iters
       if n_elements(parhist(0,*)) gt 1  and pcount gt 25 then begin
                pcount = 0
                window, 1, xsize=700, ysize=700
                for jj = npars-1, 0, -1 do begin
                    pos = [0.1, 0.15+float(jj)/(npars+1), 0.9, 0.15+float(jj+1)/(npars+1)]
                    yr  = [parlo(psel(jj)), parhi(psel(jj))]
                    if jj ne 0 then begin
                       plot_oi, qalhist(*).snr, parhist(psel(jj), *), psym=1, symsize=0.1, $
                            xtitle="", ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase
                    endif else begin
                       plot_oi, qalhist(*).snr, parhist(psel(jj), *), psym=1, symsize=0.1, $
                            ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, /noerase, xtitle="Signal/noise"
                    endelse
                endfor


                window, 2, xsize=700, ysize=700
                for jj = npars-1, 0, -1 do begin
                    pos = [0.1, 0.15+float(jj)/(npars+1), 0.9, 0.15+float(jj+1)/(npars+1)]
                    yr  = [0, sighi(psel(jj))]
                    if jj ne 0 then begin
                       plot_oi, qalhist(*).snr, sighist(psel(jj), *), psym=1, symsize=0.1, $
                            xtitle="", ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase
                    endif else begin
                       plot_oi, qalhist(*).snr, sighist(psel(jj), *), psym=1, symsize=0.1, $
                            ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, /noerase, xtitle="Signal/noise"
                    endelse
                endfor
       endif
;       dummy = " "
;       read, "Press RETURN to continue", dummy
   endfor

   deltime = systime(1) - strtime
   print, "Average time/spectrum was: ", float(deltime)/nspec, " seconds."
   print, "Average number of iterations was: ", float(itertot)/n_elements(parhist(0, *))

;  Make a postscript scatter plot of the fitted parameters:
                set_plot, 'PS'
                device, filename="d:\conde\lidar\parscat.ps", $
                        /helvetica, $
                        font_size=8, $
                        /portrait
                for jj = npars-1, 0, -1 do begin
                    pos = [0.1, 0.15+float(jj)/(npars+1), 0.9, 0.15+float(jj+1)/(npars+1)]
                    yr  = [parlo(psel(jj)), parhi(psel(jj))]
                    if jj ne 0 then begin
                       plot_oi, qalhist(*).snr, parhist(psel(jj), *), psym=1, symsize=0.1, $
                            xtitle="", ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase
                    endif else begin
                       plot_oi, qalhist(*).snr, parhist(psel(jj), *), psym=1, symsize=0.1, $
                            ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                            position=pos, /ystyle, /noerase, xtitle="Signal/noise"
                    endelse
                endfor
                device, /close

                device, filename="d:\conde\lidar\sigscat.ps", $
                        /helvetica, $
                        font_size=8, $
                        /portrait

    for jj = npars-1, 0, -1 do begin
        kk = 30
        while kk lt 16000 do begin
           ns = 0
           sel = where(qalhist(*).snr gt kk/2 and qalhist(*).snr lt kk, ns)
           if ns gt 1 then begin
              sd  = standev(parhist(psel(jj), sel))
              if kk eq 30 then begin
                 parsig = sd
                 snrval = kk/2 + kk/4
              endif else begin
                 parsig = [parsig, sd]
                 snrval = [snrval, kk/2 + kk/4]
              endelse
           endif
           kk = kk*2
        endwhile
        pos = [0.1, 0.15+float(jj)/(npars+1), 0.9, 0.15+float(jj+1)/(npars+1)]
        yr  = [0, sighi(psel(jj))]
        if jj ne 0 then begin
           plot_oi, qalhist(*).snr, sighist(psel(jj), *), psym=1, symsize=0.1, $
                xtitle="", ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase
           for ss=5,10 do begin
               oplot, snrval, parsig, psym=4, symsize=0.15*ss
           endfor
        endif else begin
           plot_oi, qalhist(*).snr, sighist(psel(jj), *), psym=1, symsize=0.1, $
                ytitle=namz(psel(jj)), yrange=yr, xrange=xr, /xstyle, $
                position=pos, /ystyle, /noerase, xtitle="Signal/noise"
           for ss=5,10 do begin
               oplot, snrval, parsig, psym=4, symsize=0.15*ss
           endfor
        endelse
    endfor

    device, /close
    set_plot, 'WIN'
end