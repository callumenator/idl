;**********************************************************************
PRO RWAVE,W,F                           ; RESET WAVELENGTH SCALE
COMMON COM1,H,IK,IFT,NSM,C
COMMON COMXY,Xcur,Ycur
common icurunits,xunits,yunits,title
H0=H
PRINT,' RWAVE options:'
print,' 0: quit'
print,' 1: wavelength shift'
print,' 2: velocity shift'
print,' 3: rebin'
print,' other: 1+3'
read,' Enter option: ',IZERO
if izero le 0 then return
if izero eq 3 then begin    ;rebin to new dispersion
   disp=w(1)-w(0)
   z='dispersion = '+strtrim(disp,2)+XUNITS+'/bin, Enter new value'
   print,z & read,disp2
   if (disp2 le 0.) or (disp2 eq disp) then return   ;no change
   nbins=fix(disp/disp2*n_elements(w))
   w1=w(0)+disp2*findgen(nbins)
   f=interpol(f,w,w1)
   w=w1
   h(22)=fix(disp2) & h(23)=10000*(disp2-fix(disp2))
   return
   endif
case 1 of
   IZERO eq 1: NIT=0 
   IZERO eq 2: NIT=0 
   ELSE: NIT=1
   endcase
ZTIME=' first  second'
LAM=FLTARR(2)
NLAM=FLTARR(2)
IPOS=FLTARR(2)
FOR I=0,NIT DO BEGIN
;   H=0
   PLDATA,-2,W,F
   IF nit eq 0 THEN ZS='' ELSE ZS=STRMID(ZTIME,I*7,7)
   Z=' Set cursor at'+ZS+' wavelength reference   '
   print,z
   BLOWUP,-1
   LOCATE,2,W,F
   print,z
   BLOWUP,-1
   LAM(I)=XCUR
   i1=xindex(w,lam(i))            ;TABINV,W,LAM(I),I1
   IPOS(I)=I1
   Z=' Old wavelength='+strtrim(string(LAM(I),'(F9.3)'),2)+'  '
   Z=Z+' Enter correct wavelength  (0 if OK, <0 to quit): '
   print,z
   READ,L0
   IF L0 LE 0. THEN return              ;bail out on negative wavelength
   if l0 eq 0 then nlam(i)=lam(i) else NLAM(I)=L0
   ENDFOR
DL=NLAM(0)-LAM(0)
nw=n_elements(w)
case 1 of
   izero eq 1:begin     ;wavelength offset
      PRINT,' Shift=',DL
      W=W+DL
      END
   izero eq 2: begin       ;velocity shift
      v=2.99792E5*dl/l0
      z=1.D0+(dl/l0)
      wnew=double(w)*z
      w1=wnew(0)+dindgen(nw)*(2.*wnew(nw-1)-wnew(nw-2)-wnew(0))/nw
      f1=interpol(f,wnew,w1)
      w=float(w1)
      F=float(F1)
      print,'v=',v,'km/s; z=',z
      end
   else: begin      ; SHIFT DISP; W0
      DX=ABS(IPOS(1)-IPOS(0))
      DISP0=ABS(LAM(1)-LAM(0))/DX
      DISP1=ABS(NLAM(1)-NLAM(0))/DX
      W0=NLAM(0)-IPOS(0)*DISP1
      DW0=W0-W(0)
      PRINT,' Old,new dispersions=',disp0,disp1,' ; zero pt offset=',DW0
      W=W0+FINDGEN(nw)*DISP1
      END
   endcase
H=H0
RETURN
END
