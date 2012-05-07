;**************************************************************************
function filtspec,flux,eps,smlen       
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H2,ipdv,ihcdev
COMMON COMXY,icurX,icurY,ZERR
case 1 of
   n_params(0) le 0: return,0
   n_params(0) eq 1: begin
      smlem=21
      eps=flux*0+100
      end
   n_params(0) eq 2: begin
      if n_elements(eps) le 1 then begin
         smlen=eps
         eps=flux*0+100
         endif else smlen=21
      end
   else:
   endcase
;
f=flux
if (nsm gt 2) and (nsm lt 1000) then f=smooth(flux,nsm)
if n_elements(c) gt 1 then f=convol(f,c)
;
if strupcase(ipdv) eq 'X' then opstat,'  Waiting'
z='FILTSPEC: 0 (def): optimal, 1: max, 2: min'
print,z
blowup,-1
if strupcase(ipdv) eq 'X' then opstat,'  Working'
case 1 of
   zerr eq 49: ff=smooth(maxfilt(f,eps),smlen)
   zerr eq 50: ff=smooth(minfilt(f,eps),smlen)
   else:       ff=optfilt(f,eps)
   endcase
;
bell,1
ndat=1
return,ff
END
