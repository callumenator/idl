;**************************************************************************
pro addheliocor,datfile,obsl
if n_params(0) lt 1 then begin
   print,' '
   print,'* ADDHELIOCOR - place heliocentric velocity corrections in ICUR headers'
   print,'*    calling sequence: ADDHELIOCOR,datafile,obslat'
   print,'*       DATAFILE: name of ICUR format data file'
   print,'*       OBSLAT:   observatory latitude, def=32.'
   print,' '
   return
   endif
;
if n_params(0) lt 2 then obsl=32.
for record=0,9999 do begin
   gdat,datfile,h1,w1,f1,e1,record
   if n_elements(h1) lt 2 then goto,done
   heliocor,2,h1,vhel1,obslat=obsl
   kdat,datfile,h1,w1,f1,e1,record
   endfor
done:
return
end
