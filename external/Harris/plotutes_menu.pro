;-----------------------------------------------------------------------------
		pro plotutes_menu,ps,image=image
;+
; NAME:			plotutes_menu
;
; PURPOSE:		provides a simple menu of often used plot utilities
;
; CATEGORY:		plot utility
;
; CALLING SEQUENCE:	plotutes_menu
;			plotutes_menu,ps,IMAGE=image
;
; INPUTS:
;   OPTIONAL PARAMETERS:
;			IMAGE	= image array that the colour functions can use
; OUTPUTS:
;
;   OPTIONAL PARAMETERS:
;			ps  = 	flag denoting that PostScript plotting has 
;				been selected
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:		can change colour tables etc...
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	title = ' Select an Option '
	dname = !d.name

	if (n_elements(ps) le 0) then ps = -1

start:
	CASE (1) OF
		ps lt 0:	devtext = ' -------------------------- '
		ps eq 0:	devtext = ' Set Plot Device to PostScript '
		ps gt 0:	devtext = ' Close PostScript File ' 
	ENDCASE

	menutxt = [' LOAD favourite color table',$
		' Make BackGround WHITE ',$
		' SELECT from normal color tables',$
		' SELECT from special color tables',$
		' Histogram EQUALISE colour table',$
		' Dynamically ADJUST colour intensity',$
		' Dynamically adjust colour PALETTE',$
		' REVERSE colour table',$
		' SAVE current colour table to file ',$
		' RESTORE colour table from file ',$
		' ZOOM image ',' CLEAR plot screens',$
		' open SINGLE plot screen ',$
		' DUMP WINDOW to xwd file ',$
		' Load SPECIAL Screens ',$
		' Toggle PS Encapsulation',$
		' Toggle PS Colour plotting',$
		devtext,' HALT ']
	
	index = choice(menutxt,/index,title=title)

	CASE (index) OF

	18: stop
	17: begin
		CASE (1) OF
			ps lt 0: ;continue
			ps eq 0:begin
				ps = 1
				print,'.... Plot Device set to PostScript'
				end
			ps gt 0:begin
				ps = 0
				if (dname eq 'PS') then begin
					device,/close
					print,'.... Closed PostScript file '
				endif
				end
		ENDCASE
	   end
	16: pscolour
	15: encaps
	14: special_screen
	13: begin
		if (dname ne 'X') then begin
			print,'.... Sorry, this option only works under X-Windows'
		endif else begin
			set_plot,'null'
			answer = choice('*.xwd data/*.xwd',/findfl,$
				title=' Current Files are:',$
				question=' Enter the filename to DUMP X-window to (or choose a number) -- ')
			if (answer eq ' ') then answer = ''
			if (strpos(answer,'No File') ge 0) then $
				answer = 'wdplots.xwd'
			if (strpos(strupcase(answer),'.XWD') lt 0) then $
				answer = answer+'.xwd'
			if (strupcase(!version.os) eq 'VMS') $
			then	spawn,'xwd '+basename(answer) $
			else	spawn,['xwd','-out',answer],/noshell
			set_plot,dname	
		endelse	
	   end
	12: begin
		loadct,4
		single_screen
	   end
	11: clear
	10: zoom
	9: begin
		ctfile = choice('*_ct.dat data/*_ct.dat',/findfl,title='Select a Colour Table file')
		if (strpos(ctfile,'No File') lt 0) then begin
			restore,file=ctfile
			tvlct,r,g,b
		endif else print,'....Colour Table unchanged...'
	   end
	8: begin
		tvlct,r,g,b,/get
		save,/xdr,r,g,b,file='current_ct.dat'
	   end
	7: stretch,!d.n_colors,0
	6: palette
	5: adjct
	4: if (keyword_set(image)) then hist_equal_ct,image else hist_equal_ct
	3: begin
		;loadct,get_names=menutxt,file='IDL$LIBRARY:IE_colors.tbl'
		;index = 0
		;while (index ge 0) do begin
		;	index = choice(menutxt,/index)
		;	if (index ge 0) then loadct,index,file='IDL$LIBRARY:IE_colors.tbl';
		;endwhile
		ieloadct
	   end
	2: begin
		loadct,get_names=menutxt
		index = 0
		while (index ge 0) do begin
			index = choice(menutxt,/index)
			if (index ge 0) then loadct,index
		endwhile
	   end
	1: whitebg
	0: begin
		loadct,5 & stretch,255,0 & whitebg
	   end
	else: return
	ENDCASE

	goto,start

	end
