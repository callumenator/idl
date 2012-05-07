;***********************************************************************
pro fffixlines,ncam
COMMON CFT,X,Y,SIG,E   
COMMON CURVE,A,EA,IFIXT
common ffits,lu4
np=n_elements(a)
nlines=(np-3)/3
if nlines le 0 then return
for i=0,nlines-1 do begin    ;are lines to be fixed here?
   klin=(i+1)*3+1
   if a(klin) lt 0 then begin
      IF NCAM EQ 10 then A(klin+1)=3.7      ;IIDS
      IF (NCAM EQ 20) OR (NCAM ge 30) then A(klin+1)=2.0
      A(klin)=ABS(A(klin))
      wl=lint(x,A(klin))
      print,' LINE AT ',wl,' A. ENTER proper wavelength, 0 to go on'
      READ,wnew
      if wnew gt 0. then begin
         Da=(WNEW-WL)/apb
         A(klin)=A(klin)+DA
         wl=lint(x,a(klin))
         print,' LINE FIXED AT BIN',a(klin),' WAVELENGTH=',wl
         endif
      endif
   endfor
return
end

