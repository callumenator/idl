;**********************************************************************
function dmstodeg,d0,dm,ds
if n_params(0) eq 1 then case 1 of
   ifstring(d0): begin              ;dd:mm:ss
      d0=strcompress(d0,/remove_all)
      nn=n_elements(d0)
      d=intarr(nn) & dm=intarr(nn) & ds=fltarr(nn)
      for i=0,nn-1 do begin
         x=str_sep(d0(i),':')
         if strmid(x(0),0,1) eq "'" then begin
            x(0)=strmid(x(0),1,5)
            sl=strlen(x(2))
            x(2)=strmid(x(2),0,sl-1)
            endif
         d(i)=fix(x(0))
         dm(i)=fix(x(1))
         if n_elements(x) eq 3 then ds(i)=float(x(2)) else ds(i)=0.0
         endfor
      end    ;string passed
   else: begin
      if n_elements(d0) lt 3 then ds=0. else ds=d0(2)
      if n_elements(d0) lt 2 then dm=0. else dm=d0(1)
      d=d0(0)
      end
   endcase else d=d0
if n_elements(ds) eq 0 then ds=0.
;   if n_elements(d) lt 3 then return,-999
;   dm=abs(d(1)) & ds=abs(d(2)) & d=d(0)
;   endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
s=size(d)
if s(0) eq 0 then begin     ;scalar
   IF D NE 0 THEN ISIGN=D/ABS(D) ELSE BEGIN  ;DEC=+/-0
      IF DM NE 0 THEN ISIGN=DM/ABS(DM) ELSE BEGIN   ;MIN=0
         IF DS NE 0 THEN ISIGN=DS/ABS(DS) ELSE ISIGN=1.
         ENDELSE
      ENDELSE 
   endif else begin          ;array
   isign=fltarr(n_elements(d))+1.
   k=where((d lt 0) or (dm lt 0) or (ds lt 0.))
   if k(0) ne -1 then isign(k)=-1.
   endelse
DELTA=ISIGN*(ABS(D)+ABS(DM)/60.+ABS(DS)/3600.)
return,delta
end
