;*********************************************************************
pro icsave,id,file                ;save/restore fit parameters
COMMON COM1,H
COMMON COM2,A,B,FH,FIXT,ISHAPE
if n_params(0) eq 0 then return   ;no input
if n_params(0) ge 2 then nfile=1 else nfile=0  ; 1 if file supplied
if nfile eq 0 then file=''
if !version.os eq 'vms' then unf='/unf' else unf=''
nh=n_elements(h)
;
if id eq -1 then begin                   ;read from file
   if nfile eq 0 then READ,' Enter file name (no extension): ',FILE
   if not ffile(file+'.icf') then begin
      print,' File ',file+'.icf was not found. Try again.'
      return
      endif
   ISHAPE=0
   H0=H
   PRINT,' '
   openr,lu,file+'.icf'+unf,/get_lun
   readu,lu,a,b,fh,fixt,ishape,h0
;  TEST HEADERS
   bell=string(byte(7))+' ICSAVE: WARNING - '
   for i=0,1 do print,' '
   if h0(3) ne h(3) then print,bell,'CAMERAS DO NOT MATCH ' else begin
      if h(3) le 4 then begin   ;IUE DATA
         if h0(4) ne h(4) then print,bell,'IMAGE NUMBERS DO NOT AGREE '
         endif else begin   ;optical data
         l0=strtrim(string(byte(h0(100:140))>32b),2)
         l=strtrim(string(byte(h(100:140))>32b),2)
         if (l ne l0) or strpos(l,l0) eq -1 then print,bell,' labels Differ '
        endelse
      endelse
   endif
;
if id eq 1 then begin                   ;write file
   print,' '
   if nfile eq 0 then read,' Enter file name (no extension): ',file
   file=file+'.icf'+unf
   openw,lu,file,/get_lun
   writeu,lu,a,b,fh,fixt,ishape,h
   print,' '
   print,' Fit parameters saved to file ',file
   endif
close,lu
free_lun,lu
return
end
