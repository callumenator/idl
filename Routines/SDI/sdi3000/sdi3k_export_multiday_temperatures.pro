pro sdi3k_export_multiday_temperatures, alldays, filename

   sord = sort(alldays.start_time)

   whoami, dir, file
   pathinfo = mc_fileparse(dir + file)
   drive = str_sep(pathinfo(0).path, '\')
   drive = drive(0)

   if not(keyword_set(filename)) then filename = dialog_pickfile(file='PKR_6300_Temperature_History.txt', $
                                      filter='*.txt', $
                                      path=drive + '\Users\Conde\Main\Poker_SDI')
   openw, txtun, filename, /get_lun
   printf, txtun, '    YMD Date UT             Time UT        Time JS         Temp K   Sigma Temp K'
   for j=0L,n_elements(sord) - 1 do begin
       goods = where(alldays(sord(j)).chi_squared  gt 0.5 and $
                     alldays(sord(j)).chi_squared  lt 1.7 and $
                     alldays(sord(j)).signal2noise gt 500, nn)
        if nn gt 5 then begin
           medtemp = median(alldays(sord(j)).temperature(goods))
           sigtemp = stddev(alldays(sord(j)).temperature(goods))
               tcen   = (alldays(sord(j)).start_time + alldays(sord(j)).end_time)/2
               printf, txtun,  dt_tm_mk(js2jd(0d)+1, tcen, format='     Y$-0n$-0d$            h$:m$:s$'), $
                               string(tcen, format='(i15)'), $
                               string(medtemp, format='(f15.1)'), $
                               string(sigtemp, format='(i15)')
        endif else print, 'Bad Record: ', dt_tm_mk(js2jd(0d)+1, tcen, format='Y$-n$-0d$ at h$:m$:s$')
   endfor
   close, txtun
   free_lun, txtun
end