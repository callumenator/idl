;***************************************************************************
pro fffitstat,chisq,iflag,bsca
COMMON CFT,X,Y,SIG,E
COMMON CURVE,A,EA,IFIXT
COMMON PLCR,YF
common ffits,lu4
common icurunits,xunits,yunits,title
if n_elements(lu4) eq 0 then lu4=-1
n=n_elements(x)
nterms=n_elements(a)
nlines=(nterms-3)/3
L1=1
CASE 1 OF
   nterms le 3: printf,lu4,'*  No lines fit'
   (NTERMS gt 3) and (nterms le 6): begin              ;1 line
      printf,lu4,'*  BEST FIT LINE INTENSITY=', $
            string(a(3),'(G10.3)'),' +/-',string(ea(3),'(g10.3)')
      print,'  BEST FIT LINE INTENSITY=',a(3),' +/-',Ea(3)
      IF NTERMS ge 5 then begin
         printf,lu4,'*  FIT BIN =',a(4),' +/-',ea(4),' ; GIVEN BIN',bsca
         print,' FIT BIN =',a(4),' +/-',ea(4),' ; GIVEN BIN',bsca
         IF NTERMS ne 5 then begin
            printf,lu4,'*  FIT HWHM=',a(5),' +/-',ea(5),' BINS'
            print,' FIT HWHM=',a(5),' +/-',ea(5),' BINS'
            endif            ;ne 5
         endif               ;ge 5
      end
   nterms gt 6: begin                                  ;2 or more lines
      while nlines ge 2 do begin
         l2=l1+1
         k1=l1*3
         k2=l2*3
         printf,lu4,'*  LINES',l1,' AND',l2
         printf,lu4,'*  LINE AMPLITUDES:', $
            string(a(k1),'(G10.3)'),' +/-',string(ea(k1),'(g10.3)'),'  ', $
            string(a(k2),'(G10.3)'),' +/-',string(ea(k2),'(g10.3)')
         printf,lu4,'*  LINE POSITIONS :', $
            string(a(k1+1),'(G10.3)'),' +/-',string(ea(k1+1),'(g10.3)'),'  ', $
            string(a(k2+1),'(G10.3)'),' +/-',string(ea(k2+1),'(g10.3)')
         printf,lu4,'*  LINE HWHMS     :', $
            string(a(k1+2),'(G10.3)'),' +/-',string(ea(k1+2),'(g10.3)'),'  ', $
            string(a(k2+2),'(G10.3)'),' +/-',string(ea(k2+2),'(g10.3)')
         nlines=nlines-2
         l1=l1+2
         endwhiLE
      if nlines eq 1 then begin      
         l2=l1+1
         k1=l1*3
         k2=l2*3
         printf,lu4,'*  LINE ',l1
         printf,lu4,'*  LINE AMPLITUDE:',a(k1),' +/-',ea(k1)
         printf,lu4,'*  LINE POSITION:',a(k1+1),' +/-',ea(k1+1)
         printf,lu4,'*  LINE HWHM:',a(k1+2),' +/-',ea(k1+2)
         endif
      end
   else:
   endcase
;   
schs=string(chisq,'(F8.3)')
printf,lu4,'*    CHI-SQUARE per degree of freedom:',schs
CHISQ=CHISQ*FLOAT(N-NTERMS)
sflag=string(iflag,'(I3)')
sn=string(n,'(I4)')
snt=string(total(ifixt),'(I3)')
schs=string(chisq,'(F9.3)')
printf,lu4,'*    Flag= ',sflag,'  Chi**2=',schs,'  Data points= ',sn,' Free parameters= ',snt
print,'*   Flag= ',sflag,'  Chi^2=',schs,'  ',sn,' Data points,',snt,' Free parameters'
;
NPL=6
imax=fix((nterms-1)/NPL)
SNPL=STRTRIM(NPL,2)
SF='G11.4'
fmt1='("",A,"A:",'+SNPL+'(" ",'+SF+'))'
fmt2='("     EA:",'+SNPL+'(" ",'+SF+'))'
for i=0,imax do begin
   s=string(i*npl,'(i2)')+'-'+string((i*npl+npl-1)<(nterms-1),'(i2)')+' '
   printf,lu4,S,a(i*NPL:(nterms-1)<(i*NPL+NPL-1)),format=fmt1
   printf,lu4,ea(i*NPL:(nterms-1)<(i*NPL+NPL-1)),format=fmt2
;   printf,lu4,'* ',S,' A:', a(i*NPL:(nterms-1)<(i*NPL+NPL-1))
;   printf,lu4,'*      EA:',ea(i*NPL:(nterms-1)<(i*NPL+NPL-1))
   endfor
;
RETURN
END
