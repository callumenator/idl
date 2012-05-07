;********************************************************************
function make_mask,nx,ny,xc,yc,rad=rad,seg=seg,neg=neg
;
if not keyword_set(rad) then rad=5.
if n_elements(nx) eq 0 then nx=512
if n_elements(ny) eq 0 then ny=512
if n_elements(xc) eq 0 then xc=nx/2
if n_elements(yc) eq 0 then yc=ny/2
;
arr=bytarr(nx,ny)
x1=long(xc-rad) & x2=long(xc+rad+1)
y1=long(yc-rad) & y2=long(yc+rad+1)
;
nsx=x2-x1 & nsy=y2-y1
subarr=fltarr(nsx,nsy)
for i=0,nsy-1 do subarr(*,i)=sqrt((indgen(nsx)-xc+x1)^2+(i-yc+y1)^2)
k=where(subarr le rad,nk)
subarr=bytarr(nsx,nsy)
if nk gt 0 then subarr(k)=1b else subarr(xc-x1,yc-y1)=1b
if keyword_set(seg) then begin
   nseg=n_elements(seg)
   if nseg gt 1 then begin    ;>1 segment
      nbad=nseg-fix(total(seg))
      badi=-1
      if nbad gt 0 then begin    ;>some zero segments
         s2=subarr*0b+1b
         ndeg=360./nseg             ;degrees per segment
         ldeg=ndeg*where(seg eq 0)
         udeg=ldeg+ndeg
         subarr2=fltarr(nsx,nsy)
         for iy=-rad,rad do begin            ;all y
            for ix=-rad,-1 do subarr2(ix+rad,iy+rad)=atan(iy,ix)*!radeg
            for ix=1,rad do subarr2(ix+rad,iy+rad)=atan(iy,ix)*!radeg
            endfor
         subarr2(rad,0:rad)=-90. & subarr2(rad,rad+1:*)=90.     ;avoid atan(0,0)
         subarr2=subarr2+180.
         for i=0,nbad-1 do begin
            k=where((subarr2 ge ldeg(i)) and (subarr2 lt udeg(i)),nk)
            if nk gt 0 then badi=[badi,k]
            endfor
         badi=badi(1:*)
         s2(badi)=0b
         subarr=subarr*s2
         endif
      endif     ;nseg>1
   endif        ;seg
; take care of sources at edge...
if x1+nsx gt nx then subarr=subarr(0:nx-x1-1,*)
if y1+nsy gt ny then subarr=subarr(*,0:ny-y1-1)
if y1 lt 0 then begin
      subarr=subarr(*,abs(y1):*)
      y1=0
      endif
if x1 lt 0 then begin
      subarr=subarr(abs(x1):*,*)
      x1=0
      endif
arr(x1,y1)=subarr
;
if keyword_set(neg) then arr=(not arr)-254b
return,arr
end
