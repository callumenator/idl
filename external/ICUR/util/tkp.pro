;***********************************************************************
PRO TKP,CH,X,Y,color=color                 ; UPDATED VERSION OF TEKPLOT
if (n_elements(x) eq 0) or (n_elements(y) eq 0) then return
if !y.type eq 1 then begin
   yu=10^!y.crange(1)
   yl=10^!y.crange(0)
   endif else begin
   yu=!y.crange(1)
   yl=!y.crange(0)
   endelse
PX=X
PY=Y
T=SIZE(PX)
IF T(0) EQ 0 THEN BEGIN
   PX=FLTARR(2)+X
   PY=FLTARR(2)+Y
   ENDIF
if n_elements(color) eq 0 then color=!p.color
OPLOT,PX,((PY>yl)<yu),psym=ch,color=color
RETURN
END
