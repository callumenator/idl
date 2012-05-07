;*************************************************************************
pro vmerge,h1,w1,f1,e1,h2,w2,f2,e2,head,w,f,e,etype=etype,weight=weight, $
    wtype=wtype,cut=cut
;
; called from SPECMERGE, RD_IUEHI, ICD_TO_FULL
;
if n_elements(wtype) eq 0 then wtype=0
if n_elements(cut) eq 1 then begin
   if cut gt 0 then begin
      n1=n_elements(w1)
      k=indgen(n1-2*cut)+cut
      w1=w1(k)
      f1=f1(k)
      e1=e1(k)
      n2=n_elements(w2)
      k=indgen(n2-2*cut)+cut
      w2=w2(k)
      f2=f2(k)
      e2=e2(k)
      endif
   endif
wav0=min(w1)<min(w2)
wav1=max(w1)>max(w2)
disp1=w1(1)-w1(0)
disp2=w2(1)-w2(0)
disp=disp1<disp2                            ;minimum dispersion
case 1 of
   (disp eq disp1) and (wav0 eq min(w1)): dx=1
   (disp eq disp2) and (wav0 eq min(w2)): dx=2
   else: dx=0
   endcase
np=long((wav1+disp-wav0)/disp)+1            ;number of points
if wtype gt 0 then begin
   np=wtype
   disp=(wav1-wav0)/np
   endif
w=wav0+disp*findgen(np)
f=w*0 & e=w*0
print,' W0, disp,np, dx =',wav0,disp,np,dx
ndat=intarr(np)
head=intarr(400)
if n_elements(h1) ge 3 then head(3)=h1(3)
head(7)=np
head(20)=fix(wav0)
head(21)=fix(head(19)*(wav0-head(20)))
head(22)=fix(disp)
head(23)=fix(head(19)*(disp-head(22)))
if n_elements(h1) ge 159 then t1=strtrim(byte(h1(100:159)>32b),2) else t1=''
if n_elements(h2) ge 159 then t2=strtrim(byte(h2(100:159)>32b),2) else t2=''
case 1 of
   (strlen(t1) gt 0) and (strlen(t2) gt 0): t1=strmid(t1+' + '+t2,0,60)
   strlen(t2) gt 0: t1=t2
   else:
   endcase
head(100)=fix(byte(t1))
;
if (n_elements(etype) eq 0) and (n_elements(h1) ge 33) then etype=h1(33)
if n_elements(h2) ge 33 then et2=h2(33) else et2=etype
if et2 ne etype then begin
   print,' VMERGE WARNING: etypes inconsistent',etype,et2
   weight=0
   endif
if etype lt 30 then weight=0
if min(e1) gt -200 then e1=abs(e1)
if dx eq 1 then begin
   fa=w*0. & ea=fa
   fa(0)=f1 & ea(0)=e1
   endif else begin
   fa=interpol(f1,w1,w)
   ea=interpol(e1,w1,w)
   endelse
nd=ndat*0+1 
k=where((w lt w1(0)) or (w gt max(w1)),nk)
if nk gt 0 then begin
   fa(k)=0 & ea(k)=0 & nd(k)=0 
   endif
ndat=ndat+nd
if keyword_set(weight) then begin
   case etype of
      30: sn=ea
      40: begin
             kea=where(ea eq 0.,nkea)
             if nkea gt 0 then ea(kea)=1.
             sn=fa/ea
             if nkea gt 0 then sn(kea)=0.
          end
      else:
      endcase
   sn=abs(sn)
   f=f+fa*sn
   weigh=sn
   endif else begin
   f=fa+f & e=e+ea*ea
   endelse
;
if min(e2) gt -200 then e2=abs(e2)
if dx eq 2 then begin     ;second spectrum fixes scale
   fa=w*0. & ea=fa
   fa(0)=f2 & ea(0)=e2
   endif else begin
   fa=interpol(f2,w2,w)
   ea=interpol(e2,w2,w)
   endelse
nd=ndat*0+1 
k=where((w lt w2(0)) or (w gt max(w2)),nk)
if nk gt 0 then begin
   fa(k)=0 & ea(k)=0 & nd(k)=0 
   endif
ndat=ndat+nd
if keyword_set(weight) then begin
   case etype of
      30: sn=ea
      40: begin
             kea=where(ea eq 0.,nkea)
             if nkea gt 0 then ea(kea)=1.
             sn=fa/ea
             if nkea gt 0 then sn(kea)=0.
          end
      else:
      endcase
   sn=abs(sn)
   f=f+fa*sn
   e=sqrt(weigh*weigh+sn*sn)    ;S/N vector
   weigh=weigh+sn
   k=where(weigh eq 0.,nk)
   if nk gt 0 then weigh(k)=1.
   f=f/weigh
   if nk gt 0 then f(k)=0.
   if etype eq 40 then begin
      ke=where(e eq 0.,nke)
      if nke gt 0 then e(ke)=1.
      e=f/e    ;error bar
      if nke gt 0 then e(ke)=0.
      endif
   endif else begin
   f=fa+f & e=e+ea*ea
   e=sqrt(e)/(ndat>1)
   f=f/(ndat>1)
   endelse
return
end
