;==========================================================
;
;  This file contains subroutines tailored for analysis of
;  lidar fps spectra.  They could be used as templates,
;  and modified as required for other fps analysis tasks.

;==========================================================
;  This function returns TRUE if the string "keystring" is
;  located anywhere in ctlz.diagz; otherwise it returns
;  FALSE.  It is, thankfully, NOT case sensitive.
function diagsel, keystring
@spekinc.pro
   found = 0
   for j=0,n_elements(ctlz.diagz)-1 do begin
       spot = strpos(ctlz.diagz(j), strupcase(keystring))
       if spot ge 0 $
          then begin
               found = 1
               leftbrak = strpos(ctlz.diagz(j), "(" )
               if leftbrak gt 0 then begin
                  ritebrak = strpos(ctlz.diagz(j), ")" )
                  cmd = strmid(ctlz.diagz(j), leftbrak+1, ritebrak-leftbrak - 1)
                  r = execute(cmd)
               endif
          endif
   endfor
   return, found
end

;==========================================================
;  Create basis functions using the current fitpars values.
;  Although there is only one basis function for the TOTAL
;  molecular scatter, we keep the component Gaussians due
;  to each particular species because we need these later,
;  for generating the derivatives of the fit function with
;  respect to position and temperature.

pro spek_bas, species, fitpars, cal
@spekinc.pro

   area_norm=1
   if fitpars(ptrz.temperature) lt 0.01 then fitpars(ptrz.temperature) = 1. ; protect us from unphysical temperatures.

;  Create the constant (background) basis function:
   funz.basis(ptrz.backgnd, *) = 1.

;  Create the aerosol basis function:
   funz.basis(ptrz.aerosol, *) = ftdrl(spekfshf(funz.ftinsp, fitpars(ptrz.position)))
   funz.basis(ptrz.aerosol, *) = funz.basis(ptrz.aerosol, *)/max(funz.basis(ptrz.aerosol, *))
   if diagsel('basis_plot_aerosol') then plot, funz.basis(ptrz.aerosol, *), title="Aerosol basis function"

;  Create the molecular basis functions:
   funz.basis(ptrz.molecular, *) = 0
   for k=0,dimz.nspecies - 1 do begin
;      Compute the spectral width for species k, in channels:
       funz.molewid(k) = spek_wdt(fitpars(ptrz.temperature), species(k).mass, $
                                  cal.nominal_lambda, cal.delta_lambda, ctlz.passive)
       if diagsel('basis_print_widths') then print, 'Species ', strcompress(string(k)), $
                                                    ' width is ', funz.molewid(k), ' channels.'
;      Generate the transform of the Gaussian for species k:
       spekfgau, dimz.npts, dimz.npts/2, funz.molewid(k), 1., gauft, area=area_norm
       funz.molebas(k, *) = ftdrl(gauft)
       gauft = spekfshf(gauft, fitpars(ptrz.position) - dimz.npts/2)
;      Accumulate the total molecular basis function by summing the kth
;      component with appropriate relative intensity:
       funz.basis(ptrz.molecular, *) = funz.basis(ptrz.molecular, *) + $
                                       species(k).relint*ftdrl(funz.ftinsp*gauft)
   endfor
   funz.nrm = max(funz.basis(ptrz.molecular, *))
;   if (area_norm) then funz.nrm = total(funz.basis(ptrz.molecular, *))
   funz.basis(ptrz.molecular, *) = funz.basis(ptrz.molecular, *)/funz.nrm
   funz.molebas = funz.molebas/funz.nrm
   if diagsel('basis_plot_molecular') then plot, funz.basis(ptrz.molecular, *), title="Molecular basis function"

end

;==========================================================
;  Create the fitting function and the residual:
pro spekmodl, obs_spec, fitpars
@spekinc.pro
;  Evaluate the total fitting function by summing the basis functions
;  weighted by their current coefficients:
   funz.fitfunc = fitpars(ptrz.backgnd  )*funz.basis(ptrz.backgnd,   *) + $
                  fitpars(ptrz.aerosol  )*funz.basis(ptrz.aerosol,   *) + $
                  fitpars(ptrz.molecular)*funz.basis(ptrz.molecular, *)
   if diagsel('model_plot_fitfunc') then plot, funz.fitfunc, title="Fitted function"
;  Evaluate the residuals:
   funz.residual = (obs_spec - funz.fitfunc)
   if diagsel('model_plot_residual') then $
      plot, funz.residual, title="Residual"
end

;==========================================================
;  Create the derivatives of the fitting function with
;  respect to the fit paramenters.  Unless the ALL_PARS keyword is set,
;  we only calculate the derivatives with respect to position and
;  temperature, for use in the non-linear parameter search.  If
;  ALL_PARS is set, we calculate the derivatives with respect to all
;  parameters, as these are used in the final calculation of uncertainties
;  in the parameter estimates.  The position and temperature derivatives
;  are calculated analytically, unless the NUMERIC keyword is set.

pro spek_der, species, fitpars, cal, numeric=numder, all_pars=allpar
@spekinc.pro

;  Test if numeric (rather than analytic) differention was
;  requested:
   if keyword_set(numder) then goto, numder

;==========================================================
;  Calculate the derivative with respect to peak position:
;  First, accumulate the derivatives due to each molecular component:
   deraccm = fltarr(dimz.npts)
   for k=0,dimz.nspecies-1 do begin
       dermul  = 2.*(dimz.xx)/(funz.molewid(k))^2
       deraccm = deraccm + species(k).relint*funz.molebas(k, *)*dermul
   endfor
   deraccm = fft(deraccm, -1)*fitpars(ptrz.molecular)
;  And shift to the current wavelength:
   deraccm = spekfshf(deraccm, fitpars(ptrz.position) - dimz.npts/2)
;  Convolve the molecular derivative with the insprof
   deraccm = deraccm*funz.ftinsp
;  Now add the component of derivative due to the aerosol, which is
;  given by -funz.insderiv, scaled by the aerosol intensity and shifted to current position:
   deraccm = deraccm - fitpars(ptrz.aerosol)*spekfshf(funz.insderiv, fitpars(ptrz.position))
   funz.parderiv(ptrz.position, *) = ftdrl(deraccm)

;==========================================================
;  Calculate the derivative with respect to temperature:
;  The only non-zero component of this occurs in the
;  molecular basis function:
   f1      = 5.40470535e12 ; =(AMU*c^2)/(2k)
   deraccm = fltarr(dimz.npts)
   for k=0,dimz.nspecies-1 do begin
       dermul  = 2.*((dimz.xx)/(cal.nominal_lambda/(cal.delta_lambda*ctlz.passive)))^2
       dermul  = (f1*species(k).mass/fitpars(ptrz.temperature)^2)*dermul
       deraccm = deraccm + species(k).relint*funz.molebas(k, *)*dermul
   endfor
   deraccm = spekfshf(fft(deraccm, -1), fitpars(ptrz.position) - dimz.npts/2)
;  Convolve the molecular derivative with the insprof, and scale by the
;  molecular intensity coefficient:
   funz.parderiv(ptrz.temperature, *) = 0.5*fitpars(ptrz.molecular)*ftdrl(deraccm*funz.ftinsp)

;  If we got to here, we're computing derivatives analytically. Skip the
;  numeric calculation:
   goto, ander

numder:
   spek_bas, species, fitpars, cal
   funz.fitfunc = fitpars(ptrz.backgnd  )*funz.basis(ptrz.backgnd,   *) + $
                  fitpars(ptrz.aerosol  )*funz.basis(ptrz.aerosol,   *) + $
                  fitpars(ptrz.molecular)*funz.basis(ptrz.molecular, *)
   fs = funz
   fitpars(3) = fitpars(3) + 0.1
   spek_bas, species, fitpars, cal
   funz.fitfunc = fitpars(ptrz.backgnd  )*funz.basis(ptrz.backgnd,   *) + $
                  fitpars(ptrz.aerosol  )*funz.basis(ptrz.aerosol,   *) + $
                  fitpars(ptrz.molecular)*funz.basis(ptrz.molecular, *)
   fs.parderiv(3,*) = (funz.fitfunc - fs.fitfunc)/0.1

   funz = fs
   fitpars(3) = fitpars(3) - 0.1

   fs = funz
   fitpars(4) = fitpars(4) + 2.
   spek_bas, species, fitpars, cal
   funz.fitfunc = fitpars(ptrz.backgnd  )*funz.basis(ptrz.backgnd,   *) + $
                  fitpars(ptrz.aerosol  )*funz.basis(ptrz.aerosol,   *) + $
                  fitpars(ptrz.molecular)*funz.basis(ptrz.molecular, *)
   fs.parderiv(4,*) = (funz.fitfunc - fs.fitfunc)/2.
   funz = fs
   fitpars(4) = fitpars(4) - 2.
ander:
   if diagsel('deriv_plot_position') then plot, funz.parderiv(ptrz.position, *), title="Position derivative"
   if diagsel('deriv_plot_temperature') then plot, funz.parderiv(ptrz.temperature, *), title="Temperature derivative"

;  Now check if we need to do the (trivial) differentiations with respect
;  to the linear paramters as well:
   if keyword_set(allpar) then begin
      for i=ptrz.backgnd, ptrz.molecular do begin
          funz.parderiv(i, *) = funz.basis(i, *)
      endfor
   endif
end

;==========================================================
;  This routine calls IDL's singular value decomposition
;  routine to fit the linear parameters specified by
;  ctlz.fix_mask:
pro spek_lin, obs_spec, fitpars, sigpars
@spekinc.pro
;  Get pointers to the linear parameters to be fitted, and count how many:
   nlft = 0
   lftz = where(ctlz.fix_mask(ptrz.backgnd:ptrz.molecular) eq 0, nlft)
   if nlft eq 0 then return

;  Get pointers to the linear parameters fixed (unfitted) pars, and count how many:
   nfit = 0
   lfit = where(ctlz.fix_mask(ptrz.backgnd:ptrz.molecular) ne 0, nfit)

;  Remove the fixed terms from the model:
   lspec = obs_spec
   for jj = 0,nfit-1 do begin
      lspec   = lspec - fitpars(lfit(jj))*funz.basis(lfit(jj), *)
   endfor

;  And fit to what's left.  If its only one parameter, use direct analytic calculation.
;  If its more than one, use SVDFIT:
   if nlft eq 1 then begin
      fitpars(lftz) = total(lspec*funz.basis(lftz, *))/total(funz.basis(lftz, *) * funz.basis(lftz, *))
      sigpars(lftz) = sqrt(qalz.variance/total(funz.basis(lftz, *) * funz.basis(lftz, *)))
   endif else begin
      varvar  = fltarr(nlft)
      numsing = 0
      linpars = spek_svd(dimz.x, lspec, nlft, $
                         funct="spek_fun", $
                         weight=fltarr(dimz.npts) + 1./sqrt(qalz.variance), $
                         variance=varvar, $
                         singular=numsing)
      fitpars(lftz) = linpars
;      diag = indgen(nlft)
;      sigpars(lftz) = sqrt(abs(covmat(diag)))
       sigpars(lftz) = sqrt(abs(varvar))
   endelse

end

;==========================================================
;  This routine uses the Levenberg-Marquardt search to
;  generate a new estimate for the non-linear fit parameters:
pro spek_nln, obs_spec, fitpars, sigpars, species, cal
@spekinc.pro

;  Get pointers to the non-linear parameters to be fitted, and count how many:
   p0   = ptrz.position
   nlft = 0
   lftz = p0 + where(ctlz.fix_mask(ptrz.position:ptrz.temperature) eq 0, nlft)
   if nlft eq 0 then return
;  Check if we have only one non-linear parameter:
   if nlft eq 1 then begin
       alpha = total(funz.parderiv(lftz, *)*funz.parderiv(lftz, *))/qalz.variance
       beta  = total(funz.parderiv(lftz, *)*funz.residual)/qalz.variance
       delta = beta/alpha
       fitpars(lftz) = fitpars(lftz) + delta
       sigpars(lftz) = sqrt(1./alpha)
       spek_bas,  species, fitpars, cal  ; New basis fns for the new pars
       spekmodl,  obs_spec,fitpars       ; Evaluate fit function & residuals
       spek_chi                          ; Chi-squared at the new pars
   endif else begin
       oldfunz = funz
       oldqalz = qalz
       oldparz = fitpars
       lmiters = 0
       repeat begin
          lmiters = lmiters + 1
          funz    = oldfunz
          qalz    = oldqalz
          fitpars = oldparz
          spek_alph, alpha                  ; Evaluate the curvature matrix
          spek_beta, beta,    obs_spec      ; Evaluate the beta vector
          spek_dlta, alpha,   beta, $       ; Next fitpars estimate
                     delta,   fitpars
          spek_bas,  species, fitpars, cal  ; New basis fns for the new pars
          spekmodl,  obs_spec,fitpars       ; Evaluate fit function & residuals
          spek_chi                          ; Chi-squared at the new pars
          if qalz.chisq(qalz.iters) gt oldqalz.chisq(qalz.iters-1) then begin
		     ctlz.lmlambda = ctlz.lmlambda*2.
		     fitpars(ptrz.position:ptrz.temperature) = fitpars(ptrz.position:ptrz.temperature) - delta
                     spek_bas,  species, fitpars, cal  ; New basis fns for the new pars
                     spekmodl,  obs_spec,fitpars       ; Evaluate fit function & residuals
                     spek_chi                          ; Chi-squared at the new pars
          endif else ctlz.lmlambda = ctlz.lmlambda/4.
          if diagsel('nonlin_print_chi') then print, "LM chi: ", qalz.chisq(qalz.iters)
          if diagsel('nonlin_print_lambda') then begin
             print, 'Lambda: ', ctlz.lmlambda
          endif
          if diagsel('nonlin_print_pars') then begin ; Print latest parameter estimates?
             print, "PARS: ", fitpars
          endif
       endrep until lmiters gt 2 and $
	             (qalz.chisq(qalz.iters) lt oldqalz.chisq(qalz.iters-1) $
                 or lmiters gt 25)
   endelse
end

;==========================================================
;  Evaluates the unreduced chi-squared goodness of fit,
;  placing the result in qalz.chisq:
pro spek_chi
@spekinc.pro
   qalz.chisq(qalz.iters) = total(funz.residual^2)/qalz.variance
end

;==========================================================
;  Evaluates the curvature matrix with "variable diagonal
;  dominance":
pro spek_alph, alpha
@spekinc.pro
;   Get the number of parameters to search:
    p0   = ptrz.position
    nnln = ptrz.temperature - p0 + 1
;   Create the 2-D curvature matrix:
    alpha=fltarr(nnln, nnln)
    for i=ptrz.position,ptrz.temperature do begin
        for j=ptrz.position,ptrz.temperature do begin
            alpha(i-p0,j-p0) = total(funz.parderiv(i,*) * $
                                     funz.parderiv(j,*))
        endfor
    endfor
;   Enhance the diagonals by a factor of 1+ctlz.lmlambda:
;    diag  = indgen(nnln)
;    alpha(diag,diag) = alpha(diag,diag)*(1.+ctlz.lmlambda)
;   Scale by the variance:
    alpha = alpha/qalz.variance
    if diagsel('alpha_print_alpha') then begin
       print, 'Alpha: '
       print,  alpha
    endif
end

;==========================================================
;  Evaluate the deviation vector, beta:
pro spek_beta, beta, obs_spec
@spekinc.pro
    p0   = ptrz.position
    nnln = ptrz.temperature - p0 + 1
    beta = fltarr(nnln)
    for i=ptrz.position,ptrz.temperature do begin
        beta(i-p0) = total(funz.residual*funz.parderiv(i, *))
    endfor
    beta = beta/qalz.variance
    if diagsel('beta_print_beta') then begin
       print, 'Beta: '
       print,  beta
    endif
end

;==========================================================
;  Generate a new set of fitpars estimates:
pro spek_dlta, alpha, beta, delta, fitpars
common ranseed, seed
@spekinc.pro
    alpha = invert(alpha)
	dgnl  = indgen(2)*3
	alpha(dgnl) = alpha(dgnl)*(1+ctlz.lmlambda)
    delta = alpha#beta
;    delta = delta*(1 + ctlz.lmlambda/1.1)  ;#####
;---Do not allow unreasonably large parameter changes:
;    if abs(delta(0)) gt dimz.npts/2 then delta(0) = randomu(seed) - 0.5
;    if abs(delta(0)) gt dimz.npts/2 then delta(0) = 0.2*delta(0)*dimz.npts/(abs(delta(0))+0.1)
;    if abs(delta(1)) gt fitpars(ptrz.temperature)/2. then delta(1) = randomu(seed) - 0.5
;    if abs(delta(1)) gt fitpars(ptrz.temperature)/2. then delta(1) = 0.5*(delta(1)*fitpars(ptrz.temperature)/2.)/(abs(delta(1))+0.1)
    delta(0) = (delta(0) > dimz.npts/(-4.)) < dimz.npts/4.
    delta(1) = (delta(1) > fitpars(ptrz.temperature)/(-4.)) < fitpars(ptrz.temperature)/4.
    bads =  where(finite(delta) eq 0, badcount)
    if badcount gt 0 then delta(bads) = 10*(randomu(seed) - 0.5)
    fitpars(ptrz.position:ptrz.temperature) = fitpars(ptrz.position:ptrz.temperature) + delta
    if diagsel('delta_print_delta') then begin
       print, 'Delta: '
       print,  delta
     endif
end

;==========================================================
;  Generate estimates of the uncertainties in the parameters.
pro spek_sgma, sigpars
@spekinc.pro
       nnln   = 0
       sigsel = where(ctlz.fix_mask eq 0, nnln)
;      Create the 2-D curvature matrix:
       alpha=fltarr(nnln, nnln)
       for i=0,nnln-1 do begin
           for j=0,nnln-1 do begin
               alpha(i,j) = total(funz.parderiv(sigsel(i),*) * $
                                  funz.parderiv(sigsel(j),*))
           endfor
       endfor
;      Scale by the variance:
       alpha = alpha/qalz.variance
       if nnln gt 1 then begin
          alpha = invert(alpha)
          sigpars(sigsel) = $
            sqrt(alpha(indgen(nnln), indgen(nnln)))
        endif else begin
          sigpars(sigsel(0)) = sqrt(1./alpha(0,0))
        endelse

end

;==========================================================
;  This function returns TRUE if satisfactory convergence
;  has been achieved.
function spekdone, fitpars
@spekinc.pro
   if qalz.iters gt ctlz.max_iters then qalz.status = 'Exceeded iteration limit'
   if qalz.iters gt ctlz.max_iters then return, 1

   if ctlz.tol gt 0 then chitol = ctlz.tol else chitol = 0.000015*alog10((qalz.snr))*qalz.iters^1.2

   if qalz.iters lt   ctlz.min_iters  then return, 0
   if qalz.chisq(qalz.iters)/qalz.df gt 25 then return, 0
   if qalz.iters lt 2*ctlz.min_iters  and qalz.chisq(qalz.iters)/qalz.df gt 5 then return, 0
   if fitpars(ptrz.molecular)   lt 0. then return, 0


;   delchi = 0.5*(total(qalz.chisq(qalz.iters-4:qalz.iters-3)) - total(qalz.chisq(qalz.iters-2:qalz.iters-1)))
   result = moment(qalz.chisq((qalz.iters-8 > 0):qalz.iters), sdev=sigchi)
   sigchi = sqrt(sigchi)/qalz.df
   if sigchi gt chitol then return, 0
   if qalz.chisq(qalz.iters) - min(qalz.chisq(0:qalz.iters)) gt 2*sigchi then begin
      if qalz.warning eq 'None' then qalz.warning = "Final result was NOT the smallest chi-squared"$
      else qalz.warning = qalz.warning + ", Final result was NOT the smallest chi-squared"
   endif
   return, 1
end

;==========================================================
;  This routine attempts to determine if the search of the
;  chi-squared hypersurface has dropped into a bad local
;  minimum.  If so, it "warps" the search away by jumping
;  through the peak position  and temperature dimensions.
pro spekwarp, obs_spec, fitpars, species, cal, fix_mask
@spekinc.pro
    temtol = 25.
    bgtol  = .5*median(abs(obs_spec))
    if fix_mask(ptrz.temperature) then temtol = 0.01
    bads =  where(finite(fitpars) eq 0, badcount)
    bad_hole = qalz.iters gt 5 and $
                                 badcount gt 0 or $
               (fitpars(ptrz.molecular)   lt 0. or $
                fitpars(ptrz.temperature) lt temtol or $
                fitpars(ptrz.backgnd)     lt -bgtol)
    if bad_hole then begin
       fitpars(ptrz.temperature) = 600.
       fitpars(ptrz.position) = fitpars(ptrz.position) + (0.5-randomu(systime(1)/qalz.chisq(qalz.iters)))*dimz.npts
       while fitpars(ptrz.position) gt  dimz.npts/2. do fitpars(ptrz.position) = fitpars(ptrz.position) - dimz.npts
       while fitpars(ptrz.position) lt -dimz.npts/2. do fitpars(ptrz.position) = fitpars(ptrz.position) + dimz.npts
       while fitpars(ptrz.position) gt dimz.npts do $
          fitpars(ptrz.position) = fitpars(ptrz.position) - dimz.npts
       spek_bas,  species, fitpars, cal  ; New basis fns for the new pars
       spekmodl,  obs_spec,fitpars       ; Evaluate fit function & residuals
       spek_chi                          ; Chi-squared at the new pars
       qalz.warning = 'Invoked WARP, to escape a local chi-squared minimum'
    endif
    if fitpars(ptrz.temperature) gt 3000. then begin
       fitpars(ptrz.temperature) = 700.
    endif
end

;==========================================================
;  Initialize data items passed via common:
pro spekinit, species, obs_spec, fitpars, insprof, diagz, fix_mask, passive, min_iters, max_iters, tolerance
@spekinc.pro

   ptrz = {s_ptr, backgnd:  0, $
                  aerosol:  1, $
                  molecular:2, $
                  position: 3, $
                  temperature: 4}
   nlft = 0
   lftz = where(fix_mask(ptrz.backgnd:ptrz.molecular) eq 0, nlft)
   npts = n_elements(obs_spec)

   dimz = {s_dim, x:        indgen(npts), $
                  xx:       (indgen(npts)-npts/2), $
                  npts:     npts, $
                  npars:    n_elements(fitpars), $
                  nspecies: n_elements(species)}

   namz = {s_nam, parz: ['Background', $
                          'Aerosol', $
                          'Molecular', $
                          'Position', $
                          'Temperature']}

   ctlz = {s_ctl, fix_mask: fix_mask, $
                  alg_mask: intarr(dimz.npars), $
                  diagz:    strupcase(diagz), $
                  iter:     0, $
                  newpars:  1, $
                  secwait:  0.001, $
                  delta:    fltarr(dimz.npars - ptrz.molecular - 1), $
                  lmlambda: 0.05, $
                  min_iters:min_iters, $
                  max_iters:max_iters, $
                  passive:  passive, $
                  tol:      tolerance}

   funz = {s_fun, basis:    fltarr(dimz.npars, dimz.npts), $
                  parderiv: fltarr(dimz.npars, dimz.npts), $
                  fitfunc:  fltarr(dimz.npts), $
                  residual: fltarr(dimz.npts), $
                  insderiv: complexarr(dimz.npts), $
                  molebas:  fltarr(dimz.nspecies, dimz.npts), $
                  molewid:  fltarr(dimz.nspecies), $
                  ftinsp:   complexarr(dimz.npts), $
                  nrm: 0.}

   qalz = {s_qal, chisq:    fltarr(2400), $
                  fitfunc:  fltarr(dimz.npts), $
                  variance: 0., $
                  snr:      0., $
                  df:       dimz.npts - dimz.npars, $
                  iters:    0, $
                  warning:  'None', $
                  status:   'OK', $
                  version:  'SPEK_FIT version 1.3 by Mark Conde, Fairbanks, October 2001.'}

;  Save the number of data points, for use in
;  routines that haven't got easy access to it:
   ncn2        = dimz.npts/2
   ncn4        = dimz.npts/4

;  Compute the insprof Fourier transform, and normalize
;  to unit height (###need to work on that!):
   funz.ftinsp   = fft (insprof/max(insprof), -1)
;   nrm           = abs(funz.ftinsp(0))
;   funz.ftinsp   = funz.ftinsp/nrm

;  Compute the first derivative of the insprof w.r.t. channel number,
;  using the Fourier derivative theorem:
   npts = dimz.npts
   phasor = findgen(npts)/npts
   phasor(npts/2+1:npts-1) = reverse(-phasor(1:npts/2-1))
   phasor = complex(0., 2.*!pi*phasor)
   funz.insderiv = funz.ftinsp*phasor

;  Compute the variance of the points in the observed spectrum:
   ftspec = fft(obs_spec, -1)
   pd     = float(abs(ftspec*conj(ftspec)))
   mnp    = total(pd(ncn4:ncn2))/(ncn2 - ncn4 + 1)
   noisep = (mnp + 2*median(pd(ncn4:ncn2)))/3
   qalz.variance = sqrt(2)*noisep*dimz.npts

;  Compute the signal/noise ratio:
   if noisep gt 0 then qalz.snr = pd(1)/noisep $
      else             qalz.snr = -1.

;  Ensure the relative brightness coefficients for the species
;  add to 1:
   species(*).relint = species(*).relint/total(species(*).relint)

;  Correct the degrees of freedom for fixed parameters:
   nf = 0
   fixed = where(ctlz.fix_mask ne 0, nf)
   qalz.df = qalz.df + nf

   if diagsel('init_print_common') then begin
      help, dimz, /structure
      help, ptrz, /structure
      help, ctlz, /structure
      help, funz, /structure
      help, qalz, /structure
   endif

end

