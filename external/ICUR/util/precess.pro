;***************************************************************************
pro precess,h,m,s,dd,dm,ds,e1,e2,helpme=helpme,hms=hms,noprint=noprint, $
   degrees=degrees
; precess using H,M,S,D,DM,DS
np=n_params(0) & npe=np
; NP=8 all passed
; NP=7 e2=e1+50
; NP=6 e1=1950. & e2=2000.
; Np=2,3,4 - same as 6,7,8
;
if np lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* PRECESS - precession routine'
   print,'*    calling sequence: PRECESS,h,m,s,dd,dm,ds,e1,e2
   print,'*                  or: PRECESS,ra,dec,e1,e2
   print,'*    H,M,S,DD,DM,DS or RA,DEC:   coordinates at epoch E1
   print,'*    E1:       initial epoch, default=1950.0
   print,'*    E2:       final epoch, default=E1+50.0
   print,'*'
   print,'*    KEYWORDS:
   print,'*           HMS: set to convert input RA,DEC to output HMS DMS'
   print,'*       NOPRINT: do not print to screen if set'
   print,' '
   return
   endif

;
if keyword_set(hms) and (np gt 2) then np=2
if np gt 4 then begin    ;coordinates passed as H,M,S,D,M,S
   ra=hmstodeg(h,m,s)
   dec=dmstodeg(dd,dm,ds)
   endif else begin      ;coordinates passed as decimal degrees
   RA=h
   dec=m
   if npe gt 2 then e1=s
   if npe gt 3 then e2=dd
   endelse
;
if (npe eq 2) or (npe eq 6) then e1=1950.0    ;default initial epoch
if (npe eq 3) or (npe eq 7) then e2=e1+50.0   ;default final epoch
if (npe eq 2) or (npe eq 6) then e2=e1+50.0   ;default final epoch
;
precess2,ra,dec,e1,e2
;
outdeg=1
case 1 of
   keyword_set(degrees): begin
      h=ra & m=dec & s=e1 & dd=e2
      end
   ((np gt 4) or (keyword_set(hms))): begin
      degtohms,ra,h,m,s
      degtodms,dec,dd,dm,ds
      outdeg=0
      end
   else: begin
      h=ra & m=dec & s=e1 & dd=e2
      end
   endcase
if keyword_set(noprint) then return    ;do not print to screen
;
;fi='(I3)'
;ff='(F6.1)'
;print,' '
;if n_elements(h) eq 1 then begin
;   case 1 of
;      outdeg eq 0: print, $
;       'Equinox ',string(e2,ff),' coordinates:',string(h,fi),string(m,fi),' ', $
;      string(s,'(F6.3)'),string(dd,'(I5)'),string(dm,fi),' ',string(ds,'(F5.2)')
;      else: print,'Equinox ',string(e2,ff),' coordinates: ' $
;            ,string(ra,'(F7.3)'),string(dec,'(F8.3)')
;      endcase
;   endif
;
return
end
