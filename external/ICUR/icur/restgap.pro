;**********************************************************************
pro restgap,h,w       ;restore gaps to hi dispersion data
ngap=h(900)
if !quiet ne 3 then begin
   if ngap le 0 then begin
      print,' No gaps stored, returning'
      return
      endif else print,ngap,' gaps stored'
   endif
;
for i=0,ngap-1 do begin
   w1=double(h(901+i*4))+double(h(902+i*4))/30000.
   dw=double(h(903+i*4))+double(h(904+i*4))/30000.
   k=where(w gt w1)
;   w2=w1+dw    ;wavelength at top of gap
;   dw1=dw
;   w0=w(k(0))
;   dw=w2-w0    ;actual offset
   w(k)=w(k)+dw
   endfor
return
end
