function tlr_connected, logname, good_words
         connex = 0
         oneline = 'dummy'
         openr, logun, logname, /get_lun
         while not(eof(logun)) do begin
               readf, logun, oneline
               connex = connex or (strpos(strupcase(oneline), strupcase(good_words)) ge 0)
         endwhile
         close, logun
         free_lun, logun
         return, connex
end
         