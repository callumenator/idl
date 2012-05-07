;********************************************************************
pro icdfile,file,nr,etype,nl,stp=stp
if strlen(get_ext(file)) eq 0 then z=file+'.icd' else z=file
if not ffile(z) then begin
   print,' File ',z,' not found'
   return
   endif
openr,lu,z,/get_lun
p=assoc(lu,bytarr(512))
rec0=p(0)
close,lu & free_lun,lu
;
orig=rec0(0)
if keyword_set(sun) then orig=1b
;
; check origin and host machines
;
case 1 of
   (orig eq 0b) and (!version.arch eq 'mipsel'): machine=1     ;vms to DEC
   (orig eq 2b) and (!version.arch eq 'vax'): machine=2        ;DEC to vms
   (orig eq 0b) and (!version.arch eq 'sparc'): machine=3      ;vms to sun
   (orig eq 1b) and (!version.arch eq 'vax'): machine=4        ;sun to vms
   (orig eq 2b) and (!version.arch eq 'sparc'): machine=5      ;DEC to sparc
   (orig eq 1b) and (!version.arch eq 'mipsel'): machine=6     ;sun to DECs
   else: machine=0
   endcase
;
ilin=fix(rec0(3))          ;0 if stored as linear
nh=fix(rec0,8)             ;size of header record
nl=long(rec0,4)            ;size of header record
if machine gt 2 then begin                ;ne 0 then begin
   trans_bytes,nh,2,machine
   trans_bytes,nl,4,machine
   endif
;
nrec0=fix(rec0(10))        ;number of initial records
etype=fix(rec0(15))        ;epsilon vector code
k=where(rec0(32:*) gt 0b)   ;bytes 0:rec0off-1 reserved
nr=max(k)
if keyword_set(stp) then stop,'ICDFILE>>>'
return
end
