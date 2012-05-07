;========================================================================
; This routine adds one item to a pull-down menu:
pro mc_menu, menu_desc, label, rank, new=new, event_handler=handler
    item = {CW_PDMENU_S, flags: 0, name: 'Dummy'}
    item.flags = rank
    item.name  = label
    if keyword_set(handler) then item.name = item.name + '\' + handler
    if n_elements(menu_desc) lt 1 or keyword_set(new) then begin
       menu_desc = item
    endif else begin
       menu_desc = [menu_desc, item]
    endelse
end

