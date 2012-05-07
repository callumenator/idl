; Example call:
;
; sdi3k_batch_repair, bad_path='d:\Mawson\2007_Data', good_path='k:\Mawson\2007_Data\', $
;                     filter=['*.pf', '*.nc', '*.sky', '*.las'], $
;                     calfit='none', skyfit='none', windfit='none', plot='none', /choose, lookback_seconds=9000L*86400L

pro sdi3k_batch_repair,   bad_path=bad_path, $
                          good_path=good_path, $
                          filter=filter, $
                          lookback_seconds=lookback_seconds, $
                          chooser=chooser, $
                          skyfit=skyfit, $
                          calfit=calfit, $
                          windfit=windfit, $
                          plotting=plotting

if not(keyword_set(local_path))       then local_path       = 'd:\users\sdi3000\data\spectra\'
if not(keyword_set(filter))           then filter           = ['*.pf', '*.nc']
if not(keyword_set(lookback_seconds)) then lookback_seconds = 3*86400L
if not(keyword_set(calfit))           then calfit           = 'all' ; options are: 'all', 'none', or 'new'
if not(keyword_set(skyfit))           then skyfit           = 'all'
if not(keyword_set(windfit))          then windfit          = 'all'
if not(keyword_set(plotting))         then plotting         = 'all'

calfit   = strupcase(calfit)
skyfit   = strupcase(skyfit)
windfit  = strupcase(windfit)

sdi3k_batch_ncquery, file_desc, path=bad_path, filter=filter, /verbose
file_desc = file_desc(where(file_desc.sec_age le lookback_seconds))

skylis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'SKY'))
calz   = where(strupcase(file_desc.metadata.viewtype) eq 'CAL', nncal)
if nncal gt 0 then begin
   callis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'CAL'))
   skylis = skylis(sort(skylis.name))
   callis = callis(sort(callis.name))
endif

;badz   = where(skylis.metadata.end_time - skylis.metadata.start_time  lt 300 or $
;           abs(skylis.metadata.end_time - skylis.metadata.start_time) gt 3.*86400L, nn)

badz   = where(skylis.metadata.year eq 2000, nn)

if nn eq 0 then return
;skylis = skylis(badz)

if keyword_set(chooser) then begin
   mcchoice, 'First file to process?', skylis.preferred_name, choice
   lodx = choice.index
   mcchoice, 'Last file to process?',  skylis.preferred_name, choice
   hidx = choice.index
   skylis = skylis(lodx:hidx)
endif

;--Try to get a good copy of each dodgey file from the "good_path"
for j=0,n_elements(skylis)-1 do begin
    good_one = good_path + skylis(j).metadata.namepart
    if file_test(good_one) then begin
       sdi3k_read_netcdf_data, good_one, metadata=mm, /close
       stop
;       if mm.end_time - mm.start_time  gt 300 and abs(mm.end_time - mm.start_time) lt 3.*86400L then begin
       if mm.year ne 2000 then begin
          print, "copy " + good_one + " to " + skylis(j).fullname
       endif
    endif
endfor

stop


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
             sdi3k_read_netcdf_data, this_ins, metadata=mm, /close
             doit = size(mm, /tname) eq 'STRUCT'
             if doit then doit = doit and mm.maxrec gt 0
             if doit and skyfit ne 'NONE' then sdi3k_batch_spekfitz, skylis(j).name, this_ins, skip_existing=(skyfit eq 'NEW'), skip_insfit=(calfit ne 'ALL')
          endif
       endif
       sdi3k_read_netcdf_data, skylis(j).name, metadata=mm, /close
       if windfit ne 'NONE' and mm.spekfit_status eq 'Spectra Fitted' then begin
          if (windfit eq 'ALL') or (skylis(j).metadata.windfit_status ne 'Winds Fitted') then sdi3k_batch_windfitz, skylis(j).name
       endif
       if strupcase(strcompress(plotting, /remove)) ne 'NONE' then begin
          sdi3k_batch_plotz, skylis(j).name, skip_existing=(strupcase(strcompress(plotting, /remove)) eq 'NEW')
       endif
endfor
end
