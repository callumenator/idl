;========================================
; An image smoothing routine that allows
; for edge effects

function mc_im_sm, image, width, nomedian=nomedian, gaussian=gaussian
    nx  = n_elements(image(*,0))
    ny  = n_elements(image(0,*))
    if ny gt 1 then begin
       pad = fltarr(nx + 2*width, ny+2*width)
       pad(width:width+nx-1, width:width+ny-1) = image
       for j=1,width do begin
	   pad(width-j,width:width+ny-1)         = 2.*pad(width, width:width+ny-1) - pad(width+j, width:width+ny-1)
	   pad(nx+width+j-1,width:width+ny-1)    = 2.*pad(nx+width-1, width:width+ny-1) - pad(nx+width-j-1, width:width+ny-1)
	   pad(width:width+nx-1,width-j)      = 2.*pad(width:width+nx-1,width) - pad(width:width+nx-1,width+j)
	   pad(width:width+nx-1,ny+width+j-1) = 2.*pad(width:width+nx-1, ny+width-1) - pad(width:width+nx-1, ny+width-j-1)
	   for k=1,j do begin
	       pad(width-j,width-k)           = pad(width-j,width)
	       pad(nx+width+j-1,width-k)      = pad(nx+width+j-1, width)
	       pad(width-j,ny+width+k-1)      = pad(width-j,ny)
	       pad(nx+width+j-1,ny+width+k-1) = pad(nx+width+j-1, ny)

	       pad(width-k,width-j)           = pad(width,width-j)
	       pad(nx+width+k-1,width-j)      = pad(nx+width-1, width-j)
	       pad(width-k,ny+width+j-1)      = pad(width,ny+j+1)
	       pad(nx+width+k-1,ny+width+j-1) = pad(nx+width-1, ny+j-1)
	   endfor
       endfor
    endif else begin
       pad = fltarr(nx + 2*width)
       pad(width:width+nx-1) = image
       for j=1,width do begin
	   pad(width-j)         = 2.*pad(width) - pad(width+j)
	   pad(nx+width+j-1)    = 2.*pad(nx+width-1) - pad(nx+width-j-1)
       endfor
    endelse
    
    nnx  = n_elements(pad(*,0))
    nny  = n_elements(pad(0,*))

    if ny ne 1 then begin
       if not(keyword_set(nomedian)) then pad = median(pad, 3)
       if keyword_set(gaussian) then begin
          nk = min([nnx, nny])
          kernel = shift(dist(nk), nk/2, nk/2)
          kernel = exp(-(kernel/width)^2)
          pk     = fltarr(nnx, nny)
          pk(0:nk-1, 0:nk-1) = kernel
          itot = total(pad)
        
          ftimg = fft(pad)*abs(fft(pk))
          pad   = float(fft(ftimg, /inverse))
          ptot   = total(pad) 
          pad   = pad*itot/ptot
       endif else pad = smooth(pad, width)
       return, pad(width:width+nx-1, width:width+ny-1)
    endif else begin
;       pad = pad(*, width:width+ny-1)
       if not(keyword_set(nomedian)) then pad = median(pad, 3)
       if keyword_set(gaussian) then begin
          kernel = findgen(n_elements(pad)) - n_elements(pad)/2.
          pk     = exp(-(kernel/width)^2)
          itot = total(pad)
          ftimg = fft(pad)*abs(fft(pk))
          pad   = float(fft(ftimg, /inverse))
          ptot   = total(pad) 
          pad   = pad*itot/ptot
       endif else pad = smooth(pad, width)
       return, pad(width:width+nx-1)
    endelse
end