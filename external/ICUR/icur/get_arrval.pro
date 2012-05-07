;*****************************************************************************
function get_arrval,arr
if n_elements(arr) eq 0 then begin
   print,' '
   print,'* function GET_ARRVAL'
   print,'*   get values of discretely-valued array'
   print,'*   calling sequence: LEVELS=GET_ARRVAL,ARRAY'
   print,'*      ARRAY:  input array'
   print,'*      LEVELS: output vector containing levels in ARRAY'
   print,' '
   return,-1
   endif
if n_elements(arr) eq 1 then begin
   cc=[arr,arr]
   endif else cc=arr
cmax=max(cc)              ;maximum value
ca=min(cc)
kc=where(cc eq ca) & cc(kc)=cmax
ca=[ca,ca] & ca=ca(0)
if ca eq cmax then return,ca      ;unilevel
while min(cc) lt cmax do begin
   ca=[ca,min(cc)]
   kc=where(cc eq min(cc)) & cc(kc)=cmax
   endwhile
ca=[ca,cmax]
return,ca
end
