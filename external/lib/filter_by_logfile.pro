;=====================================================================
;
;  This procedure looks through a logfile to check if it describes an 
;  acceptable condition. The logfile is assumed to contain lines of the
;  form "key string = value string". The result is returned in the 
; variable 'decision'.

pro filter_by_logfile, logfile, log_filter, decision

    oneline  = 'dummy'
    dvls     = strupcase(strcompress(log_filter.desired_values, /remove_all))
    decision = strupcase(strcompress(log_filter.default, /remove_all)) eq 'ACCEPT'

;---If we have a logfile, check for the specified filter condition: 
    if file_test(logfile) then begin
       openr, logun, logfile, /get_lun
       while not eof(logun) do begin
             readf, logun, oneline
             lineparts = strupcase(str_sep(strcompress(oneline, /remove_all), '='))
             if lineparts(0) eq strupcase(strcompress(log_filter.key, /remove_all)) then begin
                print, logfile, ' --> ', oneline
                for j=0, n_elements(dvls)-1 do begin
                    if strpos(lineparts(1), dvls(j)) ge 0 then decision = decision or 1
                endfor
             endif   
       endwhile
       close, logun
       free_lun, logun
    endif
end    

