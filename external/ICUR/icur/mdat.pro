;************************************************************************
PRO MDAT,INNAME,OUTNAME,r1,r2,helpme=helpme,maxrec=maxrec,ETYPE=ETYPE, $
     single=single,wave=wave
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* MDAT - move data between ICUR data files'
   print,'*    calling sequence: MDAT,infile,outfile[,r1,r2]'
   print,'*       INFILE, OUTFILE: names of input and output files'
   print,'*       R1,R2: first and last records to copy.'
   print,'*              R1 defaults to 0'
   print,'*              If R1 is undefined, all records will be copied'
   print,'*              If R1 is defined and R2 is not passed, only record R1 is copied'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       MAXREC: search for maximum record length before copying'
   print,'*       ETYPE:  Set ETYPE when creating .ICD file'
   print,'*       Single:  force double precision values to FP'
   print,' '
   return
   endif
;
icurdata=getenv('icurdata')
if not ffile(inname+'.icd') then begin
   if not ffile(icurdata+inname+'.icd') then begin
      print,' File ',inname,' not found - returning.'
      return 
      endif else inname=icurdata+inname
   endif
case 1 of
   n_params(0) eq 2: begin
      r1=0 & r2=9999
      openr,lu,inname+'.icd',/get_lun
      p=assoc(lu,bytarr(512))
      rec0=p(0)
      recs=where(rec0(32:*) eq 1b,num)
      if num le 0 then begin
         print,inname,' is empty'
         close,lu
         free_lun,lu
         return
         endif
      r2=r2<max(recs)
      end
   n_params(0) eq 3: r2=r1
   else:
   endcase
if r1 lt 0 then r1=0
if r2 lt r1 then r2=r1
;
reclen=0
if keyword_set(maxrec) then begin
   for i=r1,r2 do begin
      gdat,inname,h,w,f,e,i
      if n_elements(h) lt 2 then goto,done1
      if h(7) lt 0 then h7=65535+h(7) else h7=h(7)
      reclen=h7>reclen
      endfor
   endif
done1:
;
if n_elements(wave) eq 1 then wave=0
for i=r1,r2 do begin
   GDAT,inname,H,W,F,E,i
   if n_elements(h) lt 2 then return      ;end of file
   if keyword_set(single) then f=float(f)
   if keyword_set(wave) then begin
      k=where((w ge wave(0)) and (w le wave(1)),nk)
      if nk gt 0 then begin
         w=w(k) & f=f(k) & e=e(k) & h(7)=nk
         endif else print,' No data in this wavelength range'
      endif
   KDAT,outname,H,W,F,E,-1,vlen=reclen,EPSTYPE=ETYPE
   endfor
RETURN
END
