function fitstape,command,unit,bitpix,data
;+
; NAME:
;       FITSTAPE
; PURPOSE:
;       Subroutine to perform FITS tape I/O.   
; EXPLANATION:
;       For VMS or Unix IDL only
;
; CALLING SEQUENCE:  
;       status = fitstape( command, unit, bitpix, data )
;
; INPUTS:
;       command - string command from the following choices
;               'init' - initialization (must be first call to fitstape)
;               'read' - get next 2880 byte data buffer
;               'eof'  - check for end of tape file
;               'write'- write 2880 byte data buffer
;               'woef' - empty buffer and write end-of-file
;       unit -   tape unit number
;       bitpix - bits/per data element (used to control byte swapping)
;               (required for 'read' and 'write')
;               (for 'init' command this parameter gives
;               the blocking factor, number of 2880 byte
;               records per tape record. if not supplied 1 is
;               assumed)
;       data - 2880 byte data array if 'write' command
;
; OUTPUTS:
;       data - 2880 byte data array if 'read' command
;               status is returned as the function value
;               with the following meanings.
;               'init' = 1
;               'read' = !err returned by taprd
;               'write' = 1
;               'eof'  = 1 if at end of file
;                       0 if not at end of file
;               'weof' = 1
;
; COMMON BLOCKS
;       QFITSTAPE
;
; HISTORY
;       Version 1  D. Lindler  Nov 1986
;       Converted to IDL Version 2.  M. Greason, STX, June 1990.
;       Recognize BITPIX = -32 and BITPIX = -64   W. Landsman April 1992
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
;---------------------------------------------------------------
common qfitstape,qbuffer,qnbuf,qipos,qnb
;
cmd=strupcase(command)          ;change to upper case
;
case cmd of
        'INIT' : begin
                if N_params() lt 2 then bitpix=1
                qnb=bitpix
                qbuffer=bytarr(2880*qnb)        ;tape buffer
                qnbuf=0                 ;number of 2880 blocks in buffer
                qipos=0                 ;crrent block position
                return,1
                end
        'READ' : begin
                if qipos ge qnbuf then begin ;need to read from tape?
                   on_ioerror,lab1
                   taprd,qbuffer,unit
lab1:      if !err lt 0 then begin
                        if !err EQ -4 then print,'%I: End-Of-File' else $
                                print,strmessage(-!err)
                        return,!err
                   endif
                   qnbuf=!err/2880      ;number of 2880 blocks
                   if qnbuf*2880 ne !err then begin
                        print,'FITSTAPE -- invalid record size'
                        print,'  Not multiple of 2880 bytes'
                        return,-1
                   end
                   qipos=0
                end; if need to read from tape
                data=qbuffer[(qipos*2880):(qipos*2880+2879)]
                case bitpix of
                   16: byteorder,data,/NtoHS
                   32: byteorder,data,/NtoHL
                  -32: byteorder,data,/XDRTOF
                  -64: byteorder,data,/XDRTOD
                 ELSE:
                 endcase
                qipos=qipos+1
                return,qnbuf*2880
                end
        'EOF' : begin
                if qipos lt qnbuf then return,0
                on_ioerror,lab2
                taprd,qbuffer,unit
lab2:
                if !err eq -4 then begin ;eof?
                        skipf,unit,-1           ;go back
                        return,1                ;return true for eof
                endif
                skipf,unit,-1,1                 ;skip back
                return,0                        ;not end of file
                end
        'WRITE' : begin
                case bitpix of
                 16: byteorder,data,/HtoNS ;swap bytes
                 32: byteorder,data,/HtoNL
                -32: byteorder,data,/FTOXDR
                -64: byteorder,data,/DTOXDR
                else:
                endcase
                qbuffer[qipos*2880] = data
                qipos=qipos+1
                if qipos ge qnb then begin
                        tapwrt,qbuffer,unit
                        qipos=0
                endif
                return,1
                end
         'WEOF' : begin
                if qipos ne 0 then tapwrt,qbuffer[0:qipos*2880-1],unit
                weof,unit
                qipos=0
                return,1
                end
        else :  message,'Invalid command specified for FITSTAPE'
endcase
return,1
end
