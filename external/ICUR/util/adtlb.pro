;*******************************************************************************
pro adtlb,a,d,l,b,rad=rad,prt=prt,epoch=epoch
if n_params() lt 4 then prt=1
;
if keyword_set(rad) then ra=a/!radeg else ra=a
if keyword_set(rad) then dec=d/!radeg else dec=d
if n_elements(epoch) eq 0 then epoch=2000.
;
sv_quiet = !quiet & !quiet = 1	;Don't display compiled procedures
yeari = 1950.0  & yearf = 1950.0  ;Default equinox values except for Precession
selection=1    ;2 is lb->ad
;
if epoch NE 1950 then precess, ra, dec, epoch, 1950
euler, ra, dec, newra, newdec, selection
if epoch NE 1950 then precess, newra,newdec, 1950, epoch
if newra LT 0 then newra = newra + 360.
;
l=newra & b=newdec
;
if keyword_set(prt) then print,' L, B = ',string(l,'(F8.4)'),string(b,'(F9.4)')
;
return
end            
