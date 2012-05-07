;=======================================================================================
;	this program is for remotely cleaning and analyzing the raw images
;	from the trailer FPS in Inuvik, using Mark's spectra-generation and
;	spectra-fitting routines.
;
;	Matt Krynicki, 11-14-01.
;=======================================================================================

;=======================================================================================
;	this subroutine takes the time values, which are in a decimal format (float),
;	and removes the	actual decimal point, leaving it in an HOURDECIMAL format.
;	this new time format is used in the end result .DBT data files, compatible with
;	Roger's other FPS data formats
;=======================================================================================

pro fixtime, thetime

	inbtw=strcompress(thetime,/remove_all)

	if thetime lt 10. then begin
	  hr=strmid(inbtw,0,1)
	  dec=strmid(inbtw,2,2)
	endif else begin
	  hr=strmid(inbtw,0,2)
	  dec=strmid(inbtw,3,2)
	endelse

	thetime=hr+dec
	thetime=fix(thetime)

return
end

;=======================================================================================
;   A simple spike remover for laser images.
;   Mark Conde, Fairbanks, Feb 2002.
pro mclascleaner, isig, isignew
    isignew = isig
    nbad = 0

;---First, fix really big blotches:
    medsig = median(isig, 7)
    difsig = abs(isig - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 5., nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---Then look closer:
    medsig = median(isig, 5)
    difsig = abs(isig - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.8, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---And now very fussy:
    medsig = median(isig, 3)
    difsig = abs(isig - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.4, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)
end

;=======================================================================================
;	the following subroutines clean each image, i.e., remove "salt'n'pepper" spikes,
;	before the image is reduced to a spectrum.  the routines look ridiculous but are
;	actually quite robust and do a thorough job.
;=======================================================================================

pro docleansky, isig, isignew

	for i=0,255 do begin

	   for j=0,254 do begin

		  if (i eq 0) then begin
			call_procedure,'doskyizero',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 0) then goto, nexti

		  if (i eq 1) then begin
			call_procedure,'doskyione',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 1) then goto, nexti

		  if (i eq 2) then begin
			call_procedure,'doskyitwo',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 2) then goto, nexti

		  if (i eq 253) then begin
			call_procedure,'doskyithree',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 253) then goto, nexti

		  if (i eq 254) then begin
			call_procedure,'doskyifour',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 254) then goto, nexti

		  if (i eq 255) then begin
			call_procedure,'doskyifive',i,j,isig,isignew
			if (j ne 254) then goto, nextj
		  endif
		  if (i eq 255) then goto, nexti

		  if (j eq 0) then begin
			if (isig(i,j) gt (isig(i,j+1)+50)) or $
			   (isig(i,j) gt (isig(i,j+2)+50)) or $
			   (isig(i,j) gt (isig(i,j+3)+50)) or $
			   (isig(i,j) gt (isig(i,j+4)+50)) or $
			   (isig(i,j) gt (isig(i,j+5)+50)) or $
			   (isig(i,j) gt (isig(i,j+6)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j+1),$
					    isig(i,j+2),isig(i,j+3),isig(i,j+4),$
					    isig(i,j+5),isig(i,j+6)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 0) then goto, nextj

		  if (j eq 1) then begin
			if (isig(i,j) gt (isig(i,j-1)+50)) or $
			   (isig(i,j) gt (isig(i,j+1)+50)) or $
			   (isig(i,j) gt (isig(i,j+2)+50)) or $
			   (isig(i,j) gt (isig(i,j+3)+50)) or $
			   (isig(i,j) gt (isig(i,j+4)+50)) or $
			   (isig(i,j) gt (isig(i,j+5)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j+1),$
					    isig(i,j+2),isig(i,j+3),isig(i,j+4),$
					    isig(i,j+5),isig(i,j-1)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 1) then goto, nextj

		  if (j eq 2) then begin
			if (isig(i,j) gt (isig(i,j-1)+50)) or $
			   (isig(i,j) gt (isig(i,j-2)+50)) or $
			   (isig(i,j) gt (isig(i,j+1)+50)) or $
			   (isig(i,j) gt (isig(i,j+2)+50)) or $
			   (isig(i,j) gt (isig(i,j+3)+50)) or $
			   (isig(i,j) gt (isig(i,j+4)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j+1),$
					    isig(i,j+2),isig(i,j+3),isig(i,j+4),$
					    isig(i,j-1),isig(i,j-2)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 2) then goto, nextj

		  if (j eq 252) then begin
			if (isig(i,j) gt (isig(i,j+1)+50)) or $
			   (isig(i,j) gt (isig(i,j+2)+50)) or $
			   (isig(i,j) gt (isig(i,j-1)+50)) or $
			   (isig(i,j) gt (isig(i,j-2)+50)) or $
			   (isig(i,j) gt (isig(i,j-3)+50)) or $
			   (isig(i,j) gt (isig(i,j-4)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j+1),$
					    isig(i,j+2),isig(i,j-1),isig(i,j-2),$
					    isig(i,j-3),isig(i,j-4)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 252) then goto, nextj

		  if (j eq 253) then begin
			if (isig(i,j) gt (isig(i,j+1)+50)) or $
			   (isig(i,j) gt (isig(i,j-1)+50)) or $
			   (isig(i,j) gt (isig(i,j-2)+50)) or $
			   (isig(i,j) gt (isig(i,j-3)+50)) or $
			   (isig(i,j) gt (isig(i,j-4)+50)) or $
			   (isig(i,j) gt (isig(i,j-5)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j-1),$
					    isig(i,j-2),isig(i,j-3),isig(i,j-4),$
					    isig(i,j-5),isig(i,j+1)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 253) then goto, nextj

		  if (j eq 254) then begin
			if (isig(i,j) gt (isig(i,j-1)+50)) or $
			   (isig(i,j) gt (isig(i,j-2)+50)) or $
			   (isig(i,j) gt (isig(i,j-3)+50)) or $
			   (isig(i,j) gt (isig(i,j-4)+50)) or $
			   (isig(i,j) gt (isig(i,j-5)+50)) or $
			   (isig(i,j) gt (isig(i,j-6)+50)) or $
			   (isig(i,j) gt (isig(i+1,j)+50)) or $
			   (isig(i,j) gt (isig(i+2,j)+50)) or $
			   (isig(i,j) gt (isig(i+3,j)+50)) or $
			   (isig(i,j) gt (isig(i-1,j)+50)) or $
			   (isig(i,j) gt (isig(i-2,j)+50)) or $
			   (isig(i,j) gt (isig(i-3,j)+50)) then begin
				isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
					    isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j-1),$
					    isig(i,j-2),isig(i,j-3),isig(i,j-4),$
					    isig(i,j-5),isig(i,j-6)]
				isignew(i,j)=median(isiginbt)
			endif else begin
				isignew(i,j)=isig(i,j)
			endelse
		  endif
		  if (j eq 254) then goto, nextj

		  if (isig(i,j) gt (isig(i,j+1)+50)) or $
			 (isig(i,j) gt (isig(i,j+2)+50)) or $
			 (isig(i,j) gt (isig(i,j+3)+50)) or $
			 (isig(i,j) gt (isig(i,j-1)+50)) or $
			 (isig(i,j) gt (isig(i,j-2)+50)) or $
			 (isig(i,j) gt (isig(i,j-3)+50)) or $
			 (isig(i,j) gt (isig(i+1,j)+50)) or $
			 (isig(i,j) gt (isig(i+2,j)+50)) or $
			 (isig(i,j) gt (isig(i+3,j)+50)) or $
			 (isig(i,j) gt (isig(i-1,j)+50)) or $
			 (isig(i,j) gt (isig(i-2,j)+50)) or $
			 (isig(i,j) gt (isig(i-3,j)+50)) then begin
			  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
				      isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i,j+1),$
				      isig(i,j+2),isig(i,j+3),isig(i,j-1),$
				      isig(i,j-2),isig(i,j-3)]
			  isignew(i,j)=median(isiginbt)
		  endif else begin
			  isignew(i,j)=isig(i,j)
		  endelse

	   nextj:
	   endfor

	nexti:
	endfor

return

end

;--this sub takes care of i=0 for sky images

pro doskyizero,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j-1),$
			      isig(i,j+1),isig(i,j+2),isig(i,j+3),$
			      isig(i,j+4),isig(i,j+5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j+1),isig(i,j+2),$
			      isig(i,j+3),isig(i,j+4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j+1),$
			      isig(i,j-1),isig(i,j-2),isig(i,j-3),$
			      isig(i,j-4),isig(i,j-5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) or $
		 (isig(i,j) gt (isig(i+6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
		  	      isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i+1,j)+50)) or $
	   (isig(i,j) gt (isig(i+2,j)+50)) or $
	   (isig(i,j) gt (isig(i+3,j)+50)) or $
	   (isig(i,j) gt (isig(i+4,j)+50)) or $
	   (isig(i,j) gt (isig(i+5,j)+50)) or $
	   (isig(i,j) gt (isig(i+6,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
			    isig(i+4,j),isig(i+5,j),isig(i+6,j),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj:

return

end

;--this sub takes care of i=1 for sky images

pro doskyione,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj1

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j-1),$
			      isig(i,j+1),isig(i,j+2),isig(i,j+3),$
			      isig(i,j+4),isig(i,j+5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj1

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j+1),isig(i,j+2),$
			      isig(i,j+3),isig(i,j+4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj1

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj1

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j+1),$
			      isig(i,j-1),isig(i,j-2),isig(i,j-3),$
			      isig(i,j-4),isig(i,j-5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj1

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) or $
		 (isig(i,j) gt (isig(i+5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
		  	      isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj1

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i-1,j)+50)) or $
	   (isig(i,j) gt (isig(i+1,j)+50)) or $
	   (isig(i,j) gt (isig(i+2,j)+50)) or $
	   (isig(i,j) gt (isig(i+3,j)+50)) or $
	   (isig(i,j) gt (isig(i+4,j)+50)) or $
	   (isig(i,j) gt (isig(i+5,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),$
			    isig(i+3,j),isig(i+4,j),isig(i+5,j),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj1:

return

end

;--this sub takes care of i=2 for sky images

pro doskyitwo,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj2

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j-1)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj2

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j-1),isig(i,j-2)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj2

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj2

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			      isig(i,j-1),isig(i,j-2),isig(i,j-3),$
			      isig(i,j-4),isig(i,j-5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj2

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i+3,j)+50)) or $
		 (isig(i,j) gt (isig(i+4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
		  	      isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj2

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i-1,j)+50)) or $
	   (isig(i,j) gt (isig(i-2,j)+50)) or $
	   (isig(i,j) gt (isig(i+1,j)+50)) or $
	   (isig(i,j) gt (isig(i+2,j)+50)) or $
	   (isig(i,j) gt (isig(i+3,j)+50)) or $
	   (isig(i,j) gt (isig(i+4,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),$
			    isig(i+2,j),isig(i+3,j),isig(i+4,j),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj2:

return

end

;--this sub takes care of i=253 for sky images

pro doskyithree,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj3

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j-1)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj3

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j-1),isig(i,j-2)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj3

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj3

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			      isig(i,j-1),isig(i,j-2),isig(i,j-3),$
			      isig(i,j-4),isig(i,j-5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj3

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i+2,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
		  	      isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj3

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i+1,j)+50)) or $
	   (isig(i,j) gt (isig(i+2,j)+50)) or $
	   (isig(i,j) gt (isig(i-1,j)+50)) or $
	   (isig(i,j) gt (isig(i-2,j)+50)) or $
	   (isig(i,j) gt (isig(i-3,j)+50)) or $
	   (isig(i,j) gt (isig(i-4,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),$
			    isig(i-2,j),isig(i-3,j),isig(i-4,j),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj3:

return

end

;--this sub takes care of i=254 for sky images

pro doskyifour,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj4

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j-1)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj4

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j-1),isig(i,j-2)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj4

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj4

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			      isig(i,j-1),isig(i,j-2),isig(i,j-3),$
			      isig(i,j-4),isig(i,j-5)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj4

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i+1,j)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
		  	      isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj4

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i+1,j)+50)) or $
	   (isig(i,j) gt (isig(i-1,j)+50)) or $
	   (isig(i,j) gt (isig(i-2,j)+50)) or $
	   (isig(i,j) gt (isig(i-3,j)+50)) or $
	   (isig(i,j) gt (isig(i-4,j)+50)) or $
	   (isig(i,j) gt (isig(i-5,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),$
			    isig(i-3,j),isig(i-4,j),isig(i-5,j),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj4:

return

end

;--this sub takes care of i=255 for sky images

pro doskyifive,i,j,isig,isignew

	if (j eq 0) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i,j+6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
		 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j+6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 0) then goto, thenextj5

	if (j eq 1) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i,j+5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
	 	 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j+5),isig(i,j-1)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 1) then goto, thenextj5

	if (j eq 2) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j+3)+50)) or $
		 (isig(i,j) gt (isig(i,j+4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
		 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j+3),isig(i,j+4),$
			      isig(i,j-1),isig(i,j-2)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 2) then goto, thenextj5

	if (j eq 252) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j+2)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
		 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j+1),$
			      isig(i,j+2),isig(i,j-1),isig(i,j-2),$
			      isig(i,j-3),isig(i,j-4)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 252) then goto, thenextj5

	if (j eq 253) then begin
	  if (isig(i,j) gt (isig(i,j+1)+50)) or $
		 (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
		 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j+1)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 253) then goto, thenextj5

	if (j eq 254) then begin
	  if (isig(i,j) gt (isig(i,j-1)+50)) or $
		 (isig(i,j) gt (isig(i,j-2)+50)) or $
		 (isig(i,j) gt (isig(i,j-3)+50)) or $
		 (isig(i,j) gt (isig(i,j-4)+50)) or $
		 (isig(i,j) gt (isig(i,j-5)+50)) or $
		 (isig(i,j) gt (isig(i,j-6)+50)) or $
		 (isig(i,j) gt (isig(i-1,j)+50)) or $
		 (isig(i,j) gt (isig(i-2,j)+50)) or $
		 (isig(i,j) gt (isig(i-3,j)+50)) or $
		 (isig(i,j) gt (isig(i-4,j)+50)) or $
		 (isig(i,j) gt (isig(i-5,j)+50)) or $
		 (isig(i,j) gt (isig(i-6,j)+50)) then begin
		  isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
		  	      isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j-1),$
			      isig(i,j-2),isig(i,j-3),isig(i,j-4),$
			      isig(i,j-5),isig(i,j-6)]
		  isignew(i,j)=median(isiginbt)
	  endif else begin
		  isignew(i,j)=isig(i,j)
	  endelse
	endif
	if (j eq 254) then goto, thenextj5

	if (isig(i,j) gt (isig(i,j-1)+50)) or $
	   (isig(i,j) gt (isig(i,j-2)+50)) or $
	   (isig(i,j) gt (isig(i,j-3)+50)) or $
	   (isig(i,j) gt (isig(i,j+1)+50)) or $
	   (isig(i,j) gt (isig(i,j+2)+50)) or $
	   (isig(i,j) gt (isig(i,j+3)+50)) or $
	   (isig(i,j) gt (isig(i-1,j)+50)) or $
	   (isig(i,j) gt (isig(i-2,j)+50)) or $
	   (isig(i,j) gt (isig(i-3,j)+50)) or $
	   (isig(i,j) gt (isig(i-4,j)+50)) or $
	   (isig(i,j) gt (isig(i-5,j)+50)) or $
	   (isig(i,j) gt (isig(i-6,j)+50)) then begin
		isiginbt = [isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
			    isig(i-4,j),isig(i-5,j),isig(i-6,j),isig(i,j+1),$
			    isig(i,j+2),isig(i,j+3),isig(i,j-1),$
			    isig(i,j-2),isig(i,j-3)]
		isignew(i,j)=median(isiginbt)
	endif else begin
		isignew(i,j)=isig(i,j)
	endelse

thenextj5:

return

end

;=======================================================================================
;	this function is also used in fitting the prss and temp. to the pkpos drift
;=======================================================================================

function driftcorr, x, m

	common prestempinfo, shftd_trlpress, shftd_trltemp
	return, [1., shftd_trlpress(x), shftd_trltemp(x)]

end

;=======================================================================================
;   this is the main program.
;   tlr_fringe_analysis.pro
;=======================================================================================



@frngprox.pro

pro tlr_fringe_analysis, stage=stage
common prestempinfo, shftd_trlpress, shftd_trltemp

	allfiles = ''
	filename = ''
	cleanfile = ''
	date = ''
	thtime = ''
	type = ''
	elev = ''
	azmth = ''
	head = bytarr(161)
	newhead = bytarr(161)
	isig = uintarr(256,255)
	isignew = uintarr(256,255)
	datfile3 = ''
	datfile4 = ''

	year = ''
	yr = ''
	day = ''
	mnth = ''
	month = ''

	load_pal,culz,idl=[3,1]

	epath = 'c:\fps_data\image\'
	dpath = 'c:\fps_data\latest\'
	fpath = 'c:\fps_data\results\'
	cpath = epath
	tlr_fplot = 0
;	temp_path = 'c:\fps_data\temp\'

	if getenv("TLR_EPATH") ne "" then epath = getenv("TLR_EPATH")
	if getenv("TLR_DPATH") ne "" then dpath = getenv("TLR_DPATH")
	if getenv("TLR_FPATH") ne "" then fpath = getenv("TLR_FPATH")
	if getenv("TLR_CPATH") ne "" then cpath = getenv("TLR_CPATH")
	if getenv("TLR_FPLOT") ne "" then tlr_fplot = fix(getenv("TLR_FPLOT"))

	year = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='Y$')
	mnth = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='0n$')
	day  = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='0d$')

	if year eq '2001' then yr = '01'
	if year eq '2002' then yr = '02'
	if year eq '2003' then yr = '03'

	subdir = yr + mnth + day + '\'
	if getenv("SUBDIR") ne "" then subdir = getenv("SUBDIR") + "\"
	if getenv("SUBDIR") ne "" then begin
	  yr = strmid(subdir,0,2)
	  mnth = strmid(subdir,2,2)
	  day = strmid(subdir,4,2)
	  if yr eq '01' then year = '2001'
	  if yr eq '02' then year = '2002'
	  if yr eq '03' then year = '2003'
	endif

	flist = findfile(epath + subdir + '*.RAW', count=nfiles)
	if (flist(0) eq '') then flist = findfile(epath + subdir + '*.RAW')
;	flist = findfile(temp_path + '*.RAW', count=nfiles)
;	if (flist(0) eq '') then flist = findfile(temp_path + '*.RAW')


        if keyword_set(stage) then begin
           print, subdir
           if stage eq 'STAGE_FIT_LASERS'           then goto, STAGE_FIT_LASERS
           stooge = stage
           xxx = findfile(fpath + yr + mnth + day + 'arrays.dat') 
           if n_elements(xxx) eq 1 then begin
              if xxx(0) eq '' then return
           endif 
           restore, fpath + yr + mnth + day + 'arrays.dat'
           stage  = stooge
           undefine, stooge
           if stage eq 'STAGE_FIT_SKIES'            then goto, STAGE_FIT_SKIES
           if stage eq 'STAGE_GEOPHYSICAL_RESULTS'  then goto, STAGE_GEOPHYSICAL_RESULTS
        endif
        
STAGE_FIT_LASERS:

	print,''
	if nfiles eq 0 then print, 'there are no images to analyze for day '+ subdir
	if nfiles eq 0 then print, 'abandoning analysis, abort, sorry bout dat.'
	if nfiles eq 0 then goto, theend
	flist = flist(sort(flist))

;--Number of points per 1-D spectrum.
	npts = 64

;--converting factor for going from peakpositions to winds,
;--for Lambdafsr= 0.0777573 Angstroms, Vfsr=4182.75 meters/sec, no. of points is ?
	Lambdafsr = (557.7e-9)^2/40e-3
	Vfsr = ((3.e8)*Lambdafsr)/557.7e-9
	cnvrsnfctr = Vfsr/npts

;--Specify the diagnostic messages/plots that we'd like 'spek_fit' to produce:
	diagz = ['dummy']
	diagz = [diagz, 'main_print_answer']
;	diagz = [diagz, 'main_plot_pars(window, 3)']
;	diagz = [diagz, 'nonlin_print_lambda']
; 	diagz = [diagz, 'main_plot_fitz(window, 0)']
        diagz = [diagz, 'main_loop_wait(ctlz.secwait = 0.01)']


;--Describe the species that emitted the airglow signal that we observed:
	species = {s_spec, name: 'O', $
			   mass:  16., $
			   relint: 1.}

;--Describe the instrument.  In this case we have a 20 mm etalon gap,
;  1 order scan range, npts channels in the spectrum:
	gap    = 20e-3
	lambda = 630.03e-9
	fsr    = lambda^2/(2*gap)
	cal    = {s_cal,   delta_lambda: fsr/npts, $
			   nominal_lambda: 630.03e-9}

	l_arrsize = 0
	s_arrsize = 0

	for findex = 0,nfiles-1 do begin

	   allfiles = flist(findex)

	   if allfiles ne '' then begin

on_ioerror, READ_SKIP
	     openr,unit,allfiles,/get_lun
	     readu,unit,head
	     readu,unit,isig
	     close, unit
	     free_lun, unit
	     goto, READ_OK
READ_SKIP:
	     close,unit
	     free_lun,unit
	     goto, NEXT_FILE
READ_OK:
	     date = string(head(0:5))
	     thtime = string(head(6:11))
	     type = string(head(12:14))
	     azmth = string(head(15:17))
	     elev = string(head(18:19))

	     if type eq '003' then begin
	       l_arrsize = l_arrsize + 1
	     endif

	     if type eq '001' then begin
	       s_arrsize = s_arrsize + 1
	     endif

	   endif
NEXT_FILE:
        endfor
        
        if s_arrsize eq 0 or l_arrsize eq 0 then return

;--Define all relevant arrays
	iter_num = intarr(s_arrsize)
	thesky_specs = dblarr(s_arrsize,npts)
	fittedsky_specs = dblarr(s_arrsize,npts)
	sky_pkpos = dblarr(s_arrsize)
	sky_pkposerr = dblarr(s_arrsize)
	sky_intnst = fltarr(s_arrsize)
	sky_intnsterr = fltarr(s_arrsize)
	sky_bckgrnd = fltarr(s_arrsize)
	sky_bckgrnderr = fltarr(s_arrsize)
	sky_temp = fltarr(s_arrsize)
	sky_temperr = fltarr(s_arrsize)
	sky_timearr = strarr(s_arrsize)
	sky_azmtharr = intarr(s_arrsize)
	sky_elevarr = intarr(s_arrsize)

	thelas_specs = dblarr(l_arrsize,npts)
	fittedlas_specs = dblarr(l_arrsize,npts)
	las_pkpos = dblarr(l_arrsize)
	las_pkposerr = dblarr(l_arrsize)
	las_temp = dblarr(l_arrsize)
	las_timearr = strarr(l_arrsize)

	incre2 = 0

	for findex = 0,nfiles-1 do begin

	   allfiles = flist(findex)

	   if allfiles ne '' then begin
on_ioerror, READ1_SKIP
	     openr,unit,allfiles,/get_lun
	     readu,unit,head
	     readu,unit,isig
	     close, unit
	     free_lun, unit
	     goto, READ1_OK
READ1_SKIP:
	     close,unit
	     free_lun,unit
	     goto, NEXT1_FILE
READ1_OK:

	     date = string(head(0:5))
	     thtime = string(head(6:11))
	     type = string(head(12:14))
	     azmth = string(head(15:17))
	     elev = string(head(18:19))

	     if strmid(thtime,0,1) eq ' ' then hr = strmid(thtime,1,1) else $
	     				       hr = strmid(thtime,0,2)
	     if strmid(thtime,2,1) eq ' ' then min = strmid(thtime,3,1) else $
					       min = strmid(thtime,2,2)
	     if strmid(thtime,4,1) eq ' ' then sec = strmid(thtime,5,1) else $
					       sec = strmid(thtime,4,2)

	     dec = strmid(strcompress(((float(min)*60.)+float(sec))/3600.,/rem),2,2)

	     if strmid(thtime,0,1) eq ' ' then dectime = '0'+hr+'.'+dec else $
	     				       dectime = hr+'.'+dec

	     if type eq '003' then begin

	       las_timearr(incre2) = dectime

	       print,''
	       if azmth eq '***' then print, 'laser image'
	       print,'image time is '+dectime
;	       print,'date is '+date
	       print,allfiles

	       filename = strmid(allfiles,strlen(allfiles)-12,8)
	       cleanfile = cpath + subdir + filename + '.cln'
;	       cleanfile = temp_path + filename + '.cln'

	       newhead(0:5) = byte(date)
	       newhead(6:10) = byte(dectime)
	       newhead(11:13) = byte(type)
	       newhead(14:16) = byte(azmth)
	       newhead(17:18) = byte(elev)

;	       isignew = isig
;	       call_procedure,'docleansky',isig,isignew
               mclascleaner, isig, isignew
	       isignew(0,*) = isignew(1,*)

	       openw,unit3,cleanfile,/get_lun
	       writeu,unit,newhead
	       writeu,unit,isignew
	       close,unit
	       free_lun,unit

	       ll = isignew

;--Remove any high-frequency noise from the image:
;	       ll = median(ll, 3)  ;Commented out MC 01-feb-02 ######

;--Remove any low-frequecy background from the image:
	       varbg = mc_im_sm(ll, 80)
	       varbg = varbg - total(varbg)/n_elements(varbg)
	       ll = ll - varbg
	       lref = ll

;--Housekeeping stuff:
	       nx   = n_elements(ll(*,0))
	       ny   = n_elements(ll(0,*))
	       lref = ll
	       llas = lref

;--Initialize the phase parameters structure (php) with reasonably close guesses:
	       frnginit, php, nx, ny, mag=[ 0.000243, 0.000243, 0.000001], $
		                      warp = [-0.00035,  0.0008], $
		                      center=[128.1, 122.6], $
		                      ordwin=[0.1,5.1], $
		                      phisq =0.0011, $
		                      R=0.82, $
		                      xcpsave='NO'
	       php.fplot = tlr_fplot

;--Fit the model to the observed laser fringes:
	       frng_fit, ll, php, culz
	       wait, .1

;--Sample the sky image to a 1-D spectrum, using the laser fit parameters:
;	       wdelete, 0
;	       window, 0, xsize=nx, ysize=ny
               fsave = php.fplot
               php.fplot=1
	       frng_spx, lref, llas, php, npts, [0.2, 3.2], 0.975, culz, las_spec ; Raised finesse to 0.975 from 0.97
	       php.fplot = fsave

	       fitpars   = [0., 0., 0., 0., 150.]
	       fix_mask  = [0, 1, 0, 0, 0]

;--------------Make an Airy function to use as an "instrument function":
               R       = 0.65
               x       = (findgen(npts) -npts/2.)*!pi/npts
               fringes = sin(x)
               fringes = 1./(1 + (4*php.R/(1. - php.r^2))*fringes*fringes)
               fringes = fringes - min(fringes)
               las_ip  = fringes/max(fringes)

;--Now fit an emission spectrum to the laser spectrum, using the instrument profile obtained from the laser fringes:
	       spek_fit, las_spec, las_ip, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_iters=2390, chisq_tolerance=0.001
	       oplot, quality.fitfunc, color=culz.cyan
	       wait, 2

;--Create a wavelength array so we can plot in actual wavelength units:
;	       lambda = fsr*((findgen(n_elements(las_spec)) - n_elements(las_spec)/2)/n_elements(las_spec))/1e-12

;	       help,quality, /str

;--Now plot the 1-D spectrum derived from the laser fringe image, and superimpose the fitted 1-D spectrum:
;	       window, 4, xsize=700, ysize=500, xpos=100, ypos=50, title="Derived spectrum and fit"
;	       erase, color=culz.white
;	       plot, lambda, las_spec, $
;	            xtitle='!6Wavelength [pm]!3', ytitle='!6Normalized Intensity!3', $
;	            /xstyle, /ystyle, yminor=2, color=culz.black, $
;	            /noerase, xthick=2, ythick=2, thick=2, charthick=2, charsize=2., $
;	            xrange=[-6,6], yrange=[0.0, max(las_spec)], psym=1, symsize=0.5
;	       oplot, lambda, las_spec, psym=1, symsize=0.5, color=culz.blue
;	       oplot, lambda, quality.fitfunc, color=culz.black, thick=2, linestyle=2
;	       xyouts, 0.5, 0.3, 'Temperature=' + strcompress(string(fitpars(4), format='(f12.1)'), /remove_all), $
;	            /normal, color=culz.black, charsize=2, charthick=2

	       las_pkpos(incre2) = double(fitpars(3))
	       las_pkposerr(incre2) = double(sigpars(3))
	       las_temp(incre2) = double(fitpars(4))
	       thelas_specs(incre2,*) = las_spec(*)
	       fittedlas_specs(incre2,*) = quality.fitfunc(*)
	       if incre2 eq 0 then las_phps = php else las_phps = [las_phps,php]
	       incre2 = incre2 + 1

	       save, /all, filename = fpath + yr + mnth + day + 'arrays.dat'
;	       save, /all, filename = temp_path + 'arrays.dat'

	       save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp,$
	             sky_temperr,$
	       	     sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	       	     filename = dpath + yr + mnth+ day +'smallarrays.dat'
	       save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp,$
	             sky_temperr,$
	       	     sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	       	     filename = fpath + yr + mnth+ day +'smallarrays.dat'

	     endif

	   endif

NEXT1_FILE:
	endfor

;--New changes to identify best laser per batch of 51 files, so that
;--sky images are analyzed using the best laser profile closest to it in time
;--MPK 02-02-11

	number = fix(l_arrsize / 9)
	number2 = l_arrsize / 9.
	if number2 gt number then no_of_batches = number + 1 else $
				  no_of_batches = number

	best_lasers = intarr(no_of_batches)
	best_insprofs = dblarr(no_of_batches, npts)
	best_las_temps = dblarr(no_of_batches)
	best_las_pkpos   = dblarr(no_of_batches)

	for i = 0,no_of_batches-1 do begin

	   if i eq no_of_batches-1 then begin
	     goody = where(las_temp(i*9:*) eq min(las_temp(i*9:*)))
	   endif else begin
	     goody = where(las_temp(i*9:(i+1)*9) eq min(las_temp(i*9:(i+1)*9)))
	   endelse

	   best_lasers(i) = goody
	   best_las_temps(i) = las_temp(goody)
	   best_las_pkpos(i) = las_pkpos(goody)
	   best_insprofs(i,*) = thelas_specs(goody, *)
	   if i eq 0 then best_phps = las_phps(goody) else $
		best_phps = [best_phps,las_phps(goody)]

	endfor

;stop


STAGE_FIT_SKIES:

	insprof = dblarr(npts)
	best_laser = where(las_temp eq min(las_temp))
	new_incre = 0

	if best_las_temps(new_incre) lt 150. then begin
	   insprof(*) = best_insprofs(new_incre,*)
	   php = best_phps(new_incre)
	   pkzero = best_las_pkpos(new_incre)
	endif else begin
	   insprof = thelas_specs(best_laser(0), *)
	   php = las_phps(best_laser(0))
       	   pkzero = las_pkpos(best_laser(0))
	endelse
	php.lambda = 557.7
	
	
	
     ;--Do a little conditioning on the instrument function:
       	insprof = insprof - min(insprof)
       	insprof = insprof/max(insprof)
	
	


;--Describe the instrument again, but for sky images at 557.7 nm.
;--In this case we have a 20 mm etalon gap, 1 order scan range,
;--npts channels in the spectrum:
	gap    = 20e-3
	lambda = 557.7e-9
	fsr    = lambda^2/(2*gap)
	cal    = {s_cal,   delta_lambda: fsr/npts, $
			   nominal_lambda: 557.7e-9}



        save, /all, filename = fpath + yr + mnth + day + 'arrays.dat'
;	save, /all, filename = temp_path + 'arrays.dat'

        save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp, $
              sky_temperr,$
	      sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	      filename = dpath + yr + mnth+ day +'smallarrays.dat'
        save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp,$
              sky_temperr,$
	      sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	      filename = fpath + yr + mnth+ day +'smallarrays.dat'

	incre = 0

	for findex=0,nfiles-1 do begin

	   allfiles = flist(findex)

	   if allfiles ne '' then begin

on_ioerror, READ2_SKIP
	     openr,unit,allfiles,/get_lun
	     readu,unit,head
	     readu,unit,isig
	     close, unit
	     free_lun, unit
	     goto, READ2_OK
READ2_SKIP:
	     close,unit
	     free_lun,unit
	     goto, NEXT2_FILE
READ2_OK:

	     date = string(head(0:5))
	     thtime = string(head(6:11))
	     type = string(head(12:14))
	     azmth = string(head(15:17))
	     elev = string(head(18:19))

	     if strmid(thtime,0,1) eq ' ' then hr = strmid(thtime,1,1) else $
	     				       hr = strmid(thtime,0,2)
	     if strmid(thtime,2,1) eq ' ' then min = strmid(thtime,3,1) else $
					       min = strmid(thtime,2,2)
	     if strmid(thtime,4,1) eq ' ' then sec = strmid(thtime,5,1) else $
					       sec = strmid(thtime,4,2)

	     dec = strmid(strcompress(((float(min)*60.)+float(sec))/3600.,/rem),2,2)

	     if strmid(thtime,0,1) eq ' ' then dectime = '0'+hr+'.'+dec else $
	     				       dectime = hr+'.'+dec

	     if type eq '001' then begin

	       sky_timearr(incre) = dectime
	       sky_azmtharr(incre) = fix(azmth)
	       sky_elevarr(incre) = fix(elev)

	       print,''
	       if azmth eq '000' and elev eq '90' then print, 'zenith looking'
;	       if azmth eq '000' and elev eq '30' then print, 'northward looking'
;	       if azmth eq '090' then print, 'eastward looking'
;	       if azmth eq '180' then print, 'southward looking'
;	       if azmth eq '270' then print, 'westward looking'
	       print,'image time is '+dectime
;	       print,'date is '+date
	       print,allfiles

	       filename = strmid(allfiles,strlen(allfiles)-12,8)
	       cleanfile = cpath + subdir + filename + '.cln'
;	       cleanfile = temp_path + filename + '.cln'

	       newhead(0:5) = byte(date)
	       newhead(6:10) = byte(dectime)
	       newhead(11:13) = byte(type)
	       newhead(14:16) = byte(azmth)
	       newhead(17:18) = byte(elev)

	       call_procedure,'docleansky',isig,isignew
;####               mclascleaner, isig, isignew
	       isignew(0,*) = isignew(1,*)

	       openw,unit3,cleanfile,/get_lun
	       writeu,unit,newhead
	       writeu,unit,isignew
	       close,unit
	       free_lun,unit

	       lsky = isignew

;--Remove any high-frequency noise from the image:
;	       lsky = mc_im_sm(lsky, 3) ; Commented out MC 01-feb-02 #######

;--Remove any low-frequecy background from the image:
	       varbg = mc_im_sm(lsky, 60)  ; Dropped window from 80 to 60, MC 01-feb-02 ####
	       varbg = varbg - total(varbg)/n_elements(varbg)
	       lsky = lsky - varbg
	       lref = lsky

;--Sample the sky image to a 1-D spectrum, using the laser fit parameters:
;	       wdelete, 0
;	       window, 0, xsize=php.nx, ysize=php.ny
               phq = php
               fsave = phq.fplot
               phq.fplot=1
	       frng_spx, lref, lsky, phq, npts, [0.1, 4.1], 0.96, culz, skyspec ; Raised finesse to 0.995 from 0.95 #####
               phq.fplot = fsave

	       ipeak = where(insprof eq max(insprof))
	       speak = where(skyspec eq max(skyspec))
	       fitpars   = [0., 0., 0., speak(0) - ipeak(0), 600.]
	       fix_mask  = [0, 1, 0, 0, 0]

;	       print,speak(0),'   ',ipeak(0)

;--Now fit an emission spectrum to the sky sky spectrum, using the instrument profile obtained from the laser fringes:
	       spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_iters=2390, chisq_tolerance=0.001
	       oplot, quality.fitfunc, color=culz.cyan
	       wait, 0.2

;--Create a wavelength array so we can plot in actual wavelength units:
;	       lambda = fsr*((findgen(n_elements(skyspec)) - n_elements(skyspec)/2)/n_elements(skyspec))/1e-12

;--Now plot the 1-D spectrum derived from the sky fringe image, and superimpose the fitted 1-D spectrum:
;	       window, 4, xsize=700, ysize=500, xpos=100, ypos=50, title="Derived spectrum and fit"
;	       erase, color=culz.white
;	       plot, lambda, skyspec, $
;	             xtitle='!6Wavelength [pm]!3', ytitle='!6Normalized Intensity!3', $
;	            /xstyle, /ystyle, yminor=2, color=culz.black, $
;	            /noerase, xthick=2, ythick=2, thick=2, charthick=2, charsize=2., $
;	             xrange=[-6,6], yrange=[0.0,max(skyspec)], psym=1, symsize=0.5
;	       oplot, lambda, skyspec, psym=1, symsize=0.5, color=culz.blue
;	       oplot, lambda, quality.fitfunc, color=culz.black, thick=2, linestyle=2
;	       xyouts, 0.5, 0.3, 'Temperature=' + strcompress(string(fitpars(4), format='(f12.1)'), /remove_all), $
;	              /normal, color=culz.black, charsize=2, charthick=2

;	       help,quality, /str
	       iter_num(incre) = quality.iters
	       sky_pkpos(incre) = double(fitpars(3)) + pkzero*632.8/557.7 ;#### MC fix
	       sky_pkposerr(incre) = double(sigpars(3))
	       thesky_specs(incre,*) = skyspec(*)
	       fittedsky_specs(incre,*) = quality.fitfunc(*)
	       sky_bckgrnd(incre) = fitpars(0)
	       sky_bckgrnderr(incre) = sigpars(0)
	       sky_intnst(incre) = fitpars(2)
	       sky_intnsterr(incre) = sigpars(2)
	       sky_temp(incre) = fitpars(4)
	       sky_temperr(incre) = sigpars(4)
	       incre = incre + 1

	       save, /all, filename = fpath + yr + mnth + day + 'arrays.dat'
;	       save, /all, filename = temp_path + 'arrays.dat'
	       save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp, $
	             sky_temperr,$
	       	     sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	       	     filename = dpath + yr + mnth+ day +'smallarrays.dat'
	       save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp,$
	             sky_temperr,$
	       	     sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	       	     filename = fpath + yr + mnth+ day +'smallarrays.dat'


	       if incre eq 42 or incre eq 84 or incre eq 126 or incre eq 168 or $
		  incre eq 210 or incre eq 252 or incre eq 294 then begin

			new_incre = new_incre + 1 < n_elements(best_las_temps)-1

			if best_las_temps(new_incre) lt 150. then begin
			   insprof(*) = best_insprofs(new_incre,*)
			   php = best_phps(new_incre)
   	                   pkzero = best_las_pkpos(new_incre)
			endif else begin
			   insprof = thelas_specs(best_laser(0), *)
			   php = las_phps(best_laser(0))
	                   pkzero = best_las_pkpos(new_incre)
			endelse
			php.lambda = 557.7
			insprof = insprof - min(insprof)
			insprof = insprof/max(insprof)

	       endif

	     endif

	   endif
NEXT2_FILE:
	endfor


	save, /all, filename = fpath + yr + mnth + day + 'arrays.dat'
;	save, /all, filename = temp_path + 'arrays.dat'

        save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp, $
              sky_temperr,$
	      sky_intnst, sky_bckgrnd, sky_timearr,thesky_specs,fittedsky_specs, $
	      filename = dpath + yr + mnth+ day +'smallarrays.dat'
        save, las_pkpos,las_temp, las_timearr, sky_pkpos, sky_pkposerr,sky_temp,$
              sky_temperr,$
	      sky_intnst, sky_bckgrnd, sky_timearr, thesky_specs,fittedsky_specs,$
	      filename = fpath + yr + mnth+ day +'smallarrays.dat'


;--Reduction to spectra complete.  On to the second stage of analysis.

STAGE_GEOPHYSICAL_RESULTS:

	joe = where(sky_pkpos lt 0.,oops)
	if oops gt 0 then sky_pkpos(joe) = sky_pkpos(joe) + npts

;set_plot, 'win'
;load_pal, culz
;plot, sky_pkpos, /ystyle
	deltol = 3.0
	for j = 1,s_arrsize-1 do begin
	   lodx = j - 2 > 0
	   hidx = j + 2 < s_arrsize-1
	   before = median(sky_pkpos(lodx:j-1))
	   after  = median(sky_pkpos(j:hidx))
	   if abs(sky_pkpos(j) - before) gt deltol then sky_pkpos(j:*) = sky_pkpos(j:*) - (after - before)
	endfor
	for j = 1,s_arrsize-1 do begin
	   lodx = j - 2 > 0
	   hidx = j + 2 < s_arrsize-1
	   before = median(sky_pkpos(lodx:j-1))
	   after  = sky_pkpos(j)
	   if abs(sky_pkpos(j) - before) gt deltol then sky_pkpos(j:*) = sky_pkpos(j:*) - (after - before)
	endfor
;oplot, sky_pkpos, color=culz.cyan
;stop

	sky_flttimes = double(sky_timearr)
	sky_pkpos_mean = double(mean(sky_pkpos))
	shftd_sky_pkpos = sky_pkpos - sky_pkpos_mean

;=======================================================================================
; this section opens and reads the trailer press/temp files and stores and sorts the
; info., so that it can be used in the drift correction.
;=======================================================================================

	useless=''
	d1=fix(0) & d2=fix(0) & d3=fix(0) & d4=fix(0) & d5=fix(0) & d6=fix(0)
	d7=fix(0) & d8=fix(0) & d9=fix(0) & d10=fix(0) & d11=fix(0) & d12=fix(0)
	d13=fix(0) & d14=fix(0) & d15=fix(0) & d25=fix(0) & d26=fix(0)

	housekeepfile = findfile(epath+subdir+'HK'+yr+mnth+day+'.DAT',count=hkfile)
	if hkfile eq 0 then goto, stupid

	old26=0.
	seep=0

	openr,unit,housekeepfile,/get_lun
	readf,unit,format='(a247)',useless
	while (not eof(unit)) do begin
	readf,format='(15I6,9F8.1,I6,I10)',unit, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
	   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
	 if d10 eq 45 or old26 eq d26 then goto, dontincre
	 seep=seep+1
	 dontincre:
	 old26 = d26
	endwhile
	close,unit
	free_lun,unit

	biggie=seep
	trl_hrtime = dblarr(biggie)
	trl_press = dblarr(biggie)
	trl_temp = dblarr(biggie)
	old26=0.
	seep=0

	openr,unit,housekeepfile,/get_lun
	readf,unit,format='(a247)',useless
	while (not eof(unit)) do begin
	readf,unit,format='(15I6,9F8.1,I6,I10)', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
	   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
	 if d10 eq 45 or old26 eq d26 then goto, dontstore
	 trl_press(seep) = double(d16)
	 trl_temp(seep) = double(d17)
	 trl_hrtime(seep) = (d4*3600L + d5*60L + d6)/3600.
	 seep=seep+1
	 dontstore:
	 old26 = d26
	endwhile
	close,unit
	free_lun,unit


;=======================================================================================
; this section is to try to fit temp. and press. data to the pkpos drift...
; this section takes care of all drift correction and converts the peaks to velocities.
;=======================================================================================

	znth_pkpos = dblarr(s_arrsize)
	znth_times = dblarr(s_arrsize)
	znth_pkpos = double(shftd_sky_pkpos)
	znth_pkposerr = sky_pkposerr
	znth_times = double(sky_flttimes)

	if biggie ne s_arrsize then begin
           print, 'Houston, we have a problem...but we can fix it because we are clever.'
           extra_press = fltarr(s_arrsize)
	   extra_temp  = fltarr(s_arrsize)

	   for j=0,s_arrsize-1 do begin
	       tdiff = abs(znth_times(j) - trl_hrtime)
	       tbest = where(tdiff eq min(tdiff))
	       tbest = tbest(0)
	       extra_press(j) = trl_press(tbest)
	       extra_temp(j) = trl_temp(tbest)
	   endfor

	   trl_press = extra_press
	   trl_temp  = extra_temp
	endif


	shftd_trlpress = double(trl_press) - double(mean(trl_press))
	shftd_trltemp = double(trl_temp) - double(mean(trl_temp))

	pshift = 15
	trange = double((max(znth_times) - min(znth_times))*60.)
	tgrid  = double(min(znth_times)) + dindgen(trange)/60.
	rrr = n_elements(tgrid)

	tempsam = interpol(double(shftd_trltemp), double(znth_times), tgrid)
	tempsam = mc_im_sm(tempsam, 60)
	temprange = [min(tempsam), max(tempsam)]
	tempsam = tempsam + 120.*(tempsam - shift(tempsam, 1))
	tempsam(0)=tempsam(1)
	tempsam = tempsam - min(tempsam)
	tempsam = tempsam/max(tempsam(3:rrr-5))
	tempsam = temprange(0) + (temprange(1) - temprange(0))*tempsam
	nshift  = tempsam
	for j=1,pshift do begin
	    shf1 = shift(tempsam, j)
	    nshift(j+1:*) = shf1(j+1:*)
	endfor
	tempsam = nshift
	temsave = shftd_trltemp
	pressave = shftd_trlpress
	zensam = interpol(double(median(znth_pkpos, 5)), double(znth_times), tgrid)
	shftd_trlpress = interpol(double(shftd_trlpress), double(znth_times), tgrid)
	shftd_trltemp = tempsam

	weights = fltarr(rrr) + 1.
	xxx = findgen(rrr)
	a = [1.,1.,1.]
	fitcoeffs = svdfit(xxx,zensam,a=a,double=double,yfit=yfit,sigma=sigma,$
					function_name='driftcorr',variance=variance, weight=weights)
	thefitcoeffs = fitcoeffs
	theerrors = sigma
	save, thefitcoeffs, theerrors, filename = fpath + yr + mnth + day + 'prstmpcoeffs.dat'
	

	smth_znth_pkpos = interpol(yfit, tgrid, znth_times)
	yfiterr = sqrt((shftd_trlpress*theerrors(1))^2 + (shftd_trltemp*theerrors(2))^2)
	smth_znth_pkposerr = interpol(yfiterr, tgrid, znth_times)

	new_znth_pkpos = znth_pkpos - smth_znth_pkpos
	new_znth_pkposerr = (znth_pkposerr^2 + smth_znth_pkposerr^2)^(0.5)

	corr_znth_pkpos = new_znth_pkpos

	mcpoly_filter, znth_times, corr_znth_pkpos, order = 5, /lowpass

	poly_znth_pkpos = corr_znth_pkpos

	fnl_pkpos = new_znth_pkpos - poly_znth_pkpos
	total_pkposerr = new_znth_pkposerr


;	if biggie eq s_arrsize then goto, okay
	goto, okay

stupid:

	print,''
	print,'there were problems with the pressure/temperature drift correction'
	print,''

	znth_pkpos = dblarr(s_arrsize)
	znth_times = dblarr(s_arrsize)
	znth_pkpos = double(shftd_sky_pkpos)
	znth_pkposerr = sky_pkposerr
	znth_times = double(sky_flttimes)

	new_znth_pkpos = znth_pkpos
	new_znth_pkposerr = znth_pkposerr

	corr_znth_pkpos = new_znth_pkpos

	mcpoly_filter, znth_times, corr_znth_pkpos, order = 9, /lowpass

	poly_znth_pkpos = corr_znth_pkpos

	fnl_pkpos = new_znth_pkpos - poly_znth_pkpos
	total_pkposerr = new_znth_pkposerr

okay:

	znthwnd = -(cnvrsnfctr * fnl_pkpos)
	znthwnderr = cnvrsnfctr * total_pkposerr
	znthintnst = sky_intnst
	znthintnsterr = sky_intnsterr
	znthtemp = sky_temp
	znthtemperr = sky_temperr

;--Analysis complete, do some plotting and storage to ASCII, and save to proper
;--directory.

	rel_intnst = znthintnst / 10000.

	if (mnth eq '01') then month='Jan'
	if (mnth eq '02') then month='Feb'
	if (mnth eq '03') then month='Mar'
	if (mnth eq '04') then month='Apr'
	if (mnth eq '05') then month='May'
	if (mnth eq '06') then month='Jun'
	if (mnth eq '07') then month='Jul'
	if (mnth eq '08') then month='Aug'
	if (mnth eq '09') then month='Sep'
	if (mnth eq '10') then month='Oct'
	if (mnth eq '11') then month='Nov'
	if (mnth eq '12') then month='Dec'

	if max(rel_intnst) le 10. then maxxiss = 10.
	if max(rel_intnst) gt 10. and max(rel_intnst) le 20. then maxxiss = 20.
	if max(rel_intnst) gt 20. and max(rel_intnst) le 30. then maxxiss = 30.
	if max(rel_intnst) gt 30. and max(rel_intnst) le 40. then maxxiss = 40.
	if max(rel_intnst) gt 40. and max(rel_intnst) le 50. then maxxiss = 50.
	if max(rel_intnst) gt 50. and max(rel_intnst) le 60. then maxxiss = 60.
	if max(rel_intnst) gt 60. and max(rel_intnst) le 70. then maxxiss = 70.
	if max(rel_intnst) gt 70. and max(rel_intnst) le 80. then maxxiss = 80.
	if max(rel_intnst) gt 80. and max(rel_intnst) le 90. then maxxiss = 90.
	if max(rel_intnst) gt 90. and max(rel_intnst) le 100. then maxxiss = 100.
	if max(rel_intnst) gt 100. and max(rel_intnst) le 110. then maxxiss = 110.
	if max(rel_intnst) gt 110. and max(rel_intnst) le 120. then maxxiss = 120.
	if max(rel_intnst) gt 120. and max(rel_intnst) le 130. then maxxiss = 130.
	if max(rel_intnst) gt 130. and max(rel_intnst) le 140. then maxxiss = 140.
	if max(rel_intnst) gt 140. and max(rel_intnst) le 150. then maxxiss = 150.
	if max(rel_intnst) gt 150. and max(rel_intnst) le 160. then maxxiss = 160.
	if max(rel_intnst) gt 160. and max(rel_intnst) le 170. then maxxiss = 170.
	if max(rel_intnst) gt 170. and max(rel_intnst) le 180. then maxxiss = 180.
	if max(rel_intnst) gt 180. and max(rel_intnst) le 190. then maxxiss = 190.
	if max(rel_intnst) gt 190. and max(rel_intnst) le 200. then maxxiss = 200.
	if max(rel_intnst) gt 200. and max(rel_intnst) le 210. then maxxiss = 210.
	if max(rel_intnst) gt 210. and max(rel_intnst) le 220. then maxxiss = 220.
	if max(rel_intnst) gt 220. and max(rel_intnst) le 230. then maxxiss = 230.
	if max(rel_intnst) gt 230. and max(rel_intnst) le 240. then maxxiss = 240.
	if max(rel_intnst) gt 240. and max(rel_intnst) le 250. then maxxiss = 250.
	if max(rel_intnst) gt 250. and max(rel_intnst) le 260. then maxxiss = 260.
	if max(rel_intnst) gt 260. and max(rel_intnst) le 270. then maxxiss = 270.
	if max(rel_intnst) gt 270. and max(rel_intnst) le 280. then maxxiss = 280.
	if max(rel_intnst) gt 280. and max(rel_intnst) le 290. then maxxiss = 290.
	if max(rel_intnst) gt 290. and max(rel_intnst) le 300. then maxxiss = 300.
	if max(rel_intnst) gt 300. and max(rel_intnst) le 310. then maxxiss = 310.
	if max(rel_intnst) gt 310. and max(rel_intnst) le 320. then maxxiss = 320.
	if max(rel_intnst) gt 320. and max(rel_intnst) le 330. then maxxiss = 330.
	if max(rel_intnst) gt 330. and max(rel_intnst) le 340. then maxxiss = 340.
	if max(rel_intnst) gt 340. and max(rel_intnst) le 350. then maxxiss = 350.
	if max(rel_intnst) gt 350. and max(rel_intnst) le 360. then maxxiss = 360.
	if max(rel_intnst) gt 360. and max(rel_intnst) le 370. then maxxiss = 370.
	if max(rel_intnst) gt 370. and max(rel_intnst) le 380. then maxxiss = 380.
	if max(rel_intnst) gt 380. and max(rel_intnst) le 390. then maxxiss = 390.
	if max(rel_intnst) gt 390. and max(rel_intnst) le 400. then maxxiss = 400.

	if max(znthtemp) le 1000. then t_max = 1000.
	if max(znthtemp) gt 1000. and max(znthtemp) le 1200. then t_max = 1200.
	if max(znthtemp) gt 1200. and max(znthtemp) le 1400. then t_max = 1400.
	if max(znthtemp) gt 1400. and max(znthtemp) le 1600. then t_max = 1600.
	if max(znthtemp) gt 1600. and max(znthtemp) le 1800. then t_max = 1800.
	if max(znthtemp) gt 1800. and max(znthtemp) le 2000. then t_max = 2000.
	if max(znthtemp) gt 2000. and max(znthtemp) le 2200. then t_max = 2200.
	if max(znthtemp) gt 2200. and max(znthtemp) le 2400. then t_max = 2400.
	if max(znthtemp) gt 2400. and max(znthtemp) le 2600. then t_max = 2600.
	if max(znthtemp) gt 2600. and max(znthtemp) le 2800. then t_max = 2800.
	if max(znthtemp) gt 2800. and max(znthtemp) le 3000. then t_max = 3000.
	if max(znthtemp) gt 3000. and max(znthtemp) le 3200. then t_max = 3200.
	if max(znthtemp) gt 3200. and max(znthtemp) le 3400. then t_max = 3400.
	if max(znthtemp) gt 3400. and max(znthtemp) le 3600. then t_max = 3600.
	if max(znthtemp) gt 3600. and max(znthtemp) le 3800. then t_max = 3800.


	v_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
			  'Vertical Winds in the Lower Thermosphere'
	temp_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
				 'Temperatures in the Lower Thermosphere'
	intnst_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
				   '557.7 nm Relative Intensity'
;###MC Mod
set_plot, 'Z'
device, set_resolution=[900,700]

        if n_elements(thefitcoeffs) gt 0 then begin
	   plot,znth_times,znth_pkpos, pos=[0.1,0.15,0.9,0.8],$
	    title='Peak position drift correction,!C'+$
	    'fitting to the shifted pressure and temp for that night,!C'+$
	    'and using the coefficients generated from that fit,!C'+$
	    month+' '+day+', '+year, xrange=[1.,17.],xstyle=1,$
	    xtitle='Time, UT',yrange=[-3.,3.],ystyle=1,$
	    subtitle = 'Pressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
				   '!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
	   oplot,znth_times,new_znth_pkpos,color=culz.blue
	   oplot,znth_times,smth_znth_pkpos,color=culz.red
	   oplot,znth_times,poly_znth_pkpos,color=culz.wheat
	   oplot,znth_times,fnl_pkpos,color=culz.green
	   img = tvrd()
	   tvlct, r, g, b, /get
	   write_gif, fpath + yr + mnth + day + '_drftcorr.gif', img, r, g, b

	   plot,znth_times,znth_pkpos,pos=[0.1,0.2,0.9,0.9],$
	    xtitle='Time, UT',yrange=[-3.,3.],ystyle=1,$
	    title='Zenith Peak Position Drift Correction Analysis!C'+$
			   month+' '+day+', '+year,xrange=[1.,17.],xstyle=1,$
	    subtitle='Graph includes raw peak position, the fit to the raw peak position!C'+$
		 'based on the pressure and response-corrected temperature info.,!C'+$
		     'the shifted pressure and temp. data, and the response-corrected temp. profile!C'+$
		     '!CPressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
		     '!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
	   oplot,znth_times,smth_znth_pkpos,color=culz.green
	   oplot,tgrid,shftd_trlpress,color=culz.cyan
	   oplot,tgrid,shftd_trltemp,color=culz.blue
	   oplot,znth_times,temsave,color=culz.yellow
	   img = tvrd()
	   tvlct, r, g, b, /get
	   write_gif, fpath + yr + mnth + day + '_drftanlys.gif', img, r, g, b
	endif



;	window,5,retain=2,xsize=700,ysize=500
	plot, znth_times, znthwnd,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = v_title,$
		  ytitle='Vertical wind speed (m/s)',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[-150,150]
	oplot, znth_times,znthwnd
	errplot, znth_times,znthwnd-znthwnderr, znthwnd+znthwnderr
;	wset,5
;	gif_this, file = dpath + yr + mnth + day + '_vertwind.gif'
;	gif_this, file = fpath + yr + mnth + day + '_vertwind.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_vertwind.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_vertwind.gif', img, r, g, b
;        write_gif, temp_path + '_vertwind.gif', img, r, g, b

;	window,6,retain=2,xsize=700,ysize=500
	plot, znth_times, znthtemp,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = temp_title,$
		  ytitle='Temperature (K)',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[0,t_max]
	oplot, znth_times,znthtemp
	errplot, znth_times,znthtemp-znthtemperr,znthtemp+znthtemperr
;	wset,6
;	gif_this, file = dpath + yr + mnth + day + '_temp.gif'
;	gif_this, file = fpath + yr + mnth + day + '_temp.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_temp.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_temp.gif', img, r, g, b
;        write_gif, temp_path + '_temp.gif', img, r, g, b

;	window,7,retain=2,xsize=700,ysize=500
	plot, znth_times, rel_intnst,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = intnst_title,$
		  ytitle='Normalized Intensity',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[0,maxxiss]
	oplot, znth_times,rel_intnst
;	wset,7
;	gif_this, file = dpath + yr + mnth + day + '_intnst.gif'
;	gif_this, file = fpath + yr + mnth + day + '_intnst.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_intnst.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_intnst.gif', img, r, g, b
;        write_gif, temp_path + '_intnst.gif', img, r, g, b

	date = yr + mnth + day

	datfile3 = dpath + 'ik' + yr + mnth + day + '.dbt'
;	datfile3 = temp_path + 'ik.dbt'
	openw,unit3,datfile3,/get_lun

	datfile4 = fpath + 'ik' + yr + mnth + day + '.dbt'
	openw,unit4,datfile4,/get_lun

	for i = 0,s_arrsize-1 do begin
	   thetime=znth_times(i)
	   call_procedure, 'fixtime', thetime

	   printf,unit3,format='(a6,i6,i8,i8,2f8.2,4f9.1,2f8.1)',date,thetime,$
	    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
	    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)

	   printf,unit4,format='(a6,i6,i8,i8,2f8.2,4f9.1,2f8.1)',date,thetime,$
	    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
	    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)

	endfor

	close,unit3
	free_lun,unit3
	close,unit4
	free_lun,unit4

	print, ''
	print, 'Analysis is complete.'
	print, 'Well, isnt that special?!'

theend:

end