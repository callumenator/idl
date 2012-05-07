
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; read user's defaults for time limits, model settings, etc.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; Last modified: 16-Aug-2002

pro read_defaults, flu

@euv_imtool-commons

line = 'abc'

; -----------------------------------------------
; read and execute the lines in the defaults file
; -----------------------------------------------
while ( not EOF(flu) ) do begin
    readf, flu, line
    if ( strmid(line,0,1)  ne ';') then begin
        result = execute(line)
    endif
endwhile


end
