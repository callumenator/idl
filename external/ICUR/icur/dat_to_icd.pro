;******************************************************************************
pro dat_to_icd,in,recs,out=out,maxrec=maxrec,helpme=helpme,notitle=notitle
if n_params(0) le 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* DAT_TO_ICD'
   print,'* convert old format ICUR data files to new format files'
   print,'* '
   print,'* calling sequence:
   print,'*    DAT_TO_ICD,infile,rec1,rec2'
   print,'*       INFILE: name of input .DAT data file'
   print,'*       RECS: optional list of records to be copied, default=all'
   print,'*'
   print,'* KEYWORDS:'
   print,'*       OUT: name of output file, default=INFILE.ICD'
   print,'*    MAXREC: set to force vector length to max in input file'
   print,'*   NOTITLE: set to override query for title'
   print,' '
   return
   endif
;
infile=in
outfile=in
if get_ext(in) eq '' then infile=infile+'.dat' else begin
   k=strpos(in,'.')
   outfile=strmid(in,0,k)
   endelse
if not ffile(infile) then begin
   bell,3
   print,' file ', infile,' not found'
   return
   endif
;
if keyword_set(out) then outfile=out
if keyword_set(notitle) then qt=1 else qt=0
;
if n_params(0) lt 2 then recs=indgen(999)
nr=n_elements(recs)
if keyword_set(maxrec) then begin
   reclen=0
   for i=0,nr-1 do begin
      getdat,in,h,w,f,e,recs(i)
      if n_elements(h) lt 2 then goto,done1
      reclen=h(7)>reclen
      endfor
done1:
   print,'reclen=',reclen
   endif
;
for i=0,nr-1 do begin
   getdat,in,h,w,f,e,recs(i)
   if n_elements(h) lt 2 then goto,done
   if keyword_set(maxrec) then kdat,outfile,h,w,f,e,vlen=reclen,notitle=qt $
      else kdat,outfile,h,w,f,e,notitle=qt
   endfor
done:
ldat,outfile
print,' New format data file is ',outfile
return
end
