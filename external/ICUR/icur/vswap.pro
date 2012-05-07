;****************************************************************************
pro vswap,x,helpme=helpme,quiet=quiet
if n_elements(x) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,''
   print,'* VSWAP - convert VAX format numbers into IEEE format'
   print,'* calling sequence: VSWAP,var'
   print,'*    VAR: input and output floating point or double precision variable'
   print,''
   return
   end
if !version.arch ne 'alpha' then return
s=size(x)
s=s(s(0)+1)
case s of
   4: byteorder,x,/vaxtof
   5: byteorder,x,/vaxtod
   else: if not keyword_set(quiet) then $
      print,' No conversion - not a FP or DP number'
   endcase
return
end
