;***********************************************************
pro lplt,dev,nodelete=nodelete,file=file,queue=queue,noplot=noplot, $
    out=out, helpme=helpme,encapsulate=encapsulate,stp=stp
defdev='X'
if !version.os eq 'vms' then defqueue='MYLP' else defqueue='hpk'
if n_params(0) eq 0 then dev=defdev                 ;default screen
if n_elements(dev) eq 0 then dev=defdev                 ;default screen
if (strtrim(dev,2) eq '-1') or (strtrim(dev,2) eq '0') then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* LPLT - send plot to hard copy device'
   print,'*    calling sequence: LPLT,dev'
   print,'*       dev: plot device, default=',defdev
   print,'*    KEYWORDS:'
   print,'*       NODELETE: if not set, plot file is deleted after plotting'
   print,'*       NOPLOT: if set, plot will not be printed'
   print,'*       FILE: file will be renamed to this, if set.'
   print,'*       QUEUE: name of plot queue, default=',defqueue
   print,' '
   return
   endif
if n_params(0) eq 0 then dev=defdev                 ;default screen
if not ifstring(dev) then dev=defdev              ;dev must be a string
irename=0
if (n_elements(out) ne 0) and (n_elements(file) eq 0) then file=out
if not keyword_set(nodelete) then nodelete=0        ;default deletes file
if n_elements(file) ne 0 then begin                     ;rename and save file
   if ifstring(file) eq 1 then begin
      irename=1 & nodelete=1                        ;do not delete
      endif
   endif
;if nodelete eq 0 then zd='/delete/noconfirm' else zd=''
if nodelete eq 0 then zd=1 else zd=0
if not keyword_set(queue) then queue=defqueue       ;default plot queue
case 1 of
    !d.name eq 'PS': begin                          ;postscript file
      device,/close_file,scale_factor=1.
      if keyword_set(encapsulate) then ext='.eps' else ext='.ps'
      if irename eq 1 then begin                    ;rename and save file
         if !version.os eq 'vms' then begin
            if get_ext(file) eq '' then file=file+ext  ;needs extension
            endif else begin
            if (get_ext(file) ne 'ps') or (get_ext(file) ne 'eps') then file=file+ext  ;needs extension
            endelse
         if !version.os eq 'vms' then spawn,' rename idl.ps '+file $
            else spawn,'mv idl.ps '+file
         endif else file='idl'+ext                   ;default file name
      if not keyword_set(noplot) then spawn_print,file,delete=zd,queue=queue, $
         stp=stp
;      spawn,'print'+zd+'/QUEUE='+queue+' '+file
      print,string(7b)                              ;bell
;      !p.color=255                                  ;reset color
      end
   else: 
   endcase
sp,dev                                              ;initialize device
if keyword_set(stp) then stop,'LPLT>>>'
return
end
