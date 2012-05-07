;****************************************************************************
pro FFINFLUX,igo 
; called by FFIT2
; determines integrated fluxes
COMMON CFT,X,Y,SIG,E
common ffits,lu4
if n_elements(lu4) eq 0 then lu4=-1
imax=n_elements(x)
if n_params(0) eq 0 then igo=-1      ;igo not equal to -1 to query for fluxes
I1=0
I2=IMAX-1
WD=(X(IMAX-1)-X(0))/FLOAT(IMAX-1)
;
restart:
k=indgen(i2-i1+1)+i1
wsat=where(e lt -1750)
nsat=n_elements(wsat)
if wsat(0) eq -1 then nsat=0
flux=total(y(k))
sk=sig(k)
kbad=where(sk ge 998.)
if kbad(0) ne -1 then sk(KBAD)=0.
fer=total(sk*sk)
W1=X(I1)
W2=X(I2)
DW=W2-W1+WD
FLUX=FLUX*DW/FLOAT(I2-I1+1)
FER=SQRT(FER)*DW/FLOAT(I2-I1+1)
sw1=string(w1,'(F9.3)')
sw2=string(w2,'(F9.3)')
if lu4 gt 0 then printf,lu4,'*  Flux from',sW1,' to',SW2,' Ang. =',flux,' +/-',fer
print,' Flux from',SW1,' to',SW2,' Ang. =',flux,' +/-',fer
IF NSAT gt 0 then begin
   if lu4 gt 0 then printf,lu4,nsat,'*  SATURATED PIXELS INCLUDED'
   print,nsat,' SATURATED PIXELS INCLUDED'
   endif
;
if igo eq -1 then return
;
print,' WAVELENGTH RANGE ACCESSIBLE IS ',x(0),' TO  ',x(imax-1)
print,' ENTER RANGE OF INTEREST'
READ,W1
IF W1 LE 0. then RETURN
READ,W2
IF W2 LE W1 then begin
   t=w2
   w2=w1
   w1=t
   endif
W1=w1>X(0)
W2=w2<X(IMAX-1)
i1=fix(xindex(x,w1)+0.5)           ;tabinv,x,w1,i1
i2=fix(xindex(x,w2)+0.5)           ;tabinv,x,w2,i2
goto,restart
return
END
