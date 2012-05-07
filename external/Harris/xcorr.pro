;+
; NAME:			XCORR
;
; PURPOSE:		Perform cross-correlation without using FFT
;
; CATEGORY:		Time-Series/Spectral analysis
;
; CALLING SEQUENCE:	xcorr, tdata1, tdata2, normal_factor=nf, maxval=maxval
;
; INPUTS:		tdata1,tdata2 = (Complex) vectors containing the 
;					time series
;   KEYWORD PARAMETERS:	
;			MAXVAL 	      = values larger than this are 
;					considered as bad data and are ignored
;
; OUTPUTS:
;   KEYWORD PARAMETERS:	
;			NORMAL_FACTOR = the normalisation factor used. 
;					This allows the user to recreate the  
;					Covariance function
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-
;------------------------------------------------------------------
	function xcorr, tdata1, tdata2, normal_factor=nf, maxval=maxval

; IDL function which returns the cross correlation from the input
; arrays tdata1 and tdata2
; If n is positive then tdata1 is moved forward of tdata2. 
; eg: if n is 1, then what was tdata1[0] now corresponds to tdata2[1].

    nf = 0
    cor = 0.0

	if (not keyword_set(maxval)) then maxval = max(tdata1)+10.0

    xi=n_elements(tdata1)
    yi=n_elements(tdata2)
    if xi ne yi then $
    begin
        message,'Arrays must have same no. of elements.',/info
        goto,finish
    endif

; Do a cross correlation:

for lag = -0.5*xi, 0.5*xi-1 do begin
    xs 	= shift(tdata1,lag)
    xs 	= xs((lag>0):xi-1+(lag<0))
    ys 	= tdata2((lag>0):yi-1+(lag<0))
    goodpts = where(xs lt maxval,count)
    xav	= total(xs(goodpts))/count
    yav	= total(ys(goodpts))/count
    xn	= complex(xs(goodpts)-xav)
    yn	= complex(ys(goodpts)-yav)
    cor = [cor, total( conj(xn)*yn )/count]
endfor

xs = tdata1	&	ys = tdata2
goodpts = where(xs lt maxval,count)
xav	= total(xs(goodpts))/count
yav	= total(ys(goodpts))/count
xn	= complex(xs(goodpts)-xav)
yn	= complex(ys(goodpts)-yav)
nf 	= sqrt( abs(total( conj(xn)*xn ))*abs(total( conj(yn)*yn )) )

cor = cor(1:*)/nf * xi

finish:
    return,cor
end



