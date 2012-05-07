;----------------------------------------------------------------------------
	pro screens,title1,title2,same=same,next=next,$
			horizontal=horizontal,vertical=vertical,$
			portrait=portrait,landscape=landscape
;+
; NAME:			SCREENS
;
; PURPOSE:		Generic routine to open a display on the default 
;			device regardless of the device type. Thus a  
;			procedure can call this routine and begin to plot  
;			without having to worry about whether it is displaying 
;			to a windowed or plot device. Currently only handles  
;			X, Sun, PS, HP, NULL and TEK devices properly.
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	SCREENS
;			SCREENS,title1,/NEXT,/PORTRAIT
;
; INPUTS:
;   OPTIONAL PARAMETERS:
;			title1 	= message which is printed to the screen
;			title2 	= Window title if on a windowed device
;				  (defaults to title1)
;	KEYWORDS:
;			NEXT 	= if set then append a number to the file name
;				  if a plot device (see PSETUP), otherwise 
;				  create a new window on windowed devices or 
;				  clear the plot screen if in TEK 
;				  This keyword allows multiple files/screens 
;				  to be generated without overwriting each  
;				  other. The LUN or append file number is
;				  incremented with each call to SCREENS,/next
;				  For the PS device the number is reset with 
;				  the /RESET keyword using PSFILE
;			HORIZONTAL = setup display in landscape mode
;				(longer side aligned with x-axis)
;			LANDSCAPE = setup display in landscape mode
;				(longer side aligned with x-axis)
;			VERTICAL = setup display in portrait mode
;				(longer side aligned with y-axis)
;			PORTRAIT = setup display in portrait mode
;				(longer side aligned with y-axis)
;
; OUTPUTS:		no explicit outputs.
;			New files/windows may be opened or screens erased 
;
; COMMON BLOCKS:	SCREENSMEM
;	
; SIDE EFFECTS:
;			New files/windows may be opened or screens erased 
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;	Ammended call to PSETUP to cater for updates in that routine
;		TJH Februrary, 1994,	IE, HFRD, DSTO
;
;-

common screensmem, alreadycalled, long,short

cols = !p.multi(1) > 1
rows = !p.multi(2) > 1
if (rows*cols eq 1) then pregion = [0.05,0.05,0.95,0.95] $
		    else pregion = !p.region
!p.multi(0) = 0

case n_params() of
	0	:begin
		 title1 = ' Plotting Data.....'
		 title2 = 'IDL Window '
		 end
	1	:title2 = title1
	else	: ;continue
endcase

horiz=0
if (keyword_set(horizontal)) then horiz=1
if (keyword_set(vertical)) then horiz=0
if (keyword_set(landscape)) then horiz=1
if (keyword_set(portrait)) then horiz=0

if (keyword_set(same) and n_elements(alreadycalled)) then $
	what = 'something_else' else what = strupcase(!d.name)

!p.region = pregion

ans = ' ' 
case what of
        'X'   : begin
		if (horiz) then $
		     window,/free,title=title2,xsize=680,ysize=510,retain=2 $
		else window,/free,title=title2,xsize=510,ysize=680,retain=2
		print,'		.... plotting data to X-Window '
		;device,font='8x16'
		;device,font='-adobe-times-medium-r-normal--17-120-100-100-p-84-iso8859-1'

                print,title1
                end
        'SUN' : begin
		if (horiz) then window,/free,title=title2,xsize=800,ysize=600 $
		else window,/free,title=title2,xsize=600,ysize=800
		print,'		.... plotting data to SunView-Window '
                print,title1
                end
        'TEK' : begin
		!p.font = 0
                read,ans
                erase
                end
	'PS'  : begin
		print,'		.... plotting data to PostScript file'
		if (horiz) then $
			psetup,next=keyword_set(next),/landscape,$
				longside=long,shortside=short $
		else	psetup,next=keyword_set(next),/portrait,$
				longside=long,shortside=short 
		print,title1
		!p.region = [0.,0.,0.,0.]
		end
	'HP'  : begin
		print,'		.... plotting data to HP-GL file'
		print,title1
		end
	'NULL': begin
		print,'		.... Null plot-device, not plotting data '
		print,title1
		end
        else  : print,title1
endcase

alreadycalled = 1

return
end


