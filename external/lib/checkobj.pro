;====================================================================================
;  This function reads the first few lines of a file to decide if it looks like
;  a valid McObject.  If not, it returns a status of 1. If it looks valid,
;  a status of 0 is returned.
function checkobj, objfile
   status = 1
   if not(fexist(objfile)) then return, status
   on_ioerror, OBJFAIL
   openr, objun, objfile, /get_lun
   xx = 0b
   attempts = 0
   while  string(xx) ne '>' and not(eof(objun)) and attempts lt 20 do begin
          xx = 0b
          readu, objun, xx
          attempts = attempts + 1
   endwhile
   htest = string(xx)
   for j = 0,30 do begin
       xx = 0b
       readu, objun, xx
       htest = htest + string(xx)
   endfor
   close, objun
   free_lun, objun
   if strpos(strupcase(htest), strupcase('>> begin comments')) ge 0 then status = 0
OBJFAIL: close, objun
   free_lun, objun
   return, status
   end

