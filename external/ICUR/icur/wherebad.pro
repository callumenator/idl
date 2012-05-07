;*********************************************************
function wherebad,e,ibad               ;compute locations of good or bad points
if n_params(0) eq 0 then return,-1
if n_params(0) lt 2 then ibad=0
;
;ibad=0 to return good points, 1 to return bad points
;
if ibad eq 0 then begin       ;get good points
   case 1 of
      (min(e) eq 0) and (max(e) lt 10): k=where(e lt 2)
      min(e) lt 0                     : k=where(e ge -200)
      else                            : k=where(e gt 0)
      endcase
   endif else begin        ;get bad points
   case 1 of
      (min(e) eq 0) and (max(e) lt 10): k=where(e ge 2)
      min(e) lt 0                     : k=where(e lt -200)
      else                            : k=where(e le 0)
      endcase
   endelse
return,k
end

