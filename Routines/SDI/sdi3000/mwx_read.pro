function mwx_read, flis
mwx_rec = {time: 0d, site: 'unknown', temperature: 0., deltemp: 0., los_wind: 0., delwind: 0., dir: 'unknown', az: 0., el: 0.}
if flis(0) eq '' then return, 'No data found'

first = 1
oneline = 'dummy'
for j=0,n_elements(flis) - 1 do begin
    openr, mwxun, flis(j), /get_lun
    readf, mwxun, oneline
    if strlen(strtrim(oneline, 2)) lt 10 then begin
       mwx_rec.site = strcompress(oneline, /remove_all)
       readf, mwxun, oneline
       fields = strsplit(strcompress(oneline), ' ', /extract)
       day = fields(0)
       month = strupcase(fields(1))
       month = where(['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'] eq month)
       month = 1 + month(0)
       year = fields(2)
       while not(eof(mwxun)) do begin
          readf, mwxun, oneline
          fields = strsplit(strcompress(oneline), ' ', /extract)
          hours = fields(0)
          scnds = 3600.*hours
          mwx_rec.time = ymds2js(year, month, day, scnds) + 9.*3600. - 86400.
          mwx_rec.temperature = fields(3)
          mwx_rec.deltemp = fields(4)
          mwx_rec.los_wind = fields(5)
          mwx_rec.delwind = fields(6)
          mwx_rec.az = fields(7)
          mwx_rec.el = fields(8)
          mwx_rec.dir = fields(9)
          if first then begin
             mwx_data = mwx_rec
             first = 0
          endif else mwx_data = [mwx_data, mwx_rec]
       endwhile
    endif else begin
       fields = strsplit(strcompress(oneline), ' ', /extract)
       year  = strmid(fields(1), 4, 4)
       month = strmid(fields(1), 2, 2)
       day   = strmid(fields(1), 0, 2)
       while not(eof(mwxun)) do begin
          readf, mwxun, oneline
          fields = strsplit(strcompress(oneline), ' ', /extract)
          hours = fields(1)
          scnds = 3600.*hours
          mwx_rec.time = ymds2js(year, month, day, scnds) + 9.*3600. - 86400.
          mwx_rec.temperature = fields(2)
          mwx_rec.az = 0.
          mwx_rec.el = 90.
          if first then begin
             mwx_data = mwx_rec
             first = 0
          endif else mwx_data = [mwx_data, mwx_rec]
       endwhile
    endelse
    mwx_data = mwx_data(sort(mwx_data.time))
    close, mwxun
    free_lun, mwxun
endfor
return, mwx_data
end