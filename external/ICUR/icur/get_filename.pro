;*************************************************************************
function get_filename,input,default=default,ext=ext
if n_elements(default) eq 0 then default=''
if n_elements(ext) eq 0 then ext='' else begin
   k=strpos(ext,'.',0)
   if k eq -1 then ext='.'+ext
   endelse
case 1 of
   n_elements(input) eq 0: z=default+ext
   ifstring(input) ne 1: z=default+ext
   noext(input): z=input+ext
   else: z=input
   endcase
return,z
end
