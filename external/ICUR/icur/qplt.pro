;****************************************************
pro qplt,nrecs,file,smth,lambda=lambda,trunc=trunc,notitle=notitle,ieb=ieb, $
   title=title,hc=hc,helpme=helpme
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,'QPLT,nrecs,file,smth'
   print,'*   nrecs: record numbers'
   print,'*   file : name of .ICD file '
   print,'*   smth : smoothing in A (gaussian). 0 (no smoothing) is default'
   print,'*  ** set nrecs negative to plot to screen, -1000 to plot record 0'
   print,'*'
   print,'* KEYWORDS:'
   print,'*    LAMBDA: 2 word vector containing wavelength range to plot'
   print,'*    TRUNC: set to force !YMIN=min flux'
   print,'*    NOTITLE: set to suppress plot title'
   print,'*    TITLE: main title for plot'
   print,'*    IEB:   set to plot error bars'
   print,'*    HC:    set for hard copy, -1 to suppress plot print'
   return
   endif
common com1,h,ik,ift,v,c,ndat,ifsm,kblo,h2,ipdv,ihcdev
common comxy,xcur,ycur,zerr,resetscale,lu3
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata
pdv=!d.name
hcdv='ps'
if n_elements(icurdata) eq 0 then icurdata=''
if strlen(icurdata) eq 0 then icurdata=getenv('icurdata')
if n_elements(userdata) eq 0 then userdata=''
if strlen(userdata) eq 0 then userata=getenv('userdata')
nrecs=fix(nrecs)
if not keyword_set(trunc) then trunc=0 else trunc=1
if n_params(0) lt 3 then smth=0.
if not keyword_set(lambda) then begin 
   l1=0. & l2=0.
   nolen=1 
   endif else begin
   l1=lambda(0) & l2=lambda(1)
   nolen=0
   endelse
;
if n_params(0) lt 2 then begin
   in=''
   read,' enter input file name',in
   endif else in=file
;
searchdir,in,'.icd'
print,'Data file:',in
s=strlen(in)
s=size(nrecs)
if s(0) eq 0 then nrecs=intarr(1)+nrecs
nrecs=abs(nrecs)
n=n_elements(nrecs)
;openw,lu3,'NL0:',/get_lun
!p.noclip=0     ;ignore=-1
if keyword_set(hc) then sp,hcdv else sp,pdv
dvplt=!d.name
svp
;
;setup
;
!x.title='!6Angstroms'
!y.title=ytit(0)
if keyword_set(ieb) then ieb=1 else ieb=0
iiue=0
!x.range=[l1,l2]
;
for i=0,n-1 do begin
   gdat,in,h,w,f,e,nrecs(i)
   if n_elements(h) lt 3 then return
   ncam=h(3)
   if (ncam eq 10) and (h(12) gt 87) then kiids=-1 else kiids=1
   dw=w(2)-w(1)
   case 1 of
      (ncam le 4) and (dw ge 1.): mt='!6IUE lo '
      ncam/10 eq 1: if kiids eq 1 then mt='!6KPNO IIDS ' else mt='KPNO Goldcam '
      (ncam le 4) and (dw ge 1.): mt='!6IUE hi '
      ncam/10 eq 3: begin
         mt='!6KPNO Coude '
         !y.title=ytit(1)
         end
      ncam/10 eq 4: begin
         mt='!6MMT echelle '
         !y.title=ytit(1)
         end
      ncam/10 eq 5: begin
         mt='!6NESSIE '
         !y.title=ytit(0)
         end
      ncam/10 eq 6: mt='!6Echelle '
      ncam eq 100: mt='!6GHRS '
      else: mt='!6 '
      endcase
   if ncam le 4 then iiue=1
   if (ncam/10 le 3) then ieb=0    ;error bars not available
   if iiue eq 1 then ieb=0    ;error bars not available
;
   if nolen eq 1 then begin
      l1=w(0) & l2=max(w)
      endif
   if trunc eq 1 then begin
      k=where((w gt l1) and (w lt l2),ck)
      if ck eq 0 then begin
         print,' invalid wavelength range specified'
         print,' Limits specified=',l1,l2
         print,'     Data limits =',w(0),max(w)
         return
         endif else !y.range=[min(f(k)),max(f(k))]
      endif
   ncam=h(3)/10
   mtitle=strtrim(byte(h(100:159)>32),2)
   date=strtrim(h(10),2)+'/'+strtrim(h(11),2)+'/'+strtrim(h(12),2)
   case 1 of
      iiue eq 1: begin
         imno=h(4)
         if imno lt 0 then imno=imno+65536L
         imno=strtrim(string(imno),2)
         !p.title=mt+strmid('    LWP LWR SWP SWR ',h(3)*4,4)+imno
         end
      ncam eq 100: !p.title=mt+strtrim(nrecs(i),2)+':'+date+' '+strtrim(h(4),2)+'-'+mtitle
      else: !p.title=mt+strtrim(nrecs(i),2)+':'+date+' '+mtitle
      endcase
   if smth ne 0. then rotvel,-1,w,smth
   if smth ne 0. then x=convol(f,c) else x=f
;   if (ncam eq 6) or (ncam eq 4) then x=x/h(5)    ;MMT data
   !c=-9
   if keyword_set(notitle) then !p.title=''
   if keyword_set(title) then !p.title=title
   plot,w,x,charsize=1.4
   if not keyword_set(notitle) then opdate,'QPLT'
   if iiue eq 1 then begin   ;overplot bad data points
     kbad=where(e lt -201)
     tkp,7,w(kbad),x(kbad)
     endif
   if ieb eq 1 then begin
      sig=f/e
      ;sig=convol(sig,c)
      ploterb,w,x,sig,1
      endif
   if keyword_set(hc) then begin
      if hc ge 0 then lplt,dvplt
      if hc lt 0 then lplt,dvplt,/noplot
      endif
   !y.range(*)=0.
   endfor
sp,pdv
close,3
return
end
