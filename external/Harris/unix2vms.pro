;+
; NAME:		unix2vms
;
; PURPOSE:	This routine converts UNIX syntax filenames to VMS syntax
;		under VMS we must place all references to directories inside 
;		square brackets and separate with "." rather than simply 
;		separating everything with /
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	vmstxt = unix2vms(unixtxt)
;
; INPUTS:	unixtxt = string constant
;
; OUTPUTS:	vmstxt = string constant with any / replaced by [, ] or .
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		Sept, 1992.
;
;-
;under VMS we must place all references to directories inside square brackets 
;and separate with . (rather than simply separating with /)

	function unix2vms, txt

;only consider constants (NOT arrays)
usetxt = txt(0)
outtxt = ''
;change all , to " " for consistency
indx1 = 0
indx2 = strpos(usetxt,',',indx1+1)

WHILE (indx2 ge 0) do begin
	usetxt = strmid(usetxt,0,indx2)+' '+strmid(usetxt,indx2+1,999)
	indx1 = indx2
	indx2 = strpos(usetxt,',',indx1+1)
ENDWHILE

usetxt = strcompress(usetxt)

;separate into distinct names
word = 'START'
indx1 = 0
indx2 = strpos(usetxt,' ',indx1+1)

WHILE (indx2 ge 0) do begin
	word = [word,strmid(usetxt,indx1,indx2-indx1+1)]
	indx1 = indx2
	indx2 = strpos(usetxt,' ',indx1+1)
ENDWHILE

word = [word,strmid(usetxt,indx1,99)]
word = strcompress(word,/rem)
;print,word
;help,word

;remove dummy first element
word = word(1:*)

;now for each word, replace unix directory name structure with vms
;;; NOTE ONLY DO for FIRST word
;;;	as findfile doesnt seem to recognise more than one under VMS

;;;for i=0,n_elements(word)-1 do begin  
for i=0,0 do begin
	tmp = strcompress(word(i),/rem)
	;print,tmp
	;replace any [] with / so as not to upset environment var. inclusions
	indx2 = strpos(tmp,']') 
	while (indx2 ge 0) do begin
		if (strpos(strmid(tmp,indx2-1,3),'/') ge 0) then $
			tmp = strmid(tmp,0,indx2)+strmid(tmp,indx2+1,99)$
		else $
			tmp = strmid(tmp,0,indx2)+'/'+strmid(tmp,indx2+1,99)
		indx1 = indx2
		indx2 = strpos(tmp,']')
		;print,tmp
	endwhile
	indx2 = strpos(tmp,'[') 
	while (indx2 ge 0) do begin
		if (strpos(strmid(tmp,indx2-1,3),'/') ge 0) then $
			tmp = strmid(tmp,0,indx2)+strmid(tmp,indx2+1,99)$
		else $
			tmp = strmid(tmp,0,indx2)+'/'+strmid(tmp,indx2+1,99)
		indx1 = indx2
		indx2 = strpos(tmp,'[')
		;print,tmp
	endwhile
	indx1 = -1
	indx2 = strpos(tmp,'/')
	;replace / with . 
	while (indx2 ge 0) do begin
		if (strpos(strmid(tmp,indx2-1,3),'.') ge 0) then $
			tmp = strmid(tmp,0,indx2)+strmid(tmp,indx2+1,99)$
		else $
			tmp = strmid(tmp,0,indx2)+'.'+strmid(tmp,indx2+1,99)
		indx1 = indx2
		indx2 = strpos(tmp,'/')
		;print,tmp
	endwhile
	;replace first and last fields with a [. and ] (or [ if absolute)
	;(if any directory replacements have been done)
	if (strmid(strcompress(word(i),/rem),0,1) eq '/') then str = '[' $
	else str = '[.'

	;but always assume full path if have to add a ':'
	if ((indx1 gt 0) and (indx1 lt strlen(tmp))) then begin
		tmp = strmid(tmp,0,indx1)+']'+strmid(tmp,indx1+1,99)
		indx2 = strpos(tmp,':') 
		if (indx2 ge 0) then $
			tmp = strmid(tmp,0,indx2)+':['+strmid(tmp,indx2+2,99) $
		else    tmp = str+tmp
	endif
	if (indx1 eq 0) then tmp = strmid(tmp,1,99)
	outtxt = outtxt+','+tmp
endfor
	
outtxt = strmid(outtxt,1,999)

return,outtxt
end

