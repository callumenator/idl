;*****************************************************************************
pro pghead,h,out,file=file,npause=npause,stp=stp
ihlp=0
if n_params() eq 0 then ihlp=1
if n_params() ge 1 then begin
   s=size(h)
   sz=s(1+s(0))
   if (sz ne 1) and (sz ne 7) then ihlp=1    ;not a byte or string
   if s(1+s(0)) eq 1 then begin
      if s(0) ne 1 then ihlp=1
      if s(1) lt 79 then ihlp=1
      endif
   endif
if ihlp eq 1 then begin
   print,' '
   print,'* PGHEAD - page through FITS header'
   print,'*    calling sequence: PGHEAD,h,out'
   print,'*       h  : header vector (byte array)'
   print,'*       out: optional output string header array'
   print,' '
if keyword_set(stp) then stop,'PGHEAD>>>' 
   return
   endif
;
if not keyword_set(npause) then npause=0 else npause=1
j=0
zz=' '
case sz of
  1: begin
      out=' '
      nlines=n_elements(h)/80
      for i=0,nlines-1 do begin
         head=string(h(i*80:i*80+79))
         if strlen(strtrim(head,2)) ne 0 then begin
            j=j+1
            print,head
            out=[out,head]
            if npause eq 0 then if j mod 23 eq 0 then begin
               read,'      RETURN to continue',zz
               zb=(byte(zz))(0)
               if (zb ge 65) and (zb le 122) then return
               endif
            endif
         endfor
      end
else: begin           ;string
   nlines=s(s(0)) 
   out=h
      for i=0,nlines-1 do begin
         j=j+1
         print,h(i)
         if npause eq 0 then if j mod 23 eq 0 then begin
            read,'      RETURN to continue',zz
            zb=(byte(zz))(0)
            if (zb ge 65) and (zb le 122) then return
            endif
         endfor
      end
   endcase
;
if keyword_set(file) then begin
   z='fits.hhh'
   openw,lu,z,/get_lun
   for i=0,n_elements(out)-1 do printf,lu,out(i)
   close,lu
   free_lun,lu
   print,' Header file is ',z
   endif
;
if keyword_set(stp) then stop,'PGHEAD>>>' 
return
end
