;******************************************************************
pro icurspfilt,inp,recs,helpme=helpme,debug=debug
;
if n_params(0) eq 0 then inp=-1
if inp eq -1 then helpme=1
if ifstring(inp) eq 1 then begin   ;string passed
   file=inp
   inp=1
   endif
;
if keyword_set(helpme) then begin
   print,' '
   print,'* ICURSPFILT   filter out single point bad pixels'
   print,'* calling sequence: ICURSPFILT,file,recs'
   print,'*    input:'
   print,'*         FILE: name of .ICD file, -1 for help, blank for prompt'
   print,'*         RECS: record numbers to filter, default=all'
   print,'*    KEYWORDS:'
   print,'*       DEBUG: make plots of data before and after filtering'
   print,'*'
   print,'*    output:'
   print,'*         updated .ICD file. Individual bad pixels are set to the'
   print,'*         mean of the adjacent pixels.'
   print,' '
   return
   end
;
rdinp:
if inp eq 0 then begin
   file=''
   read,' Enter name of .ICD file',file
   endif 
;
if n_params(0) lt 2 then recs=indgen(1024)
np=n_elements(recs)
;
nstd=8.
for i=0,np-1 do begin   ;loop through spectra
   gdat,file,h,w,d,sn,i
   if n_elements(h) eq -1 then return          ;all done
   if keyword_set(debug) then begin
      plot,w,d
      d0=d
      endif
   spfilt,d,sn,nstd
   if keyword_set(debug) then begin
      oplot,w,d-0.1*mean(d)
      stop
      endif
   kdat,file,h,w,d,sn,i
   endfor        ;i
return
end
