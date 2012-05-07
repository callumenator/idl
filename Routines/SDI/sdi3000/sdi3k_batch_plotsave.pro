pro sdi3k_batch_plotsave, plot_dir, mm, ptype, test_exist=test_exist, plot_folder=plot_folder, doystring=doystring
    lamstring = strcompress(string(fix(10*mm.wavelength_nm)), /remove_all)
    year      = strcompress(string(fix(mm.year)),             /remove_all)
    if keyword_set(plot_folder) then year = plot_folder
    scode     = strcompress(mm.site_code, /remove_all)
    if strupcase(scode) eq 'PF' then scode = 'PKR'
    md_err = 0
    catch, md_err
    if md_err ne 0 then goto, keep_going
    folder = plot_dir + year + '_' + scode + '_' + lamstring + '\' + ptype + '\'
    if !version.release ne '5.2' then file_mkdir, folder else spawn, 'mkdir ' + folder
keep_going:
    if not(keyword_set(doystring)) then doystring = string(mm.start_day_ut, format='(i3.3)')
    fname  = folder + ptype + '_' + scode + '_' + year + '_DOY' + $
             doystring + '_' + lamstring + '.png'
    if keyword_set(plot_folder) then fname  = folder + ptype + '_' + scode + '_' + year + '_' + lamstring + '.png'
    if keyword_set(test_exist) then begin
       test_exist = file_test(fname)
    endif else begin
       gif_this, file=fname, /png
       print, 'Wrote plot file: ', fname
    endelse
end
