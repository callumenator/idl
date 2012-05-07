;--This procedure connects to the GEDDS server and gets files as 
;  specified in the ftp batch job:

;--Attempt to connect
   logname = 'c:\users\conde\main\idl\trailer\rasdial.log'
   spawn, 'rasdial "Gedds 2623" /disconnect > ' + logname
   spawn, 'rasdial "Gedds 2623" optics\optics elite > ' + logname
   
;--Retry until we get through:   
   while not(tlr_connected(logname, 'Successfully connected to GEDDS 2623')) do begin
         wait, 60
         spawn, 'rasdial "Gedds 2623" optics\optics elite > ' + logname
   endwhile
   
;--Send today's files:      
   spawn, 'ftp -n -i < c:\users\conde\main\idl\trailer\tlr_oth_ftp_script.scr'
   
;--Wait a while, to allow tardis time server some exclusive access to the line:
   wait, 10
   
;--Disconnect:
   spawn, 'rasdial "Gedds 2623" /disconnect > ' + logname
end