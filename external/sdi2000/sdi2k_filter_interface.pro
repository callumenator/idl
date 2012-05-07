function sdi2k_filter_interface, command=command

;--Filter setup as of October 2002:
;  1: 6300 New
;  2: 5577
;  3: 6300 Old (?)
;  4: Neon
;  5: 5890 Na

;--At every call, ensure the serial port is in the correct mode:
   status = 1
   spawn, 'mode com1: baud=19200 data=8 parity=n stop=1 dtr=off rts=off to=off'
   
;--Open the filter com port:
   openu, ftr, 'com1:', /get_lun
   
;--Empty the serial port receive buffer:
   flush, ftr
   
;--Send the supplied command, if any:
   if keyword_set(command) then begin
      writeu, ftr, strupcase(strcompress(string(command))), string(byte([13, 10]))
      flush, ftr
      wait, 0.1
   endif

   inchar = 0b
;--Send a query command:
   writeu, ftr, '??', string(byte([13, 10]))
;   readu, ftr, inchar

;--Now close and re-open the port for read-only access:
;   close, ftr
;   free_lun, ftr
;   openr, ftr, 'com1:', /get_lun

   
;--Now wait until the filter status indicates movement is over:
;   attempts = 0
;   inchar = bytarr(20)
;   gtchar = byte('>')
;   gtchar = gtchar(0)
;   while not(eof(ftr)) and inchar(0) ne gtchar and attempts lt 100 do begin
;         readu, ftr, inchar
;         help, fstat(ftr), /str
;         wait, 0.005
;         if attempts eq 0 then status = string(inchar) else status = [status, string(inchar)]
;         attempts = attempts + 1
;   endwhile
;   
;--Now read back the response string to pass back as 'status':
;   flush, ftr
;   attempts = 0
;   inchar = 0b
;   writeu, ftr, '??', string(byte([13, 10]))
;   wait, 0.01
;   while not(eof(ftr)) and inchar ne gtchar and attempts lt 100 do begin
;         readu, ftr, inchar
;         if attempts eq 0 then status = string(inchar) else status = [status, string(inchar)]
;         wait, 0.005
;         attempts = attempts + 1
;   endwhile
   
;--Close the port:
   close, ftr
   free_lun, ftr
   wait, 7
;--And quit:
   return, status
end
   
   
