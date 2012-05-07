;***************************************************************************
pro bigplot,id,w,f,e,bw,bf              ; PLOT MULTIPLE SPECTRAL REGIONS
;vax version
common com1,hd,ik,ift,nsm,c,ndat,ifsm,kblo
common comxy,xcur,ycur,zerr
; read input data
inrec=-9
print,' '
files=''
i1='x'
print,' Enter file, record # for each spectrum (CR,-1 to end)'
while i1 ne '' do begin
   read,i1,i2
   files=[files,i1]
   inrec=[inrec,i2]
   endwhile
k=where (files ne '')
files=files(k) & inrec=inrec(k)
k=where (inrec ge 0)
files=files(k) & inrec=inrec(k)
n=n_elements(files)
if n le 0 then return
id=100
READ,' Enter wavelength range',x1,x2
READ,' Enter Ymax', y2
setxy,x1,x2,0.,y2
l=x2-x1
maxbin=l/4096.
; 4096 bins maximum
print,' Minimum bin size=',maxbin,' A'
READ,' Enter bin size (A), or # pts (>1000)',dl
if dl ge 1000 then nbins=fix(dl) else nbins=l/dl
nbins = fix(nbins < 4096)
dl=l/float(nbins)
print,'$I5',nbins,' points to be plotted, dispersion= ', dl
w=x1+dl*findgen(nbins) & f=fltarr(nbins) & e=intarr(nbins)+100
nd=intarr(nbins)
h=intarr(1022)
H(0)=100
h(3)=1000   ;ncam
h(7)=nbins
h(34)=n
hd=h
FUN3,0,0,0,H,HD   ;new title
for i=0,n-1 do begin
   gdat,files(i),h1,w1,f1,e1,inrec(i)
   np=n_elements(w1)
   i1=fix(xindex(w,w1(0)))     ;first point           ;tabinv,w,w1(0),i1
   i2=xindex(w,w1(np-1))           ;tabinv,w,w1(np-1),i2
   tw=w1(0)+dl*findgen(I2-I1+1)   ;section of big vector
   rrebin,tw,w1,f1,e1
   np=n_elements(f1)
   NDT=INTARR(NP)+1
   K=WHERE(E1 LT -201,ck)
   if ck gt 0 then begin
      f1(k)=0. & ndt(k)=0
      endif
   t=f(i1:i1+np-1)+f1
   f(i1)=t
   t=nd(i1:i1+np-1)+NDT
   nd(i1)=t
   t=e(i1:i1+np-1)<e1
   e(i1)=t
   endfor
f=f/(float(nd)>1.)
K=WHERE((F EQ 0.0) AND (E EQ 100))  ;NO DATA
E(K)=0  ;E=0 IF NO DATA
bdata,hd,-1,w,f,e,bw,bf
pldata,0,w,f,bw,bf,/bdata
return
end
