;**************************************************************************
function which_usno_cd,spd,notify=notify,band=band,helpme=helpme,a1=a1
; spd=south polar distance
if keyword_set(a1) then $
     cd=[1,1,6,5,3,2,1,4,6,5,7,10,8,7,8,9,9,4,10,3,2,6,2,3] else $
     cd=[1,1,9,7,5,4,3,2,1,6,7,10,9,8,8,11,10,11,6,4,2,3,3 ,2]   ;version A2.0
;
case 1 of
   keyword_set(helpme):
   n_elements(spd) gt 0: s=((fix(spd*10.)/75)>0)<23
   n_elements(band) eq 1: s=band
   else: helpme=1
   endcase
;
if keyword_set(helpme) then begin
   print,'*'
   print,'* WHICH_USNO_CD: determine which USNO A1 CD to mount '
   print,'* calling sequence: CD=WHICH_USNO_CD(spd,band=band)'
   print,'*   CD: CD number (1-10)'
   print,'*   SPD: south polar distance (degrees)'
   print,'*'
   print,'* KEYWORDS:'
   print,'*   A1:   set to use A1.0 CDs, default=A2.0
   print,'*   BAND: SPD/7.5 = declination band (0-23). Used if SPD undefined.'
   print,'*'
   return,-1
   endif
x=cd(s)
if keyword_set(notify) then print,' Please mount USNO disk ',string(x,'(I3)')
return,x
end
