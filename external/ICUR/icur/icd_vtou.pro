;******************************************************************************
pro icd_vtou,file,helpme=helpme,debug=debug,stp=stp
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ICD_VtoU  -  strip excess bytes from .ICD files FTP''d from VMS systems'
   print,'*    calling sequence: ICD_VtoU,file'
   print,'*'
   print,'*    Output file is renamed to file_r.icd'
   print,' '
   return
   endif
;
if keyword_set(debug) then stp=1
if strupcase(get_ext(file)) eq '.ICD' then begin
   k=strpos(strupcase(file),'.ICD')
   f=strmid(file,0,k) 
   endif else f=file
;
openr,lu,f+'.icd',/get_lun
fst=fstat(lu)
fsize=fst.size
rl=fst.rec_len
if keyword_set(debug) then help,/st,fst
;
p=assoc(lu,bytarr(512))
rec0=p(0)
;
nrec0=fix(rec0(10))        ;number of initial records
nr=fix(rec0(2))            ;records used
;
nrs=fix(total(rec0(32:511)))
nrt=fix(nrec0+nr*nrs)           ;total records in use
rem=fsize-nrt*512L
if keyword_set(debug) then print,'nrt=',nrt,' REM =',rem
print,nrt,' Records to translate.'
case 1 of
   rem eq 0: begin
      print,' ICD_VtoU: No excess bytes. Nothing will be translated'
      return
      end
   rem ne nrt : begin
      print,' ICD_VtoU Error: '
      print,' Inconsistent record numbers: REM=',rem,' NRT=',nrt
      print,' Did you use binary mode in FTP?'
      print,' ICD_VtoU will now execute a return'
      if keyword_set(stp) then stop,'ICD_VtoU>>>'
      return
      end
   else: begin
      openw,lu2,f+'_r.icd',512,/get_lun
      p2=assoc(lu2,bytarr(512))
      z0=p(0)
      p2(0)=z0
      j=1
      z=[1b,1b]            ;padding
      for i=1,nrt-1 do begin
         bbyte=(i-1) mod 513           ;index of bad byte
         z0=p(i)
         case 1 of 
            bbyte eq 0: z0=z0(1:*)
            bbyte eq 511: z0=z0(0:510)
            bbyte eq 512: z0=z0(0:511)
            else: z0=[z0(0:bbyte-1),z0(bbyte+1:*)]
            endcase
         z=[z,z0]
         nz=n_elements(z)-2
         if nz ge 512 then begin
            p2(j)=z(2:513)
            j=j+1
            if nz eq 512 then z=[1b,1b] else z=[1b,1b,z(514:*)]
            endif
         endfor
      z=z(2:*)   ;
      nz=n_elements(z)
      nr=nz/512 & if (nz mod 512) ne 0 then nr=nr+1       ;records to go
if keyword_set(debug) then print,'nz,nr',nz,nr
      while nr gt 0 do begin
         if nr gt 1 then begin
            p2(j)=z(0:511)
            z=z(512:*)
            endif else begin
            fill=bytarr(512)
            fill(0)=z
            p2(j)=fill
            endelse
         nr=nr-1
         j=j+1
         endwhile            
   case 1 of
      j eq rem:
      j eq rem-1: p2(j+1)=bytarr(512)
      else: begin
         print,' WARNING: in ICD_VtoU: j=',j,'  rem=',rem
         if keyword_set(debug) then stop,'ICD_VtoU>>>'
         end
      endcase
if keyword_set(debug) then print,'j',j
;
      print,' translated file is ',f+'_r.icd'
      end
   endcase
;
if keyword_set(stp) then begin
   print,'ICD_VtoU>>>  Warning: files are still open on lu,lu2'
   stop,'ICD_VtoU>>>'
   endif
close,lu & free_lun,lu
close,lu2 & free_lun,lu2
return
end
