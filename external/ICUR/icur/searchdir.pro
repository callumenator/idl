;*****************************************************************************
pro searchdir,inp,ext,stp=stp             ;search directories for file INP
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata
; searches working directory, USERDATA, ICURDATA
if n_params(0) eq 0 then return
if n_params(0) lt 2 then ext='.icd'         ;default extension
inp=strtrim(inp,2)
t=inp
if strlen(get_ext(t)) eq 0 then t=t+ext  ;add extension if none passed
;print,t
if n_elements(userdata) eq 0 then userdata=''
if n_elements(icurdata) eq 0 then icurdata=''
case 1 of
   ffile(t) eq 1:
   ffile(userdata+t) eq 1: inp=userdata+inp
   ffile(icurdata+t) eq 1: inp=icurdata+inp
   else: begin
      bell,3
      print,' File ',inp,' not found in user directory, USERDATA, or ICURDATA'
;stp=1
      if keyword_set(stp) then stop,'SEARCHDIR>>>>'
      inp='nofile'
      endelse
   endcase
return
end

