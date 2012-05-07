;-------------------------------------------------------------------
	pro date_sel, fulldates, currentdate,index=index,title=utitle

;+
; NAME:
;	DATE_SEL
;
; PURPOSE:
;	To allow interactive selection from a series of dates
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:
;	DATE_SEL, fullsetdates, currentdate, INDEX=index
;
; INPUTS:
;	fullsetdates = array(5,*) containing the full set of dates from
;		which the choice can be made. Must be an integer or real
;		array 5xNUMBERCHOICES.
;		The 5 elements are assumed to be [day,mth,year,hour,minutes]
;	currentdate = array(5) containing the current date selection
;	INDEX = will contain the index into fullsetdates for currentdate. 
;		If currentdate is not passed and index is a valid index 
;		then this determines the current date
;	TITLE = this will be the title displayed (replacing the default)
;
; OUTPUTS:
;	currentdate is updated (along with index)
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		March, 1991
;
;-

	days = 1.0
	t=[days,40.*days, 12.*40.*days, days/24., days/24.*3600.]

	if (n_elements(utitle) le 0) then utitle='Date'

	fmtstr = "(2(i2.2,'/'),i2.2,1x,2i2.2)"

	sz = size(fulldates)

	if ((sz(0) lt 2) or (sz(sz(0)) lt 2)) then begin
		index = 0
		currentdate = fulldates
	endif else begin
		if (sz(0) gt 2) then begin
			index = -1
			print,' The data array has more than 2 dimensions '
			return
		endif
		t = t(0:sz(1)-1)
		if (not keyword_set(index)) then index = -1
		if ((index ge 0)and(n_elements(currentdate) le 0)) then $
			currentdate = fulldates(*,index) $
		else begin
			if (n_elements(currentdate) le 0) then begin
				print,' Invalid input date '
				return
			endif
			higher = (where((t#fulldates) ge (total(currentdate*t))) < sz(2)-1) > 0
			index = higher(0)
		endelse

		def_index = index

select_type:	;present user with first menu to select how to select date

		menutxt = [' EXPLICIT ',' INCREMENTAL ',' by YEAR ',$
			   ' by MONTH ',' by DAY ',' by HOUR ',$
			   strtrim(string(currentdate,format=fmtstr))]
		title = ' Select type of entry for '+utitle+' selection'
		option = choice(menutxt,title=title,/index)

		case (option) of
		
		0: begin
			index= def_index
			currentdate = [-1,-1,-1,-1,-1]
			return
		   end
		1: begin
		   if (sz(2) le 20) then begin
			title = ' Choose a NEW '+utitle
			index = choice(fulldates,title=title,/index,def_sel=index)
			if (index lt 0) then index = def_index
			currentdate = fulldates(*,index)
		   endif else begin
			menutxt = ['    Previous MONTH ','    Previous DAY ',$
				   '    Previous HOUR ','    Previous POINT ',$
				   strtrim(string(currentdate,format=fmtstr)),$
				   '    Next POINT ','    Next HOUR ',$
				   '    Next DAY ','    Next MONTH ',$
				   '    RESET     ']
			title = ' Select an Option to Change Current '+utitle

			option = 4
			while (option ge 0) do begin
				menutxt(4) = ' Current '+utitle+' is '+strtrim(string(currentdate,format=fmtstr))
				option = choice(menutxt,title=title,/index,def_sel=option)

				case (option) of
					0:	select=1
					1:	select=0
					2:	select=3
					3:	index = (index-1) > 0
					4:	index = index
					5:	index = (index+1) < (sz(2)-1)
					6:	select=3
					7:	select=0
					8:      select=1
					9:	index = def_index
					else: ;continue
				endcase

				if (strpos('012',strcompress(option,/remove_all)) ge 0) then begin
				    repeat begin
					index = (index-1)>0 
					tmp1 = total(fulldates(*,index)*t)
					tmp2 = total(currentdate*t)-t(select)
				    endrep until ((tmp1 lt tmp2) or (index eq 0))
				endif
				if (strpos('678',strcompress(option,/remove_all)) ge 0) then begin
				    repeat begin
					index = (index+1)<(sz(2)-1) 
					tmp1 = total(fulldates(*,index)*t)
					tmp2 = total(currentdate*t)+t(select)
				    endrep until ((tmp1 gt tmp2) or (index eq (sz(2)-1)))
				endif
				if (index ge 0) then currentdate = fulldates(*,index)
			endwhile
		   endelse
		   option = -1
		   end
		2: select = 2
		3: select = 1
		4: select = 0
		5: select = 3
		else: return
		endcase

		if (strpos('2345',strtrim(string(option),2)) ge 0) then begin
				
			subset = where(fulldates(select,*) ne shift(fulldates(select,*),1),count)
			if (count gt 0) then begin
			  defindx = fix(where((t#fulldates(*,subset)) eq $
						(total(currentdate*t))))
			  defindx = defindx(0)
			  minshow = 87
			  title = ' Select the '+utitle
			  if (count le minshow) then begin
			    menutxt = strtrim(string(fulldates(*,subset),format=fmtstr))
			    index = choice(menutxt,title=title,/index,def_sel=defindx)
			    if (index ge 0) then index = subset(index)
			  endif else begin
			    lindex = min(abs(subset-index),i)
			    lindex = i
			    stshow = (lindex+1)
			    enshow = (lindex-1) 
			    while ((lindex eq stshow-1) or $
					(lindex gt enshow)) do begin
				stshow = (lindex-minshow/2) > 0
				enshow = (lindex+minshow/2+1) < count-1
				defindx = fix(where((t#fulldates(*,subset(stshow:enshow))) eq (total(currentdate*t))))
				defindx = defindx(0)
			    	menutxt = strtrim(string(fulldates(*,subset(stshow:enshow)),format=fmtstr))
				if (stshow gt 0) then begin
					menutxt=['more .... ',menutxt]
					offset = 1
				endif else offset = 0
				if (enshow lt count-1) then menutxt=[menutxt,'more .... ']
				lindex = choice(menutxt,title=title,/index,def_sel=defindx+offset)
				lindex = lindex+stshow-offset
			    endwhile
			    index = subset(lindex)
			  endelse
			endif else index = def_index

			print,' '
			print,'old date :',currentdate
			if (index ge 0) then currentdate = fulldates(*,index)
			print,'new date :',currentdate
		endif
		goto, select_type
	endelse

	return
	end
