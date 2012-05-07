
mcchoice, 'Analysis stage?', ['STAGE_FIT_LASERS', 'STAGE_FIT_SKIES', 'STAGE_GEOPHYSICAL_RESULTS'], choice
stage = choice.name

mcchoice, 'Image Source?',  ['C:\', 'D:\', 'E:\', 'F:\', 'C:\image\'], sdsk
mcchoice, 'Results Disk?', ['C:\', 'D:\', 'E:\', 'F:\'], rdsk


setenv, "TLR_EPATH=" + sdsk.name
setenv, "TLR_DPATH=" + rdsk.name + "TRAILER\LATEST\"
setenv, "TLR_FPATH=" + rdsk.name + "TRAILER\RESULTS\"
setenv, "TLR_CPATH=" + rdsk.name + "TRAILER\IMAGE\"
setenv, "TLR_FPLOT=0"

nn    = 0
dlist = findfile(getenv("TLR_EPATH") + "*")

k=0
for j=0,n_elements(dlist)-1 do begin
    if strmid(dlist(j), strlen(dlist(j))-1, 1) eq "\" then begin
       partz = str_sep(dlist(j), '\')
       yymmdd = partz(n_elements(partz)-2)
       intro = strmid(yymmdd, 0, 1)
       if intro eq '0' then begin
          if k eq 0 then goodlist = dlist(j) else goodlist = [goodlist, dlist(j)]
          k = 1
       endif
    endif
endfor

goodlist = goodlist(sort(goodlist))
mcchoice, "First day to process?", goodlist, lochoice
mcchoice, "Last day to process?",  goodlist(lochoice.index:*), hichoice
dlist = goodlist(lochoice.index: lochoice.index+hichoice.index)

for j=0,n_elements(dlist)-1 do begin
    if strmid(dlist(j), strlen(dlist(j))-1, 1) eq "\" then begin
       partz = str_sep(dlist(j), '\')
       yymmdd = partz(n_elements(partz)-2)
       intro = strmid(yymmdd, 0, 1)
       if intro eq '0' then begin
          setenv, "SUBDIR="+yymmdd
          spawn, "mkdir " + getenv("TLR_CPATH") + getenv("SUBDIR")
          set_plot, 'win'
          tlr_fringe_analysis, stage = stage
       endif
    endif
endfor
end

