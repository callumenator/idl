;***************************************************
pro chlo,infile,outfile,r1,r2  ;change iue low dispersion format 0 to format 8
if n_params(0) eq 1 then begin
   if ifstring(infile) ne 1 then begin     ;not a string
      if infile eq -1 then begin
         print,' CHLO  : change ICUR data format 0 to 8'
         print,' call CHLO,infile,outfile,r1,r2'
         print,'        infile: input file name (format 0), default=LODAT'
         print,'       outfile: output file name (format 8), default=IUELO'
         print,'            r1: first record to transcribe, default=0'
         print,'            r2: last record, =r1 if r1 specified, 999 otherwise'
         return
         endif
      endif
   endif
if n_params(0) eq 0 then infile='LODAT'
infile=infile+'.DAT'
if n_params(0) lt 2 then outfile='IUELO'
if n_params(0) lt 3 then begin
   r1=0 & r2=999
   endif
if n_params(0) eq 3 then r2=r1       ;only one record
r1=(r1>0)
r2=(r2>r1)
on_ioerror,nofile
get_lun,lu
openr,lu,outfile+'.dat'
close,lu
goto,proceed
;
nofile:   openw,lu,outfile+'.dat/recs:1000',8196
;
proceed: close,lu
free_lun,lu
;
ws=1100.+findgen(900)   ;SWP wavelength vector
wl=1900.+1.5*findgen(934)   ;LWP/R wavelength vector
FOR I=r1,r2 do BEGIN
   on_ioerror,done
   GDAT,infile,h,w,f,e,i
   if n_elements(h) eq 1 then goto,done
   if n_elements(h) gt 1020 then h=h(0:1019)
   ncam=h(3)
   print,'record=',i,' NCAM=',ncam
   if ncam le 2 then begin    ;LWP/LWR
      w0=wl
      dl=1.5
      endif else begin
      w0=ws
      dl=1.0
      endelse
   f1=interpol(f,w,w0)
   e1=fix(interpol(e,w,w0))
   k=where(w0 le max(w))      ;valid points 
   w0=w0(k)
   f1=f1(k)
   e1=e1(k)
   h(20)=fix(w0(0))
   h(21)=1000.*(w0(0)-float(h(20)))
   h(22)=fix(dl)
   h(23)=1000.*(dl-float(h(22)))
;   h(100:159)=32b
   h(0)=8
   kdat,outfile,h,w0,f1,e1,i
   endfor
done:
return
end
