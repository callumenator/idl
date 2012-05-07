; Example call:  sdi2k_batch_autoprox, path='d:\users\sdi2000\data\2000_fall\', /all_spex, /choose, lookback_seconds=30*86400L

pro sdi2k_batch_autoprox, path=local_path,   wind_only=wind_only, skip_existing=skip_existing, $
                          all_spex=all_spex, all_winds=all_winds, chooser=chooser, plot_only=plot_only, $
                          lookback_seconds=lookback_seconds

if not(keyword_set(local_path)) then local_path = 'd:\users\sdi2000\data\'
sdi2k_batch_ncquery, file_desc, path=local_path

if not(keyword_set(lookback_seconds)) then lookback_seconds = 3*86400L

if keyword_set(chooser) then begin
   strt = strpos(file_desc(0).name, '\SKY20') + 1
   fsel = strmid(file_desc.name, strt, 99)
   mcchoice, 'First file to process?', fsel, choice
   lodx = choice.index
   mcchoice, 'Last file to process?',  fsel, choice
   hidx = choice.index
   file_desc = file_desc(lodx:hidx)
endif

if not (keyword_set(wind_only) or keyword_set(plot_only)) then begin
   for j=0,n_elements(file_desc)-1 do begin
       if ((file_desc(j).analysis_level eq 'None'  or keyword_set(all_spex)) and $
	   (file_desc(j).insfile        ne 'None') and $
	    file_desc(j).records gt 1 and $
	    file_desc(j).sec_age lt lookback_seconds) then begin
	   print, 'Fitting spectra: ', file_desc(j).name
	   sdi2k_batch_spekfitz, file_desc(j).name, file_desc(j).insfile, skip_existing=skip_existing
           print, 'Fitting winds: ', file_desc(j).name
           sdi2k_batch_windfitz, file_desc(j).name, resarr, windfit, skip_existing=skip_existing
           print, 'Updating Web Plots: ', file_desc(j).name
           sdi2k_batch_plotz, file_desc(j).name, resarr, windfit
       endif
   endfor
endif
 
sdi2k_batch_ncquery, file_desc, path=local_path
if keyword_set(chooser) then file_desc = file_desc(lodx:hidx)


 for j=0,n_elements(file_desc)-1 do begin
     if  file_desc(j).analysis_level eq 'Spectra Fitted' or $
        (file_desc(j).analysis_level eq 'Winds Fitted' and keyword_set(all_winds) and file_desc(j).records gt 1) and $
         file_desc(j).sec_age lt lookback_seconds then begin
         if not(keyword_set(plot_only)) then begin
            print, 'Fitting winds: ', file_desc(j).name
            sdi2k_batch_windfitz, file_desc(j).name, resarr, windfit, skip_existing=skip_existing
         endif
         print, 'Updating Web Plots: ', file_desc(j).name
         sdi2k_batch_plotz, file_desc(j).name, resarr, windfit
     endif
 endfor
 end
