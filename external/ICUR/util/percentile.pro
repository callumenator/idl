;********************************************************************
function percentile,image,pcts,srt=srt,hist=hist,time=time,prt=prt, $
         thresh=thresh,verbose=verbose,stp=stp,helpme=helpme
if n_elements(image) lt 4 then helpme=1
if n_elements(thresh) eq 0 then thresh=64000.
;
if keyword_set(helpme) then begin
   print,' '
   print,'* function PERCENTILE  -  returns percentile values of image'
   print,'* calling sequence: Z=PERCENTILE(IMAGE,PCTS)'
   print,'*    IMAGE: name of image array'
   print,'*    PCTS:   percentiles, def pcts(0)=0.01,pcts(1)=1.-pcts(0)'
   print,'*    Z:     output data values corresponding to percentiles'
   print,'* ' 
   print,'*   KEYWORDS:' 
   print,'*       HIST: use histogram sorting. Fast, but potentially inaccurate' 
   print,'*       SRT:  use SORT. Much slower'   
   print,'*             HIST is default if range > ',thresh
   print,'*       TIME: print elapsed time for operation' 
   print,'*       THRESH: maximum range in image for HIST mode, def=',thresh
   print,'*       PRT: print output values' 
   print,'*       VERBOSE: equivalent to /TIME, /PRT'   
   print,' '
   return,0 
   endif
;
if n_elements(pcts) eq 0 then pcts=0.01
if n_elements(pcts) eq 1 then pcts=[pcts,1.-pcts(0)]  ;make symmetric
npct=n_elements(pcts)
;
nim=n_elements(image)
t=systime(0)
if keyword_set(verbose) then begin 
   time=1
   prt=1
   endif
;
z=fltarr(npct)
if keyword_set(verbose) then print,' Percentiles:',pcts
range=max(image)-min(image)
case 1 of
   keyword_set(hist):
   keyword_set(srt):
   else: if range le thresh then srt=1 else hist=1
   endcase
;
case 1 of
   keyword_set(srt): begin 
      if keyword_set(verbose) then print,' Sort chosen' 
      k=sort(image)      
      for i=0,npct-1 do z(i)=image(k(nim*pcts(i)))
      end
   else: begin
      if keyword_set(verbose) then print,' Histogram chosen'
bs=fix(range/128000.)>1
;print,bs
;stop
      k=histogram(image,min=min(image),bin=bs)
      k=cumdist(k)
      for i=0,npct-1 do begin
         kk=where(k ge nim*pcts(i),nk)
         if nk gt 0 then z(i)=kk(0)+min(image) else z(i)=max(image)
         endfor
      end
   endcase
;
if keyword_set(time) then t_elapsed,t,/prt
if keyword_set(prt) then print,z
if keyword_set(stp) then stop,'PERCENTILE>>>'
k=0
return,z
end
