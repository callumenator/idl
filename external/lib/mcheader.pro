;==========================================================================================
; Read the header fields from a McObject, returning a (2, n) string array. The first 
; column is the header keywords, the second is the header settings.
pro mcheader, objfile, header, status=sts
    sts = 1
    if checkobj(objfile) then return
    if fexist(objfile) then begin
       openr, objun, objfile, /get_lun, /xdr
       oneline = 'Empty'
       attempts = 0
       while strpos(oneline, '>>>> begin declarations') lt 0 and $
             not(eof(objun)) and $
             attempts lt 15 do begin
             readu, objun, oneline
             attempts = attempts + 1
        endwhile
       
       if not(eof(objun)) and attempts lt 15 then begin
          readu, objun, oneline
          while strpos(oneline, '>>>> end declarations') lt 0 do begin
                parts    = str_sep(oneline, '=')
                parts    = strtrim(parts, 2)
                if (n_elements(header)) lt 1 then header = parts else header = [[header], [parts]]
                readu, objun, oneline
          endwhile
          sts = 0
       endif else begin
          sts = 1
       endelse
       close, objun
       free_lun, objun
    endif
end
