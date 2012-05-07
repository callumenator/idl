; Example calls:  sdi3k_batch_autoprox, path='d:\users\sdi2000\data\2000_fall\', filter=['*.pf', '*.nc'], calfit='none', skyfit='new', windfit='all', /choose, lookback_seconds=30*86400L
;                 sdi3k_batch_autoprox, path='d:\users\sdi3000\data\spectra', filter=['*.pf', '*.nc', '*.sky', '*.las'], calfit='none', skyfit='none', windfit='all', plotting='all', lookback_seconds=18L*86400L, /choose

pro sdi3k_batch_autoprox, path=local_path, $
                          filter=filter, $
                          lookback_seconds=lookback_seconds, $
                          chooser=chooser, $
                          skyfit=skyfit, $
                          calfit=calfit, $
                          windfit=windfit, $
                          plotting=plotting, $
                          plotstage=plotstage, $
                          plot_folder=plot_folder, $
                          ask_flat=ask_flat, $
                          drift_mode=drift_mode, $
                          xy_only=xy_only

if not(keyword_set(local_path))       then local_path       = where_is('mawson_data')
if not(keyword_set(filter))           then filter           = ['*.pf', '*.nc', '*.sky', '*.las']
if not(keyword_set(lookback_seconds)) then lookback_seconds = 20*86400L
if not(keyword_set(calfit))           then calfit           = 'new' ; options are: 'all', 'none', or 'new'
if not(keyword_set(skyfit))           then skyfit           = 'new'
if not(keyword_set(windfit))          then windfit          = 'all'
if not(keyword_set(plotting))         then plotting         = 'none'
if not(keyword_set(drift_mode))       then drift_mode       = 'data'

calfit   = strupcase(calfit)
skyfit   = strupcase(skyfit)
windfit  = strupcase(windfit)

if keyword_set(ask_flat) then begin
print, local_path + "Wind_flat_field_???_5577*.sav"
   flats    = findfile(local_path + "Wind_flat_field_*_5577*.sav")
   mcchoice, 'Wind flat field file for GREEN?', [flats, 'None'], choice, help='This flat field correction will only be applied to 5577 winds'
   if choice.name ne 'None' then setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=' + choice.name
   flats    = findfile(local_path + "\Wind_flat_field_???_6300*.sav")
   mcchoice, 'Wind flat field file for RED?', [flats, 'None'], choice, help='This flat field correction will only be applied to 6300 winds'
   if choice.name ne 'None' then setenv, 'SDI_RED_ZERO_VELOCITY_FILE=' + choice.name
endif


sdi3k_batch_ncquery, file_desc, path=local_path, filter=filter, /verbose
file_desc = file_desc(where(file_desc.sec_age le lookback_seconds))

skylis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'SKY'))
calz   = where(strupcase(file_desc.metadata.viewtype) eq 'CAL', nncal)
if nncal gt 0 then begin
   callis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'CAL'))
   skylis = skylis(sort(skylis.name))
   callis = callis(sort(callis.name))
endif

if keyword_set(chooser) then begin
   mcchoice, 'First file to process?', skylis.preferred_name, choice
   lodx = choice.index
   mcchoice, 'Last file to process?',  skylis.preferred_name, choice
   hidx = choice.index
   skylis = skylis(lodx<hidx:hidx>lodx)
endif


for j=0,n_elements(skylis)-1 do begin
       print, 'Processing: ', skylis(j).preferred_name
       if nncal gt 0 then begin
          insinf   = mc_fileparse(skylis(j).metadata.path + strmid(skylis(j).insfile, 0, 4) + strmid(skylis(j).insfile, 9, 999))
          insname  = insinf.name_only
          insinf   = mc_fileparse(skylis(j).metadata.path + strmid(callis.insfile,    0, 4) + strmid(callis.insfile,    9, 999))
          insz     = insinf.name_only
          this_ins = where(insz eq insname, nn)
          if nn gt 0 then begin
             this_ins = callis(this_ins(0)).name
             if getenv('user_specified_insprof') ne '' then this_ins = getenv('user_specified_insprof')
             if strupcase(drift_mode) ne 'DATA' then drift_mode=this_ins
             sdi3k_read_netcdf_data, this_ins, metadata=mm, /close
             doit = size(mm, /tname) eq 'STRUCT'
             if doit then doit = doit and mm.maxrec gt 0
             if doit and skyfit ne 'NONE' then sdi3k_batch_spekfitz, skylis(j).name, this_ins, skip_existing=(skyfit eq 'NEW'), skip_insfit=(calfit eq 'NONE')
          endif
       endif
       sdi3k_read_netcdf_data, skylis(j).name, metadata=mm, /close
       if windfit ne 'NONE' and mm.spekfit_status eq 'Spectra Fitted' then begin
          if (windfit eq 'ALL') or (skylis(j).metadata.windfit_status ne 'Winds Fitted') then sdi3k_batch_windfitz, skylis(j).name, drift_mode=drift_mode
       endif
       if strupcase(strcompress(plotting, /remove)) ne 'NONE' then begin
          sdi3k_batch_plotz, skylis(j).name, skip_existing=(strupcase(strcompress(plotting, /remove)) eq 'NEW'), stage=plotstage, plot_folder=plot_folder, drift_mode=drift_mode, xy_only=xy_only
       endif
       sdi3k_read_netcdf_data, skylis(j).name, metadata=mm, /close
endfor
end
