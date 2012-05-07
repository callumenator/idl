;************************************************************
pro cp_fitsext,fin,fout,extno,helpme=helpme,stp=stp,verify=verify
;
if n_params() lt 3 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* CP_FITSEXT - copy fits extensions'
   print,'* calling sequence: CP_FITSEXT,in,out,extno'
   print,'*   IN:    input file name'
   print,'*   OUT:   output file name'
   print,'*   EXTNO: extension number'
   print,'* '
   print,'* KEYWORDS:'
   print,'*   VERIFY: verify name of extension'
   print,' '
   return
   endif
if not ffile(fin) then begin
   print,'CP_FITSEXT: input file ',fin,' not found -- returning'
   if keyword_set(stp) then stop,'CP_FITSEXT>>>'
   return
   endif
if not ffile(fout) then begin
   print,'CP_FITSEXT: output file ',fout,' not found -- returning'
   if keyword_set(stp) then stop,'CP_FITSEXT>>>'
   return
   endif
next=fitsexts(fin,/quiet)
if extno gt next then begin
   print,'CP_FITSEXT: There are only ',next,' extensions in ',fin
   print,'            You requested extension ',extno
   if keyword_set(stp) then stop,'CP_FITSEXT>>>'
   return
   endif
;
d=mrdfits(fin,extno,h)
mwrfits,d,fout,h
if keyword_set(verify) then print, $
  ' Extension ',strtrim(extno,2),' ( ',strtrim(sxpar(h,'EXTNAME'),2),') copied'
;
if keyword_set(stp) then stop,'CP_FITSEXT>>>'
return
end
