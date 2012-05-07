;**************************************************************************
pro make_hcpy,hcpy,dev,helpme=helpme,queue=queue,noprint=noprint, $
    encapsulate=encapsulate,show=show
;
if keyword_set(helpme) then begin
   print,' '
   print,'* MAKE_HCPY - runs LPLT'
   print,'*    calling sequence: MAKE_HCPY,file,dev'
   print,'*    FILE: name of output .PS file, default=IDL.PS'    
   print,'*    DEV: name of output device to be set, def from DECW$DISPLAY'
   print,'*'
   print,'*  KEYWORDS:'
   print,'*    NPORINT: if set, so not sent postscript file to printer'
   print,'*    QUEUE:   name of print queue, if not default'
   print,' '
   return
   endif
;
if n_params(0) lt 2 then begin
   case 1 of
      !version.os eq 'vms': begin
         if (getenv('DECW$DISPLAY') ne '') then dev='X' else dev='TEK'
         end
      !version.os eq 'win': dev='win'
      else: dev='X'
      endcase
   endif
;
if n_params(0) eq 0 then hcpy=1
;
if (!d.name eq 'X') or (!d.name eq 'win') and keyword_set(show) then wshow
if ifstring(hcpy) then lplt,dev,file=hcpy,queue=queue,noplot=noprint, $
     encapsulate=encapsulate $
     else lplt,dev,noplot=noprint,encapsulate=encapsulate 
return
end
