;***************************************************
pro ploterb,w,y,err,ierr,psym,type
; ierr=1 to oplot +/- 1 sigma errors
; ierr=2 to oplot SNR
; ierr=3 to do both 
;
if n_params(0) lt 2 then begin
   print,' '
   print,'* PLOTERB - overplot error bars'
   print,'*    calling sequence: PLOTERB,x,y,err,ierr,psym,type
   print,'*        X,Y: X,Y vectors'
   print,'*        ERR: vector of 1 sigma errors'
   print,'*       IERR: 1 (default) to overplot error bars'
   print,'*             2 to overplot S/N vector'
   print,'*             3 =1+2'
   print,'*       PSYM: symbol for error bars, default=0'
   print,'*       TYPE: 1 (default) to plot error bars, 0 to oplot EB range'
   print,' '
   return
   endif
;
plot,w,y
sn=y/err    ;signal to noise
ps=!p.psym
if n_params(0) lt 4 then ierr=1
if (n_params(0) lt 5) and (ierr eq 1) then ps=0
if n_params(0) lt 6 then type=1
if (ierr eq 1) or (ierr eq 3) then begin
   !c=-1
   case 1 of
      type eq 1: begin     ;plot error bars
         n=n_elements(w)
         for k=0,n-1 do begin
            erx=[y(k)+err(k),y(k)-err(k)]
            wx=[w(k),w(k)]
            oplot,wx,erx,psym=ps
            endfor
         end
      else: begin     ;default type=0
         oplot,w,y+err,psym=ps
         oplot,w,y-err,psym=ps
         end
      endcase
   endif
if (ierr eq 2) or (ierr eq 3) then oplot,w,sn,psym=ps
return
end
