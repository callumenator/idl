pro sdi2k_read_crlresults, resfile, res_crl

crlrec = {s_crl, time: 0d, $
            intensity: 0., $
      sigma_intensity: 0., $
           background: 0., $
     sigma_background: 0., $
             los_wind: 0., $
       sigma_los_wind: 0., $
          temperature: 0., $
    sigma_temperature: 0.}

oneline = 'Dummy'      
openr, resun, resfile, /get_lun
readf, resun, oneline
oneline = strtrim(oneline, 2)
oneline = strcompress(oneline)
vals    = str_sep(oneline, ' ')
year    = fix(strmid(vals(1), 0, 2))
if year lt 50 then year = 2000 + year else year = 1900 + year
month   = fix(strmid(vals(1), 2, 2))
day     = fix(strmid(vals(1), 4, 2))

while not(eof(resun)) do begin
      readf, resun, oneline
      oneline = strtrim(oneline, 2)
      oneline = strcompress(oneline)
      vals    = str_sep(oneline, ' ')
      hrs                      = float(vals(0))
      crlrec.time              = ymds2js(year, month, day, 3600*hrs)
      crlrec.intensity         = vals(1)
      crlrec.sigma_intensity   = vals(2)
      crlrec.background        = vals(3)
      crlrec.sigma_background  = vals(4)
      crlrec.los_wind          = vals(5)
      crlrec.sigma_los_wind    = vals(6)
      crlrec.temperature       = vals(7)
      crlrec.sigma_temperature = vals(8)
      if n_elements(resarr) eq 0 then resarr = crlrec else resarr = [resarr, crlrec]  
      wait, 0.01
endwhile
close, resun
free_lun, resun
res_crl = resarr
end