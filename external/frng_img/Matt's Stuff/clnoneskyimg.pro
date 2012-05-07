;   this program is to read and display raw image files
;   taken from the trailer FPI located in Inuvik, and clean
;   the images up.  this should become the final working version
;   of this program.
;   Matt Krynicki, 09-02-99.

pro docleansky, isig, isignew

for i=0,255 do begin
 for j=0,254 do begin
  if (i eq 0) then begin
   call_procedure,'doskyizero',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 0) then goto, nexti
  if (i eq 1) then begin
   call_procedure,'doskyione',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 1) then goto, nexti
  if (i eq 2) then begin
   call_procedure,'doskyitwo',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 2) then goto, nexti
  if (i eq 253) then begin
   call_procedure,'doskyithree',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 253) then goto, nexti
  if (i eq 254) then begin
   call_procedure,'doskyifour',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 254) then goto, nexti
  if (i eq 255) then begin
   call_procedure,'doskyifive',i,j,isig,isignew
   if (j ne 254) then goto, nextj
  endif
  if (i eq 255) then goto, nexti

   if (j eq 0) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i,j+6)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j+6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 0) then goto, nextj
   if (j eq 1) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j-1)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 1) then goto, nextj
   if (j eq 2) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j-1),isig(i,j-2)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 2) then goto, nextj
   if (j eq 252) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
       isig(i,j-3),isig(i,j-4)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 252) then goto, nextj
   if (j eq 253) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
       isig(i,j-5),isig(i,j+1)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 253) then goto, nextj
   if (j eq 254) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i,j-6)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
       isig(i,j-5),isig(i,j-6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 254) then goto, nextj
    
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i+2,j)+50)) or $
     (isig(i,j) gt (isig(i+3,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i+1,j),$
       isig(i+2,j),isig(i+3,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
       isig(i,j-2),isig(i,j-3)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse

nextj:
 endfor
nexti:
endfor

return

end

;  this sub takes care of i=0 for sky images

pro doskyizero,i,j,isig,isignew

if (j eq 0) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i,j+6)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j+6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 0) then goto, thenextj
if (j eq 1) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j-1),isig(i,j+1),isig(i,j+2),isig(i,j+3),$
    isig(i,j+4),isig(i,j+5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 1) then goto, thenextj
if (j eq 2) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j-1),isig(i,j-2),isig(i,j+1),isig(i,j+2),$
    isig(i,j+3),isig(i,j+4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 2) then goto, thenextj
if (j eq 252) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
    isig(i,j-3),isig(i,j-4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 252) then goto, thenextj
if (j eq 253) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j+1),isig(i,j-1),isig(i,j-2),isig(i,j-3),$
    isig(i,j-4),isig(i,j-5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 253) then goto, thenextj
if (j eq 254) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i,j-6)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
    isig(i,j-5),isig(i,j-6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 254) then goto, thenextj
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) or $
  (isig(i,j) gt (isig(i+6,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),isig(i+4,j),$
    isig(i+5,j),isig(i+6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
    isig(i,j-2),isig(i,j-3)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse

thenextj:

return

end

;  this sub takes care of i=1 for sky images

pro doskyione,i,j,isig,isignew

if (j eq 0) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i,j+6)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j+6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 0) then goto, thenextj1
if (j eq 1) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j-1),isig(i,j+1),isig(i,j+2),isig(i,j+3),$
    isig(i,j+4),isig(i,j+5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 1) then goto, thenextj1
if (j eq 2) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j-1),isig(i,j-2),isig(i,j+1),isig(i,j+2),$
    isig(i,j+3),isig(i,j+4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 2) then goto, thenextj1
if (j eq 252) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
    isig(i,j-3),isig(i,j-4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 252) then goto, thenextj1
if (j eq 253) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j+1),isig(i,j-1),isig(i,j-2),isig(i,j-3),$
    isig(i,j-4),isig(i,j-5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 253) then goto, thenextj1
if (j eq 254) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i,j-6)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
    isig(i,j-5),isig(i,j-6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 254) then goto, thenextj1
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) or $
  (isig(i,j) gt (isig(i+5,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i+1,j),isig(i+2,j),isig(i+3,j),$
    isig(i+4,j),isig(i+5,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j+1),$
    isig(i,j+2),isig(i,j+3)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse

thenextj1:

return

end

;  this sub takes care of i=2 for sky images

pro doskyitwo,i,j,isig,isignew

if (j eq 0) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i,j+6)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j+6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 0) then goto, thenextj2
if (j eq 1) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j-1)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 1) then goto, thenextj2
if (j eq 2) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j-1),isig(i,j-2)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 2) then goto, thenextj2
if (j eq 252) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
    isig(i,j-3),isig(i,j-4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 252) then goto, thenextj2
if (j eq 253) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j-1),isig(i,j-2),isig(i,j-3),$
    isig(i,j-4),isig(i,j-5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 253) then goto, thenextj2
if (j eq 254) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i,j-6)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
    isig(i,j-5),isig(i,j-6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 254) then goto, thenextj2
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i+3,j)+50)) or $
  (isig(i,j) gt (isig(i+4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i+1,j),isig(i+2,j),$
    isig(i+3,j),isig(i+4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
    isig(i,j-2),isig(i,j-3)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse

thenextj2:

return

end

;  this sub takes care of i=253 for sky images

pro doskyithree,i,j,isig,isignew

if (j eq 0) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i,j+6)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j+6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 0) then goto, thenextj3
if (j eq 1) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i,j+5)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j+5),isig(i,j-1)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 1) then goto, thenextj3
if (j eq 2) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i,j+4)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
    isig(i,j-1),isig(i,j-2)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 2) then goto, thenextj3
if (j eq 252) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
    isig(i,j-3),isig(i,j-4)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 252) then goto, thenextj3
if (j eq 253) then begin
 if (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j-1),isig(i,j-2),isig(i,j-3),$
    isig(i,j-4),isig(i,j-5)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 253) then goto, thenextj3
if (j eq 254) then begin
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j-4)+50)) or $
  (isig(i,j) gt (isig(i,j-5)+50)) or $
  (isig(i,j) gt (isig(i,j-6)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
    isig(i,j-5),isig(i,j-6)]
   isignew(i,j)=median(isiginbt)
 endif else begin
   isignew(i,j)=isig(i,j)
 endelse
endif
if (j eq 254) then goto, thenextj3
 if (isig(i,j) gt (isig(i,j-1)+50)) or $
  (isig(i,j) gt (isig(i,j-2)+50)) or $
  (isig(i,j) gt (isig(i,j-3)+50)) or $
  (isig(i,j) gt (isig(i,j+1)+50)) or $
  (isig(i,j) gt (isig(i,j+2)+50)) or $
  (isig(i,j) gt (isig(i,j+3)+50)) or $
  (isig(i,j) gt (isig(i+1,j)+50)) or $
  (isig(i,j) gt (isig(i+2,j)+50)) or $
  (isig(i,j) gt (isig(i-1,j)+50)) or $
  (isig(i,j) gt (isig(i-2,j)+50)) or $
  (isig(i,j) gt (isig(i-3,j)+50)) or $
  (isig(i,j) gt (isig(i-4,j)+50)) then begin
   isiginbt=[isig(i,j),isig(i+1,j),isig(i+2,j),isig(i-1,j),isig(i-2,j),$
    isig(i-3,j),isig(i-4,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
    isig(i,j-2),isig(i,j-3)]
   isignew(i,j)=median(isiginbt)
 endif else begin
  isignew(i,j)=isig(i,j)
 endelse

thenextj3:

return

end

;  this sub takes care of i=254 for sky images

pro doskyifour,i,j,isig,isignew

   if (j eq 0) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i,j+6)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j+6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 0) then goto, thenextj4
   if (j eq 1) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j-1)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 1) then goto, thenextj4
   if (j eq 2) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j-1),isig(i,j-2)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 2) then goto, thenextj4
   if (j eq 252) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
       isig(i,j-3),isig(i,j-4)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 252) then goto, thenextj4
   if (j eq 253) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j-1),isig(i,j-2),isig(i,j-3),$
       isig(i,j-4),isig(i,j-5)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 253) then goto, thenextj4
   if (j eq 254) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i,j-6)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
       isig(i,j-5),isig(i,j-6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 254) then goto, thenextj4
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i+1,j)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i+1,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),$
       isig(i-4,j),isig(i-5,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
       isig(i,j-2),isig(i,j-3)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse

thenextj4:

return

end

;  this sub takes care of i=255 for sky images

pro doskyifive,i,j,isig,isignew

   if (j eq 0) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i,j+6)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j+6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 0) then goto, thenextj5
   if (j eq 1) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i,j+5)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j+5),isig(i,j-1)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 1) then goto, thenextj5
   if (j eq 2) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i,j+4)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j+4),$
       isig(i,j-1),isig(i,j-2)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 2) then goto, thenextj5
   if (j eq 252) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j+1),isig(i,j+2),isig(i,j-1),isig(i,j-2),$
       isig(i,j-3),isig(i,j-4)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 252) then goto, thenextj5
   if (j eq 253) then begin
    if (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
       isig(i,j-5),isig(i,j+1)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 253) then goto, thenextj5
   if (j eq 254) then begin
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j-4)+50)) or $
     (isig(i,j) gt (isig(i,j-5)+50)) or $
     (isig(i,j) gt (isig(i,j-6)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j-1),isig(i,j-2),isig(i,j-3),isig(i,j-4),$
       isig(i,j-5),isig(i,j-6)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse
   endif
   if (j eq 254) then goto, thenextj5
    if (isig(i,j) gt (isig(i,j-1)+50)) or $
     (isig(i,j) gt (isig(i,j-2)+50)) or $
     (isig(i,j) gt (isig(i,j-3)+50)) or $
     (isig(i,j) gt (isig(i,j+1)+50)) or $
     (isig(i,j) gt (isig(i,j+2)+50)) or $
     (isig(i,j) gt (isig(i,j+3)+50)) or $
     (isig(i,j) gt (isig(i-1,j)+50)) or $
     (isig(i,j) gt (isig(i-2,j)+50)) or $
     (isig(i,j) gt (isig(i-3,j)+50)) or $
     (isig(i,j) gt (isig(i-4,j)+50)) or $
     (isig(i,j) gt (isig(i-5,j)+50)) or $
     (isig(i,j) gt (isig(i-6,j)+50)) then begin
      isiginbt=[isig(i,j),isig(i-1,j),isig(i-2,j),isig(i-3,j),isig(i-4,j),$
       isig(i-5,j),isig(i-6,j),isig(i,j+1),isig(i,j+2),isig(i,j+3),isig(i,j-1),$
       isig(i,j-2),isig(i,j-3)]
      isignew(i,j)=median(isiginbt)
    endif else begin
      isignew(i,j)=isig(i,j)
    endelse

thenextj5:

return

end

;   Program Cleanimage

start:

file=''
imagefile=''
cleanfile=''
date=''
piece=''
othpiece=''
thtime=''
type=''
znth=''
azmth=''
dumbo=''
head=bytarr(161)
isig=bytarr(256,255)
isignew=bytarr(256,255)

print,''
print, "enter the date of the image data file"
print, "in format YYMMDD.  this should also be"
print, "the directory that the files are located in"
print,''
read, date
print,''

piece=strmid(date,1,5)
othpiece=strmid(date,3,3)

print,''
print, "enter the last three characters (numbers) of the"
print, "first image data file to begin with.  this should"
print, "be the first dark count image of the night.  e.g. 014"
print,''
read,file

print,''
print, "enter the time, in UT, of the first dark count profile,"
print, "using HR:MIN:SEC format.  e.g.  00:26:44 for 26 minutes"
print, "and 44 seconds past midnight, 13:07:09 for 7 minutes and"
print, "9 seconds past the 13th hour."
print,''
read,thtime
print,''
filenum=fix(file)

if filenum lt 10 then strfile='00'+strcompress(filenum,/remove_all)
if filenum lt 100 then strfile='0'+strcompress(filenum,/remove_all)
if filenum ge 100 then strfile=strcompress(filenum,/remove_all)

imagefile='/home/mpkryn/ivkimgarc/'+date+'/'+piece+strfile+'.RAW'
cleanfile='/home/mpkryn/ivkimgarc/'+date+'/'+piece+strfile+'.cln'

openr,unit,imagefile,/get_lun,error=bad

hrs=strmid(thtime,0,2)
min=float(strmid(thtime,3,2))
sec=float(strmid(thtime,6,2))
totalsec=(min*60.)+sec
dec=strmid(strcompress(totalsec/3600.,/remove_all),2,2)
print,''
thtime=hrs+'.'+dec
print,'the time in decimal format is '+thtime
print,''

print, "enter the type of the image"
print, " 001 for a sky image and 002 for a dark count image"
print,''
read, type
if type eq '002' then begin
 azmth='***'
 znth='**'
endif
if type eq '001' then begin
 print, "enter the azimuth angle, 000 for north, 270 for west,"
 print, '180 for south, 090 for east, and 000 for zenith'
 print,''
 read, azmth
 print,''
 print, "enter the zenith angle, 30 for offzenith measurements,"
 print, "90 for zenith measurements"
 print,''
 read, znth
endif 

print,''
print,date,thtime,type,azmth,znth
print,''

openw,unit3,cleanfile,/get_lun
readu,unit,head
readu,unit,isig
close,unit
free_lun,unit

;window,3,xsize=256,ysize=255,retain=2
;loadct,41
;tv,isig

if type eq '002' then isignew=isig
if type eq '002' then goto, dontdo

call_procedure,'docleansky',isig,isignew

dontdo:

isignew(0,*)=isignew(1,*)
head(0:5)=byte(date)
head(6:10)=byte(thtime)
head(11:13)=byte(type)
head(14:16)=byte(azmth)
head(17:18)=byte(znth)
writeu,unit3,head,isignew

close,unit3
free_lun,unit3

;window,1,xsize=256,ysize=255,retain=2
;tv,isignew

decision=''
print, "another image?  y/n"
print,''
read,decision
if decision eq 'y' then goto, start 

end


