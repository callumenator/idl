;-----------------------------------------------------------------------------
		pro copyright, txt, size=size, xoff=xoff, yoff=yoff
;+
; NAME:			copyright
;
; PURPOSE:		Put a current date/time stamp and user id at bottom of 
;			plot (but outside plot region). Generally only useful  
;			for PostScript plots as the plotted page is smaller  
;			than the physical page therefore text outside the plot
;			region can still be seen. Not so useful for window  
;			dumps unless the user has reduced the plot region by  
;			setting !P.REGION.
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	copyright
;			copyright,"use this text string instead",size=1.2
;			copyright,xoff=0,yoff=-1
;
; INPUTS:
;			txt	= a string to be used instead of the 
;				  default USERNAME and SYSTEM DATE
;
;		KEYWORDS:
;			SIZE	= size in character units. Default is 1.5
;			XOFF	= the offset (in character units) towards the 
;				  -ve x-axis from the extreme +ve x-axis, 
;				  where the end of the text string will be 
;				  aligned (default is +3.5)
;			YOFF	= the offset (in character units) towards the 
;				  +ve y-axis from 0, 
;				  where the end of the text string will be 
;				  aligned (default is -2.2)
;
; OUTPUTS:
;		Uses XYOUTS to write a text string
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;		Uses XYOUTS to write a text string
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	if (n_elements(txt) gt 0) then text = txt $
	else begin
		if (strupcase(!version.os) eq 'VMS') then $
			status = TRNLOG("SYS$LOGIN",text) $
		else text = getenv('USER')
	endelse

	;my default !!
	if (strpos(strupcase(text),'HARRIS') ge 0) then text= 'T.J.Harris  '

	if (not keyword_set(size)) then size = 1.5
	if (not keyword_set(xoff)) then xoff = 3.5
	if (not keyword_set(yoff)) then yoff = -2.2
	dt = ' '

	;;if (strupcase(!version.os) eq 'VMS') then begin
	;;	spawn,"show time",tmp
	;;	dt = strmid(tmp,2,2)+strmid(tmp,5,3)+strmid(tmp,11,2)
	;;endif else spawn,['date','+%d%h%y'],/noshell,dt
	tmp = systime()
	dt = strmid(tmp,11,5)+'  '+strmid(tmp,8,2) $
		+strmid(tmp,4,3)+strmid(tmp,22,2)

	text = text+dt(0)

	if (!p.region(0) eq !p.region(2)) then begin
		bottom = 0.0 
		rightside = 1.0
	endif else begin
		bottom = !p.region(1)
		rightside = !p.region(2)
	endelse
	bottom = bottom + !d.y_ch_size*yoff/float(!d.y_vsize)
	rightside = rightside + !d.x_ch_size*xoff/float(!d.x_vsize)

	if ((strpos('TEKXSUN',!d.name) ge 0) and (!d.window lt 0)) or (!d.name eq 'NULL') then begin
		exclamark = strpos(text,'!')
		while (exclamark ge 0) do begin
			text = strmid(text,0,exclamark-1)+strmid(text,exclamark+3,strlen(text))
			exclamark = strpos(text,'!')
		endwhile
		print,text
	endif else $
		xyouts,rightside,bottom,text,/norm,alignment=1,size=size 

	return
	end

