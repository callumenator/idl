;==========================================================
;
;  This file contains some spectral analysis utility
;  routines.  It is designed to be included as needed
;  in other analysis programs.  The parameters passed
;  are all simple scalars or arrays - no fancy data
;  structures are needed.  Further, nothing is passed
;  through common.
;
;  Mark Conde, Kingston, July 1998

;==========================================================
;  Given array dimensions m and n, return two (m x n) arrays,
;  ii and jj, such that ii(i,j) = i and jj(i,j) = j
pro idx_2d, i, j, ii, jj
    jj = indgen(m,n)/m
    ii = transpose(indgen(n,m)/n)
end

;==========================================================
;  Given ftsrc, the fourier transform of some source function,
;  return the fourier transform of that function shifted
;  x_shift channels in the positive x direction:
function spekfshf, ftsrc, x_shift
   npts = n_elements(ftsrc)
   phasor = findgen(npts)/npts
   phasor(npts/2+1:npts-1) = reverse(-phasor(1:npts/2-1))
   phasor = complex(0., -2.*!pi*x_shift*phasor)
   return, ftsrc*exp(phasor)
end

;==========================================================
;  Given a vector list of values, valz, return the standard
;  deviation of the list:
function standev, valz
   npts = n_elements(valz)
   var  = (total(valz*valz) - (1./npts)*(total(valz))^2 )*(1./(npts - 1))
   return, sqrt(var)
end

;==========================================================
;  Given the Fourier transform, ftx, of a real function,
;  return that real function:
function ftdrl, ftx
   return, float(fft(ftx, 1))
end

;==========================================================
;  Return the spectral width, in scan channels, of an
;  emission given temperature, mass, wavelength, and
;  wavelength increment per channel:
function spek_wdt, temperature, amass, nominal_lambda, delta_lambda, divisor
   if temperature lt 0. then temperature = 0.1
;   f1    = 3.07238644d-40  ; (=2k/c^2)
   f1    = 1.5362d-40  ; (=k/c^2)
   amu   = 1.66053e-27
   width = nominal_lambda*sqrt(2.*f1*temperature/(amass*amu))
   width = float(width/delta_lambda)
   return, width/divisor
end

;==========================================================
;   This routine generates the Fourier transform of a Gaussian
;   function with npts signal-domain points, and signal domain
;   position, width and height as specified by the input parameters.
;   Two possible methods are used.  If width/npts < 0.15, the
;   Gaussian is generated directly in the transform domain.  If
;   width/npts >= 0.15, it is generated in the signal domain
;   and then transformed.

pro spekfgau, npts, position, width, magnitude, gauft, area=area
    if width/float(npts) lt 0.15 then begin
       f1     = npts/!pi
       ftpos  = 2*position/f1
       ftwid  = (width/f1)^2

       gauft  = findgen(npts)
       gauft  = complex(ftwid*gauft*gauft, ftpos*gauft)
       gauft  = (magnitude*width*sqrt(!pi)/npts)*exp(-gauft)
       gauft(npts-npts/2:npts-1) = conj(reverse(gauft(1:npts/2)))
    endif else begin
       x      = findgen(npts)
       g      = exp(-((x-npts/2)/width)^2)
       g      = magnitude*g
       gauft  = fft(g, -1)
       gauft  = spekfshf(gauft, position-npts/2)
    endelse
    if keyword_set(area) then gauft = magnitude*gauft/gauft(0) ;####################
end

