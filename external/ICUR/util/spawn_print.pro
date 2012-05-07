;******************************************************************************
pro spawn_print,file,delete=delete,queue=queue,form=form,stp=stp
if n_params(0) eq 0 then begin
   print,' '
   print,'* SPAWN_PRINT - sends file to printer'
   print,'*   calling sequence: SPAWN_PRINT,file'
   print,'*      FILE: name of file to be printed'
   print,'*   KEYWORDS:'
   print,'*      DELETE: set to delete file after printing'
   print,'*      FORM: set /FORM VMS option'
   print,'*      QUEUE: use to specify queue if not default'
   print,' '
   return
   endif
;
if keyword_set(delete) then zd=1 else zd=0      ;delete specified
if not keyword_set(queue) then iq=0 else iq=1   ;queue specified
;
case 1 of
   strupcase(!version.os) eq 'VMS': begin
      defqueue='mylp'
      if zd eq 1 then zd='/delete' else zd=''
      if iq eq 1 then zq='/queue='+queue else zq='/queue='+defqueue
      if keyword_set(form) then frm='/form='+form else frm=''
      z='print'+zd+zq+frm+' '+file
      end
   else: begin
      defqueue='hpk'
      if zd eq 1 then zd=' -r' else zd=''
      if iq eq 1 then zq=' -P'+queue else zq=' -P'+defqueue 
      z='lpr'+zd+zq+' '+file
      end
   endcase
spawn,z
;if !version.os_family eq 'unix' then spawn,/noshell,z else spawn,z
if keyword_set(stp) then stop,'SPAWN_PRINT>>>'
return
end
