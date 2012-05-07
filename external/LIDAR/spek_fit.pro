;=================================================================================================
;
;+
; NAME:
;       Spek_Fit
; PURPOSE:
;       This is the kernel routine for fitting a model spectrum to
;       an observed spectrum recorded by a lidar or passive FPS system.
; CALLING:
;       Spek_Fit, obs_spec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality
; INPUTS:
;       obs_spec: A vector of real numbers representing the
;                 observed spectrum, in wavelength space.
;       insprof:  A vector of real numbers representing the instrument
;                 function in wavelength space.  Must be the the same
;                 length as obs_spec.
;       species:  An array of structures defining the various molecular
;                 species.  Fields in the structures are:
;                   name:   string specifying species name, e.g. "N2"
;                   mass:   real number specifying species mass in AMU
;                   relint: real number specifying the relative
;                           intensity of the Rayleigh backscatter from
;                           this species.  Relint values summed over
;                           species should total 1. (If not, this
;                           will scale the relint values so they do.)
;       cal:      A structure containing some required calibration
;                 information.  Fields in the structure are:
;                   delta_lambda: the wavelength interval spenned by
;                           one channel of a spectrum.
;                   nominal_lambda: the nominal observing wavelength.
;       fix_mask: An integer array of the same size as "fitpars".  Each
;                 array element controls fitting of the corresponding
;                 parameter in fitpars.  Only parameters with a zero-
;                 valued element in the corresponding location of
;                 fix_mask will be fitted.  Parameters with a non-zero
;                 fix_mask entry will remain "fixed" at their initial value.
;       diagz:    A string array , containing various possible keywords.  These
;                 are used to trigger optional diagnostic outputs from
;                 internal components of the analysis.
;       fitpars:  An array containing the values for the fitted
;                 parameters.  Array elements are:
;                   background:   the background continuum level in
;                                 counts/channel.
;                   aerosol:      the aerosol backscatter intensity
;                                 coefficient.
;                   molecules:    the molecular backscatter intensity
;                                 coefficient.
;                   peak_channel: the channel in which the observed
;                                 spectrum peaks.
;                   temperature:  the best-fit temperature.
;       Upon completion, SPECKFIT returns its final parameter
;       estimates in the fitpars array.
;       NOTE: fitpars must be defined and passed in, which is why it
;             is listed as an input.  Peak_channel and temperature
;             must be passed in with meaningful values; these are used as
;             initial estimates for these parameters.  Further, any
;             parameter with a non-zero "fix_mask" entry must be supplied
;             with a sensible initial estimate - to be used as a fixed
;             value throughout this routine.
; OUTPUTS:
;       sigpars:  An array containing one-sigma standard errors of
;                 the fitted parameters.
;       quality:  A structure containing some parameters indicating the
;                 quality of the data and of the fit.  Fields in the
;                 structure are:
;                 chisq:    A 100-element floating-point array
;                           containing the unreduced chi-squared
;                           goodness of fit estimates after each
;                           iteration.
;                 fitfunc:  A vector containing the final fitted function.
;                 variance: The variance of the noise term in the
;                           observed profile, estimated from the
;                           high-frequency components of its power
;                           spectrum.
;                 snr:      A floating-point scalar containing the
;                           observed spectrum's signal/noise ratio.
;                 df:       The number of statistical degrees of
;                           freedom in the fit (integer-valued).
;                 iters:    The (integer) number of iterations
;                           that were needed for convergence.
;                 status:   A string describing the status of the
;                           fit. Possible values are:
;                             'OK',
;                             'Signal/noise too low',
;                             'Singular dimensions encountered'
;                             'Exceeded iteration limit'
;                 warning:  A string describing some possible
;                           warning conditions.  Possible values are:
;                             'None'
;                             'Final result was NOT the smallest chi-squared'
;                             'Invoked WARP, to escape a local chi-squared minimum'
;                 version:
;                           A string describing the version number of the 'spek_fit'
;                           software that was used. As of August 2001, the most recent
;                           version is 1.2.
; KEYWORDS:
;       numeric_derivatives:
;                 Set this keyword to force the partial derivatives of the
;                 fitting function with respect to position and temperature
;                 to be evaluated numerically, rather than analytically.
;       passive_fps:
;                 Set this keyword to indicate that the spectra come from a
;                 passive FPS, i.e. NOT from a lidar. This distinction is
;                 needed because a given temperature value will give double
;                 Doppler spectral width in a lidar than that of a passive
;                 system, because of the "reflection" involved in getting
;                 the light to backscatter.
;       max_iters:
;                 Set this keyword to indicate the maximum number of iterations
;                 that will be performed. If this keyword is not supplied, the
;                 default is 100 iterations.
;       chisq_tolerance:
;                 Use this keyword to specify the desired delta-chisqr between
;                 succesive iterations that is to be used as a stopping criterion.
;                 The default is to use 0.01*alog10(snr)
; PROCEDURE:
;       A combination of singular-value decomposition (for background,
;       aerosol, and molecules) and Levenberg-Marquardt searching
;       (for temperature and peak channel).
; HISTORY:
;       Written by Mark Conde, Kingston, July 1998.
;-
;
;==============================================================================

@spekutil.pro                                      ; Include general utility routines
@spekldar.pro                                      ; Include lidar specific routines

pro Spek_Fit, obs_spec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality, $
              numeric_derivatives=numder, passive_fps=passive, min_iters=min_iters, max_iters=max_iters, chisq_tolerance=tolerance

common temporary, parhist, os ;###################
os = obs_spec                 ;###################

if not keyword_set(passive)    then passive = 0.5 else passive = 1.
if not(keyword_set(min_iters)) then min_iters = 5.
if not(keyword_set(max_iters)) then max_iters = 100.
if not(keyword_set(tolerance)) then tolerance = -1.

@spekinc.pro                                       ; Define common blocks for main module
    parhist   = fitpars                            ; Will contain successive par estimates
    sigpars   = fltarr(n_elements(fitpars))-1.     ; Uncertainties, initially all -1
    spekinit, species, obs_spec, fitpars, $        ; Initialize common blocks
              insprof, diagz,    fix_mask, passive, min_iters, max_iters, tolerance
    quality   = qalz                               ; Create an initial quality indicator
    if qalz.snr lt 25 then qalz.status = "Signal/noise too low"
    if qalz.snr lt 25 then return                  ; Abort if too little information
    spek_bas, species,  fitpars, cal               ; Create initial basis functions
    spek_lin, obs_spec, fitpars, sigpars           ; Initial linear coefficients
    spekmodl, obs_spec, fitpars                    ; Evaluate fit function & residuals
    spek_chi                                       ; Initial chi-squared value
    if diagsel('main_plot_fitz') then begin  ; Plot data & fit function
       plot,  obs_spec, psym=1, title="Observed and fitted spectra"
       oplot, funz.fitfunc
    endif
    dummy = diagsel('main_call_external')          ; Can be used to invoke an external routine
                                                   ; once/main loop. Supply the routine name as
                                                   ; an argument to the diagnostic string.
    while not spekdone(fitpars) do begin
          qalz.iters = qalz.iters + 1
          spek_der, species,  fitpars, cal, $      ; Evaluate derivatives wrt pos & temp
                    numeric=numder
          spek_nln, obs_spec, fitpars, sigpars, $  ; Fit position and temperature
                    species,  cal
          spekwarp, obs_spec, fitpars, species, $  ;  Test if stuck in a local minimum;
                    cal, fix_mask                  ; "warp" out if so...
          spek_lin, obs_spec, fitpars, sigpars     ; Fit the linear coefficients
          spek_chi                                 ; Latest chi-squared
          parhist   = [[parhist], [fitpars]]

;         Now some code to generate diagnostic outputs, if requested:
          dummy = diagsel('main_call_external')    ; Can be used to invoke an external routine
                                                   ; once/main loop. Supply the routine name as
                                                   ; an argument to the diagnostic string.
          if diagsel('main_plot_pars') then begin
                erase
                for jj = dimz.npars - 1, 0, -1 do begin
                    pos = [0.1, 0.15+float(jj)/(dimz.npars+1), 0.9, 0.15+float(jj+1)/(dimz.npars+1)]
                    yr  = [min(parhist(jj, *)), max(parhist(jj, *))]
                    yr  = yr + [yr(0)-yr(1), yr(1)-yr(0)]/10.
                    if qalz.iters gt 1 and jj lt 3 then parhist(jj, 0) = parhist(jj, 1)
                    if jj ne 0 then begin
                       plot, parhist(jj, *), xtitle="", ytitle=namz.parz(jj), yrange=yr, /xstyle, $
                            position=pos, /ystyle, xticks=1, xtickname=[" "," "], /noerase
                    endif else begin
                       plot, parhist(jj, *), ytitle=namz.parz(jj), yrange=yr, /xstyle, $
                            position=pos, /ystyle, /noerase, xtitle="Iteration number"
                    endelse
                endfor
          endif
          if diagsel('main_plot_fitz') then begin  ; Plot data & fit function
             plot,  obs_spec, psym=1, title="Current fit", $
                                     xtitle="Scan channel", $
                                     ytitle="Signal counts"
             oplot, funz.fitfunc
          endif
          if diagsel('main_plot_chisq') then begin ; Plot evolution of chisq, if requested
             plot_io, qalz.chisq(0:qalz.iters)/qalz.df,  title="Chi-squared history", $
                                                       xtitle="Iteration number", $
                                                       ytitle="Reduced chi-suared"
          endif
          if diagsel('main_print_pars') then begin ; Print latest parameter estimates?
             print, "PARS:", fitpars
          endif
          if diagsel('main_print_sigma') then begin ; Print latest parameter estimates?
             print, "SIGMA:", sigpars
          endif
          if diagsel('main_loop_wait') then wait, ctlz.secwait
    endwhile

;   Now compute the final error estimates:
    spek_der, species, fitpars, cal, /all_pars
    spek_sgma, sigpars
    quality = qalz
	quality.fitfunc = funz.fitfunc

    if diagsel('main_print_status') then begin
       print, "SPEK_FIT exit status is: ", qalz.status
       print, "Last warning was: ", qalz.warning
    endif
    if diagsel('main_print_answer') then begin
       print, "Final parameter estimates are:"
       for j=0,dimz.npars-1 do begin
           print, strcompress("   " + namz.parz(j) +  ": " + string(fitpars(j)) + ", +/- " + string(sigpars(j)))
       endfor
       print, "======================================================================="
    endif
    if diagsel('main_plot_answer') then begin  ; Plot data & fit function
       plot,  obs_spec, psym=1, title="Final fit", $
                               xtitle="Scan channel", $
                               ytitle="Signal counts"
       oplot, funz.fitfunc
    endif
    while fitpars(ptrz.position) gt  dimz.npts/2. do fitpars(ptrz.position) = fitpars(ptrz.position) - dimz.npts
    while fitpars(ptrz.position) lt -dimz.npts/2. do fitpars(ptrz.position) = fitpars(ptrz.position) + dimz.npts
end
