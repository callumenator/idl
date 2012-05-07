pro read_hgip_photometers, flis, o2n2
    oneline = 'dummy'
    o2n2_rec = {filename: 'unknown', header: 'unknown', time: 0D, o2n2: 0.}
    for j=0,n_elements(flis) - 1 do begin
        o2n2_rec.filename = flis(j)
        nameinfo = mc_fileparse(flis(j))
        year = strmid(nameinfo.name_only, strlen(nameinfo.name_only) - 6, 4)
        openr, gipun, flis(j), /get_lun
               readf, gipun, oneline
               o2n2_rec.header = oneline
               readf, gipun, oneline
               readf, gipun, oneline
               oneline = strcompress(oneline, /remove_all)
               nobs    = fix(oneline)
               doyz    = fltarr(nobs)
               an_o2n2 = replicate(o2n2_rec, nobs)
               tcount  = 0
               while tcount lt nobs do begin
                     readf, gipun, oneline
                     fields  = strsplit(strcompress(oneline), ' ', /extract)
                     for k=0,n_elements(fields) - 1 do begin
                         ydn2md,  year, fix(fields(k)), mmm, ddd
                         an_o2n2(tcount + k).time = ymds2js(year, mmm, ddd, (float(fields(k)) - fix(fields(k)))*86400)
                     endfor
                     tcount = tcount + n_elements(fields)
               endwhile
               for k= 0, nobs -1 do begin
                   readf, gipun, oneline
                   an_o2n2(k).o2n2 = float(oneline)
               endfor
        close, gipun
        free_lun, gipun
        if j eq 0 then o2n2 = an_o2n2 else o2n2 = [o2n2, an_o2n2]
    endfor
    o2n2 = o2n2(sort(o2n2.time))
end
