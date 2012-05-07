;-----------------------------------------------------------------------------
	pro placetitles,title,subtitle,size=tsize,nocopyright=nocopyright
;+
; NAME:			PLACETITLES
;
; PURPOSE:		places titles (up to two lines), subtitles and 
;			information line onto page. Useful for multiple plots  
;			to label the entire set of figures. Also useful for  
;			single page plots which already have labelling on the  
;			top and bottom, for example when there are multiple  
;			scales such as frequency at the bottom and period at  
;			the top. This routine is most useful for postscript  
;			files as the titles are placed near the borders of  
;			the plot region (!p.region). This may cause the titles
;			(and always causes the infoline) to be partially off  
;			of the window in X-window applications.
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	PLACETITLES,title,subtitle,SIZE=size,/NOCOPYRIGHT
;
; INPUTS:
;			title	= string or strarr(2) containing the title
;   OPTIONAL PARAMETERS:
;			subtitle= string containing the subtitle
;	KEYWORDS:
;			SIZE	= titles will be 1.3*SIZE in character units 
;				 (default=1.3*!p.charsize)
;			NOCOPYRIGHT = disable the information line.
;				This line is written using COPYRIGHT routine
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:		writes onto current pliot window
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	if (n_elements(title) le 0) then return
	if (n_elements(title) gt 1) then begin
		title1 = title(0) & title2 = title(1)
	endif else begin
		title1 = title(0) & title2 = ' '
	endelse
	if (n_elements(subtitle) le 0) then subtitle = ' '

	;find the position for the title and put it there
	nchar = float(!d.y_ch_size)/!d.y_vsize
	if (!p.charsize gt 0) then yoff =!p.charsize else yoff =1.
	if (not keyword_set(tsize)) then tsize = yoff
	if (!x.charsize gt 0) then yoff = yoff*!x.charsize
	nchar = nchar*yoff
	if (!p.multi(1) gt 1) then xpos = 0.5 else xpos = 0.5*total(!x.window)
	if (!p.multi(2) gt 1) then ypos = 1.0 else ypos = !y.window(1)+(-!x.ticklen>0.0)+nchar

	xyouts,xpos,ypos+nchar*0.7,title2,/norm,alignm=0.5,size=1.2*tsize
	xyouts,xpos,ypos+nchar*2.5,title1,/norm,alignm=0.5,size=1.3*tsize 
	if (not keyword_set(nocopyright)) then $
		copyright,size=1.1*tsize,yoff=-3.2*yoff	

	;find the position for the subtitle and put it there
	if (!p.multi(2) gt 1) then ypos = -7*nchar else ypos = !y.window(0)-(-!x.ticklen>0.0)-3.8*nchar
	xyouts,xpos,ypos,subtitle,alignment=0.5,/norm,size=tsize

	return
	end
