pro sdi3k_ftp_latest_spectra, remote_ip, user, pass, local_dir, remote_dir, intro_code, site_name
jsnow  = dt_tm_tojs(systime(/UTC))
filter = dt_tm_mk(js2jd(0d)+1, jsnow, format=intro_code + 'Y$_doy$_' + site_name + '_*.*')
flis   = findfile(local_dir + filter)
if n_elements(flis) gt 1 then return

openw,  ftpun, 'c:\sdi_getter.ftp', /get_lun
printf, ftpun, 'open ' + remote_ip
printf, ftpun,  user
printf, ftpun,  pass
printf, ftpun, 'lcd ' + local_dir
printf, ftpun, 'cd '  + remote_dir
printf, ftpun, 'bin'
printf, ftpun, 'hash'
printf, ftpun, 'prompt'
printf, ftpun, 'passive'
printf, ftpun, 'mget "' + filter +'"'
printf, ftpun, 'quit'
close,  ftpun
free_lun, ftpun
spawn, 'ftps -s:c:\sdi_getter.ftp'
end