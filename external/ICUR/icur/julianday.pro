;**********************************************************************
function julianday,mo,da,year,helpme=helpme,mjd=mjd
;updated from JULDATE
;  RESTRICTIONS:
;     Will not work for years between 0 and 99 A.D.  (since these are
;     interpreted as years 1900 - 1999).  Will not work for year 1582.
;     JULDATE,[1981,12,25.2673611],JD  --> JD = 44963.7673611
;  REVISION HISTORY
;    Adapted from IUE RDAF (S. Parsons)                      8-31-87
;    Algorithm from Sky and Telescope April 1981   
;    Modified by FMW
;
if n_params(0) eq 0 then mo=-1
if mo(0) eq -1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* JULIANDAY   -   compute julian day number'
   print,'*   calling sequence: JD=JULIANDAY(M,D,YR) or'
   print,'*                     JD=JULIANDAY(DOY,YR) or'
   print,'*                     JD=JULIANDAY(YR.mmdd)'
   print,'* '
   print,'* KEYWORDS: '
   print,'*    MJD: set to return JD=2,400,000. '
   print,' '
   return,0
   endif
;
np=n_params(0)
case 1 of
   (n_elements(mo) eq 3) and (np eq 1): begin
      m=mo(0) & d=mo(1) & yr=mo(2)
      np=3
      end
   np eq 3: begin
      m=mo & d=da & yr=year
      end
   np eq 2: begin
      m=mo & d=da
      end
   else: m=m0
   endcase
doy=0
t=m
;
case 1 of
   np eq 1: begin
      if ifstring(t) eq 1 then begin   ;yyyy.mmdd passed as string
         t=strtrim(t,2)
         k=strpos(t,'.')
         yr=fix(strmid(z,0,k))
         m=fix(strmiz(z,k+1,2))
         d=fix(strmiz(z,k+3,2))
         endif else begin             ;yyyy.mmdd passed as fp number
         yr=fix(t)
         t=(t-yr)*100.
         m=fix(t)
         t=(t-m)*100.
         d=fix(t)
         endelse
      end
   np eq 2: begin     ;doy,yr passed
      doy=m
      yr=d
      m=1
      d=doy
      end
   np eq 3:        ;m,d,yr passed
   else: return,0
   endcase
; 
IY = yr
IM = m
DAY = d
;
IF IM LT 3 THEN BEGIN   ;If month is Jan or Feb, don't include leap day
  IY= IY-1 & IM = IM+12 
  END
A= FIX(IY/100)
RY = FLOAT(IY)
IF IY LT 1582 THEN B = 0 ELSE B = 2 - A + FIX(A/4)
IF IY EQ 1582 THEN BEGIN
   PRINT,' YEAR 1582 NOT COVERED'
   RETURN,0 & END
JD= FIX(RY*0.25) + 365.*(RY -1860.) + FIX(30.6001*(IM+1.)) + B + DAY  - 105.5
;
if not keyword_set(mjd) then jd=jd+2400000.D0
RETURN,jd
END                                  ; JULDATE
