pro struk_mlev, menu_desc, rootname, struk, new=new, flag=flag
    if not(keyword_set(flag)) then flag=16
    mc_menu,    menu_desc, rootname, flag, new=new

;---Add menu items for each configurable component of the struk structure:
    tnames = tag_names(struk)
    for j=0, n_tags(struk)-1 do begin
        tdesc = size(struk.(j))
        if n_elements(tdesc) eq 4 then begin
           if tdesc(2) eq 8 then begin
              nm = 0
              dummy = where(tag_names(struk.(j)) eq "MENU_CONFIGURABLE", nm)
              if nm ne 0 then begin
                 stype = size(struk.(j), /structure)
                 if stype.type_name eq 'STRUCT' and stype.n_elements eq 1 then begin
                    if struk.(j).menu_configurable then begin
                       stest = size(struk.(j).(0))
                       if stest(2) eq 8 then begin
                          struk_mlev, menu_desc, sentence_case(tnames(j)), struk.(j)
                       endif else begin
                          mc_menu,    menu_desc, sentence_case(tnames(j)), 0
                       endelse
                    endif
                 endif
              endif
           endif
        endif
    endfor
    menu_desc(n_elements(menu_desc)-1).flags = 2
end

pro struk_menu, menu_desc, rootname, struk, new=new
    struk_mlev, menu_desc, rootname, struk, new=new
    nl = 0
    ours = where(menu_desc.flags eq 16, nl)
    if nl gt 0 then begin
       menu_desc(ours).flags = 1
       menu_desc(ours(n_elements(ours)-1)).flags = 3
    endif
end
