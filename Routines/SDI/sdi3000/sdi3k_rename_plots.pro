pdir = 'c:\inetpub\wwwroot\conde\sdiplots\'
flis = file_search(pdir, '*.png')

for j=0,n_elements(flis) - 1 do begin
;for j=0,10 do begin
    if strpos(flis(j), '_PKR_') ge 0 and strpos(flis(j), '_PKR_2008') lt 0 then begin
       cmd = 'rename ' + flis(j) + ' '
       base    = strmid(flis(j), 0, strlen(flis(j))-21)
       other   = strmid(flis(j), strlen(flis(j))-20, 200)
       site    = strmid(flis(j), 38, 5)
       newname = base + site + other
       xx = mc_fileparse(newname)
       newname = xx.namepart
;       print, 'rename ' + flis(j) + ' ' + newname
       spawn, 'rename ' + flis(j) + ' ' + newname, /log
       print, newname
       wait, 0.001
    endif
endfor
end