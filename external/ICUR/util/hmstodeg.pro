;*************************************************************************
function HMStoDEG,hh,m,s,stp=stp
if n_params(0) eq 1 then case 1 of
   ifstring(hh): begin              ;hh:mm:ss
      nn=n_elements(hh)
      h=intarr(nn) & m=h & s=fltarr(nn)
      for i=0,nn-1 do begin
         x=str_sep(hh(i),':')
         if strmid(x(0),0,1) eq "'" then begin
            x(0)=strmid(x(0),1,5)
            sl=strlen(x(2))
            x(2)=strmid(x(2),0,sl-1)
            endif
         h(i)=fix(x(0))
         if n_elements(x) eq 3 then begin
            m(i)=fix(x(1))
            s(i)=float(x(2))
            endif else m(i)=float(x(1))
         endfor
      end
   else: begin
      if n_elements(hh) lt 3 then s=0. else s=hh(2)
      if n_elements(hh) lt 2 then m=0. else m=hh(1)
      h=hh(0)
      end
   endcase else h=hh
;
if n_elements(s) eq 0 then s=0.
if n_elements(m) eq 0 then m=0.
if n_elements(h) eq 0 then h=0.
a=h*15.+m/4.+s/240.
if keyword_set(stp) then stop,'HMStoDEG>>>'
return,a
end
