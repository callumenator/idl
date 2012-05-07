;****************************************************************************
pro rd_2masstbl,file0,ra,dec,mag,dmag,name=name,prt=prt, $
    col23=col23,stp=stp,helpme=helpme
;
if n_elements(file0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* RD_2MASSTBL - read 14 or 23 column 2MASS table'
   print,'* calling sequence: RD_2MASSTBL,FILE,RA,DEC,MAG,DMAG'
   print,'*    FILE: name of table, extension =2MASS'
   print,'*    RA,DEC:   output coordinates'
   print,'*    MAG,DMAG: output KHJ magnitudes and errors, format 3xN'
   print,'* '
   print,'* KEYWORDS'
;   print,'*    COL23: set for long (23 column) file'
   print,'*    NAME: if named, returns source names'
   print,' '
   return
   endif
;
;if not keyword_set(col23) then short=1
file=file0
if noext(file) then file=file+'.2mass'
openr,lu,file,/get_lun
zz=''
genrd,lu,zz
free_lun,lu
z0=zz
;
nl=n_elements(zz)          ;number of lines
zz=strtrim(zz,2)
zz=strcompress(zz)
k=where(strmid(zz,0,1) ne '\',nk)
if nk eq 0 then begin
   print,' something wrong here: all lines start with \'
   if keyword_set(stp) then stop,'RD_2MASSTBL>>>'
   return
   endif
z=zz(k)
khead=where(strmid(z,0,1) eq '|',nh)
if nh gt 0 then zhead=z(khead)
kdata=where(strmid(z,0,1) ne '|',nl)
z=z(kdata)
s=str_sep(z(0),' ')
np=n_elements(s)
for i=1,nl-1 do s=[[s],[str_sep(z(i),' ')]]
;
zhead=strmid(zhead,1,512)
zhead=strtrim(zhead,2)
hdr=str_sep(zhead(0),'|')
hdr=strtrim(hdr(0:np-1),2)
ira=(where(hdr eq 'ra'))(0)
idec=(where(hdr eq 'dec'))(0)
ra=transpose(double(s(ira,*)))
dec=transpose(double(s(idec,*)))
i=(where(hdr eq 'k_m'))(0) & kmag=float(s(i,*))
i=(where(hdr eq 'h_m'))(0) & hmag=float(s(i,*))
i=(where(hdr eq 'j_m'))(0) & jmag=float(s(i,*))
mag=[kmag,hmag,jmag]
i=(where(hdr eq 'k_msig'))(0) & kmag=s(i,*)
   k=where(strtrim(kmag,2) eq 'null',nk) & if nk gt 0 then kmag(k)='9.999'
   kmag=float(kmag)
i=(where(hdr eq 'h_msig'))(0) & hmag=s(i,*)
   k=where(strtrim(hmag,2) eq 'null',nk) & if nk gt 0 then hmag(k)='9.999'
   hmag=float(hmag)
i=(where(hdr eq 'j_msig'))(0) & jmag=s(i,*)
   k=where(strtrim(jmag,2) eq 'null',nk) & if nk gt 0 then jmag(k)='9.999'
   jmag=float(jmag)
dmag=[kmag,hmag,jmag]
i=(where(hdr eq 'designation'))(0) & if i ne -1 then name=transpose(s(i,*))
;
if keyword_set(stp) then stop,'RD_2MASSTBL>>>'
return
end
