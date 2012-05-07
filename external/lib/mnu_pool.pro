;========================================================================
;   Test if "fname" specifies a valid plugin and, if so, fill the 
;   appropriate fields of "item_desc".  If not, return item_desc
;   with fields set to "Unknown".
pro query_plugin, obj_name, item_desc
    item_desc = {s_menite, class_name:        'Unknown', $
                           refresh_name:      'Unknown', $
                           menu_name:         'Unknown', $
                           xwindow_object:    'Unknown'}
    get_header, obj_name, header, status=sts, /code_only
    nmat = 0
    if not(sts) then begin
       matched = where(strpos(strupcase(header(0,*)), 'CLASS_NAME') ge 0, nmat)
       if nmat gt 0 then item_desc.class_name = header(1, matched(0)) 
       matched = where(strpos(strupcase(header(0,*)), 'MENU_NAME') ge 0, nmat)
       if nmat gt 0 then item_desc.menu_name = header(1, matched(0)) 
       matched = where(strpos(strupcase(header(0,*)), 'REFRESH_NAME') ge 0, nmat)
       if nmat gt 0 then item_desc.refresh_name = header(1, matched(0)) 
    endif
end

;========================================================================
;   Register a plugin specified by fname, if it turns out to be valid:
pro menu_register, obj_name, build=build, level=level
    common menu_items, menu_items
    if not(keyword_set(level)) then level=0
    query_plugin, obj_name, item_desc
    if item_desc.menu_name ne 'Unknown' then begin
       mc_menu, build, item_desc.menu_name, level
       if n_elements(menu_items) eq 0 then menu_items = item_desc else begin
          nmat = 0
          matched = where(strpos(strupcase(menu_items.menu_name), strupcase(item_desc.menu_name)) ge 0, nmat)
          if nmat eq 0 then menu_items = [menu_items, item_desc]
       endelse
    endif    
end

;========================================================================
;   For xwindow objects, this is a generic "autorun" procedure:
pro mnu_xwindow_autorun, instance, topname=tn, extra_menus=extra_menus
;---Create the plot window, using a slightly modified version of David Fanning's
;   "xwindow" procedure:
    wid_pool, tn, gld, /get
    xwindow,  instance.class_name + '_tik, info.wtitle', /output,  $
              top=top, group_leader=gld, menubase=xmenu, wid=wid, drawid=drawid, $
              wxsize=instance.geometry.xsize, wysize=instance.geometry.ysize, wtitle=instance.description, $
              caller_cleanup='mnu_xwindow_cleanup'
;---Register the plot xwindow name and top-level widget index with "wid_pool":
    widget_control, top, get_uvalue=info
    specific_cleanup = 'None'
    nm = 0
    dummy = where(tag_names(instance) eq "SPECIFIC_CLEANUP", nm)
    if nm ne 0 then specific_cleanup = instance.specific_cleanup
    wid_pool, info.wtitle, top, /add, action=instance.class_name + '_tik', specific_cleanup=specific_cleanup
    instance.id = top

;---Create extra menu items specific to this plugin:
    mc_menu,     menu_desc, 'Configure',        1, event_handler=instance.class_name + '_event'
    for j=0, n_tags(instance)-1 do begin
        tdesc = size(instance.(j))
        if n_elements(tdesc) eq 4 then begin
           if tdesc(2) eq 8 then begin
              tnames = tag_names(instance.(j))
              nm = 0
              dm = where(tnames eq 'MENU_CONFIGURABLE', nm)
              if nm gt 0 then begin
                 if instance.(j).menu_configurable then begin
                    if n_elements(slist) eq 0 then slist = j else slist = [slist, j]
                 endif
              endif
           endif
        endif
    endfor
    tnames = tag_names(instance)
    tnames = sentence_case(tnames)
    for j=0,n_elements(slist)-2 do begin
        mc_menu, menu_desc,  tnames(slist(j)), 0, event_handler='mnu_xwindow_config'
    endfor
    mc_menu, menu_desc,  tnames(slist(n_elements(slist)-1)), 2, event_handler='mnu_xwindow_config'
    if keyword_set(extra_menus) then menu_desc = [menu_desc, extra_menus]
    mc_menu,     menu_desc, 'Help',            0, event_handler=instance.class_name + '_event'
    menu = cw_pdmenu (xmenu, menu_desc, /mbar, /return_full_name, delimiter='|')
;---Ensure the extra menu items are visible to the user:
    widget_control, menu, /realize
    widget_control, menu, iconify=1
    widget_control, menu, iconify=0

;---Create a dummy base widget inside the top-level base for the xwindow.  We will 
;   use the user-value field of this widget to store the properties settings for this plugin:

    settings = widget_base(top)
    wid_pool, 'Settings: ' + info.wtitle, settings, /add
    widget_control, settings, set_uvalue=instance
    status = execute(instance.class_name + '_tik, info.wtitle')
    widget_control, settings, event_pro=instance.class_name + '_event'
    if instance.automation.timer_ticking then widget_control, settings, timer=instance.automation.timer_interval
end

;==========================================================================================
; For xwindow objects, this is the generic cleanup routine:
pro mnu_xwindow_cleanup, wtitle
    wid_pool, 'Settings: ' + wtitle, widx, /destroy
    wid_pool, wtitle, widx, /destroy
end

;==========================================================================================
; For xwindow objects, this is a generic properties editor:
pro mnu_xwindow_config, event
    widget_control, event.top, get_uvalue=info
    wid_pool, 'Settings: ' + info.wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=instance
    fields = tag_names(instance)
    widget_control, event.id, get_uvalue=menu_item
    for j=0,n_elements(fields)-1 do begin
        if (menu_item eq 'Configure|' + sentence_case(fields(j))) then begin
            item = instance.(j)
            nue = 0
            goods = where(item.user_editable ge 0, nue)
            if nue gt 0 then begin
               if fields(j) eq 'COLORS' then begin
                  mnu_color_edit, item, instance, event.top, sidx
               endif else begin
                  obj_edt, item, tagz=item.user_editable
               endelse
               instance.(j) = item
            endif
        endif
    endfor
    widget_control, sidx, set_uvalue=instance
end

pro mnu_color_edit, item, instance, widx, sidx
    optns = sentence_case(tag_names(item))
    optns = [optns(item.user_editable), 'Color Tables', 'Cancel']
    mcchoice, 'Color Item?', optns, choice
    if choice.name eq 'Cancel' then return
    if choice.name ne 'Color Tables' then begin
       optns = tag_names(host.colors)
       optns = optns(1:20)
       mcchoice, 'Color for ' + choice.name, optns, culla
       item.(choice.index) = culla.index
    endif else begin
       xloadct, bottom=host.colors.imgmin, ncolors=host.colors.imgmax - host.colors.imgmin + 1, $
                updatecallback='mnu_xwindow_updct', updatecbdata=widx
    endelse
    widget_control, sidx, set_uvalue=instance
end

pro mnu_xwindow_updct, data=widx
;---Copy the new palette to the xwindow info structure:
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    culrange= host.colors.imgmax - host.colors.imgmin
    tvlct, rr, gg, bb, /get
    info.r(host.colors.imgmin:host.colors.imgmax) = rr(host.colors.imgmin:host.colors.imgmax)
    info.g(host.colors.imgmin:host.colors.imgmax) = gg(host.colors.imgmin:host.colors.imgmax)
    info.b(host.colors.imgmin:host.colors.imgmax) = bb(host.colors.imgmin:host.colors.imgmax)
    widget_control, widx, set_uvalue=info
end



;========================================================================
;   This is the entry point for mnu_pool.
    pro mnu_pool, search=search, $
                  dispatch=dispatch, $
                  build=build, $
                  level=level, $
                  delimiter=delimiter
    common menu_items, menu_items
    if not(keyword_set(delimiter)) then delimiter='|'

;---Search will register all plugins that match the given filename template:
    if keyword_set(search) then begin
       find_obj, search, obj_names, class_names, descriptions, count, /code_only
       mensort = sort(descriptions(0:count-1))
       if count gt 0 then begin
          for j=0, count-1 do menu_register, obj_names(mensort(j)), build=build, level=level
       endif
    endif
    
;---Test an event structure to see if the menu event should activate a registered plugin:
    if keyword_set(dispatch) and n_elements(menu_items) gt 0 then begin
       nmat = 0
       button_pushed = str_sep(strupcase(dispatch.value), delimiter)
       button_pushed = button_pushed(n_elements(button_pushed)-1)
       matched = where(strupcase(menu_items.menu_name) eq button_pushed, nmat)
       if nmat gt 0 then begin
          for j=0,n_elements(matched)-1 do begin
              new_obj, menu_items(matched(j)).class_name, instance
              status = execute(menu_items(matched(j)).class_name + '_autorun, instance')
          endfor
       endif
    endif
end

