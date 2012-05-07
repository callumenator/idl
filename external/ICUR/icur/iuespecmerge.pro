;**********************************************************************
pro iuespecmerge,w,f,e,r1,r2,f1,f2,wtype
if n_params(0) lt 4 then begin
   print,' '
   print,'* IUESPECMERGE - merge SW and LW spectra into one'
   print,'*    calling sequence: IUESPECMERGE,W,F,E,R1,R2,F1,F2,WTYPE'
   print,'*       W,F,E : output wavelength, flux, and epsilon vectors'
   print,'*       R1,R2 : input record numbers. R2 default=R1+1
   print,'*       F1,F2 : input file(s), def F2=F1, def F1=LODAT.DAT'
   print,'*       WTYPE : def=0 to splice W vectors, >0 to interpolate to WTYPE bins'
   print,' '
   return
   endif
;
if n_params(0) lt 5 then r2=r1+1
if n_params(0) lt 6 then f1='LODAT'
if n_params(0) lt 7 then f2=f1
if n_params(0) lt 8 then wtype=0
wtype=wtype>0
gdat,f1,h1,w1,f1,e1,r1
if n_elements(h1) eq 1 then begin
   print,' Record',r1,' of file ',f1,' not found: returning'
   endif
gdat,f2,h2,w2,f2,e2,r2
if n_elements(h2) eq 1 then begin
   print,' Record',r2,' of file ',f2,' not found: returning'
   endif
nc1=h1(3) & nc2=h2(3)
case 1 of
   (nc1 le 2) and (nc2 le 2): begin
      print,' Both spectra are LW - returning'
      return
      end
   (nc1 eq 3) and (nc2 eq 3): begin
      print,' Both spectra are SWP - returning'
      return
      end
   nc1 lt nc2: begin     ;reverse order
   t=w1 & w1=w2 & w2=t
   t=f1 & f1=f2 & f2=t
   t=e1 & e1=e2 & e2=t
   end
   else:
   endcase
;
if max(w1) gt 1950. then lim=1950. else lim=max(w1)
k1=where(w1 le lim)
k2=where(w2 gt lim)
case 1 of
   wtype eq 0: begin
      w=[w1(k1),w2(k2)]
      f=[f1(k1),f2(k2)]
      e=[e1(k1),e2(k2)]
      end
   else: begin
      r=max(w2)+w2(1)-w2(0)-w1(0)    ;wavelength range
      w=r*findgen(wtype)/wtype+w1(0)
      k=where(w ge lim) & k=k(0)
      fa=interpol(f1,w1,w(0:k-1))
      fb=interpol(f2,w2,w(k:*))
      ea=interpol(e1,w1,w(0:k-1))
      eb=interpol(e2,w2,w(k:*))
      f=[fa,fb]
      e=[ea,eb]
      end
   endcase
return
end
