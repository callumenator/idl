;=================================================================================================
;
;+
; NAME:
;       Polywind
; PURPOSE:
;       This routine fits a horizontal vector wind field
;       to multi-station FPS wind data.  The fit is a 2 or 3-D polynomial
;       field, with polynomial terms up to the order specified by the
;       "order" parameter.
; CALLING:
;       Polywind, los_obs, sigobs,     obs_x,    obs_y,   view_azi,  view_zen,  order, $
;                 zonal,   meridional, vertical, sigzon,  sigmer,    sigver,    quality, $
;                 radians=radz, horizontal_only=hozo
; INPUTS:
;       los_obs:     A 1-D array of line-of-sight horizontal wind observations, positive away.
;       sigobs:      A 1-D array containing the measurement uncertainties in los_obs.
;       obs_x:       A 1-D array containing the x (longitudinal) displacement (in km) of the observed
;                    locations, relative to some convenient origin point.
;       obs_y:       A 1-D array containing the y (latitudinal)  displacement (in km) of the observed
;                    locations, relative to the same origin point.
;       view_azi:    A 1-D array containing the observing azimuth toward each observed
;                    location (eg 0 for a NORTH observation, 90 for an EAST observation, etc).
;                    The units (degrees or radians) depend on the "radians" keyword.
;       view_zen:    A 1-D array containing the observing zenith angle toward each observed
;                    location. The units (degrees or radians) depend on the "radians" keyword.
;       order:       The order of the polynomial fit (1 for a linear fit).
; OUTPUTS:
;       zonal:       A 1-D array of coefficients of the zonal wind.  Array elements are
;                    0 - the uniform wind
;                    1 - the first order variation in the zonal direction
;                    2 - the first order variation in the meridional direction
;                    3 - the second order variation in the zonal direction
;                    4 - the second order variation in the meridional direction
;                    .... etc...
;       meridional:  A 1-D array of coefficients of the meridional wind, with the same structure as
;                    the zonal coefficient array.
;       vertical:    A 1-D array of coefficients of the vertical wind, with the same structure as
;                    the zonal coefficient array.
;       sigzon:      A 1-D array of uncertainties in zonal coefficients.
;       sigmer:      A 1-D array of uncertainties in meridional coefficients.
;       sigver:      A 1-D array of uncertainties in vertical coefficients.
;       quality:     A structure describing the quality of the fit.  Fields in the structure are:
;                    chisq:    The reduced chi-squared parameter of the fit.
;                    df:       The number of statistical degrees of freedom of the fit.
;                    los_fit:  A 1-D array, of the same size as los_obs, containing the fitted
;                              line-of-sight wind estimates.
;                    singular: The number of singular values encountered by SVDFIT (should
;                              be zero for a good fit).
; KEYWORDS:
;       radians:     If set, this indicates that view_azi and view_zen are already in radians,
;                    and do not need converting.
;       horizontal_only: If this keyword is set, the fit will only consider horizontal wind components.
;                    Otherwise, coefficients for the vertical wind are calculated, along with their
;                    corresponding uncertainties.
; PROCEDURE:
;       Chi-squared minimization using singular-value decomposition.
; HISTORY:
;       Written by Mark Conde, Bromley, August 1999.
;-
;
;==============================================================================

function wnd_func, obsidx, nterms
    common wndcom, basis
    return, basis(obsidx,*)
end

pro wnd_basis, obs_x, obs_y, obs_azi, obs_zen, nobs, order, vertz
    common wndcom, basis

    for i = 0,nobs-1 do begin
;       Do the zeroth order (uniform wind) separately:
        basis(i, 0) = sin(obs_azi(i))*sin(obs_zen(i))
        basis(i, 1) = cos(obs_azi(i))*sin(obs_zen(i))
        if vertz then basis(i, 2) = cos(obs_zen(i))

;       Now do the spatially varying wind terms:
        for j = 1,order do begin
            k = (vertz + 2)*(1 + 2*(j - 1))
;           Calculate the basis functions for variations in x:
            basis(i, k  ) = sin(obs_azi(i))*sin(obs_zen(i))*(obs_x(i))^j
            basis(i, k+1) = cos(obs_azi(i))*sin(obs_zen(i))*(obs_x(i))^j
            if vertz then   basis(i, k+2) = cos(obs_zen(i))*(obs_x(i))^j
;           Calculate the basis functions for variations in y:
            basis(i, k+vertz+2) = sin(obs_azi(i))*sin(obs_zen(i))*(obs_y(i))^j
            basis(i, k+vertz+3) = cos(obs_azi(i))*sin(obs_zen(i))*(obs_y(i))^j
            if vertz then   basis(i, k+vertz+4) = cos(obs_zen(i))*(obs_y(i))^j
        endfor
    endfor
end

pro polywind, los_obs, sigobs,     obs_x,    obs_y,   view_azi, view_zen, order, $
              zonal,   meridional, vertical, sigzon,  sigmer,   sigver,   quality, $
              radians=radz, horizontal_only=hozo
    common wndcom, basis

    obs_azi = view_azi
    obs_zen = view_zen
    if not(keyword_set(radz)) then obs_azi = !pi*obs_azi/180.
    if not(keyword_set(radz)) then obs_zen = !pi*obs_zen/180.
    if keyword_set(hozo) then vertz=0 else vertz=1

    nobs    = n_elements(los_obs)
    nterms  = (vertz + 2)*(2*order + 1)
    df      = nobs - nterms
    basis   = fltarr(nobs, nterms)

;   Generate the basis functions:
    wnd_basis, obs_x, obs_y, obs_azi, obs_zen, nobs, order, vertz

;   Now fit the parameters:
    varpars = fltarr(nterms)
    numsing = 0
    los_fit = fltarr(nobs)
    fitpars = svdfit(findgen(nobs), los_obs, nterms, $
                     funct="wnd_func", $
                     weight=fltarr(nobs) + 1./sigobs, $
                     variance=varpars, $
                     singular=numsing, $
                     yfit=los_fit)

     zonal      = fltarr(nterms/(vertz+2))
     meridional = fltarr(nterms/(vertz+2))
     vertical   = fltarr(nterms/(vertz+2))
     sigzon     = fltarr(nterms/(vertz+2))
     sigmer     = fltarr(nterms/(vertz+2))
     sigver     = fltarr(nterms/(vertz+2))

;    Populate the parameter estimates and uncertainties for uniform wind terms:
     zonal(0)     = fitpars(0)
     meridional(0)= fitpars(1)
     if vertz then vertical(0) = fitpars(2)

     sigzon(0)    = sqrt(varpars(0))
     sigmer(0)    = sqrt(varpars(1))
     if vertz then sigver(0)   = varpars(2)

;    Now do the parameters and uncertainties for the spatially varying wind terms:
     for j = 1,order do begin
          k = (vertz + 2)*(1 + 2*(j - 1))
;         Extract the coefficients for variations in x:
          zonal(1 + 2*(j-1))      = fitpars(k)
          meridional(1 + 2*(j-1)) = fitpars(k+1)
          if vertz then vertical(1 + 2*(j-1)) = fitpars(k+2)

;         Extract the coefficients for variations in y:
          zonal(2 + 2*(j-1))      = fitpars(k+vertz+2)
          meridional(2 + 2*(j-1)) = fitpars(k+vertz+3)
          if vertz then vertical(2 + 2*(j-1)) = fitpars(k+vertz+4)

;         Extract the uncertainties in coefficients for variations in x:
          sigzon(1 + 2*(j-1)) = sqrt(varpars(k))
          sigmer(1 + 2*(j-1)) = sqrt(varpars(k+1))
          if vertz then sigver(1 + 2*(j-1)) = sqrt(varpars(k+2))

;         Extract the uncertainties in coefficients for variations in y:
          sigzon(2 + 2*(j-1)) = sqrt(varpars(k+vertz+2))
          sigmer(2 + 2*(j-1)) = sqrt(varpars(k+vertz+3))
          if vertz then sigver(2 + 2*(j-1)) = sqrt(varpars(k+vertz+4))
     endfor

;    Finally, build the structure to return fit quality info:
     resid     = los_obs - los_fit
     chisq     = total((resid/sigobs)^2)/df
     quality   = {chisq: chisq, df: df, los_fit: fltarr(n_elements(los_fit)), singular: numsing}
     quality.los_fit(0:n_elements(los_fit)-1) = los_fit
end
