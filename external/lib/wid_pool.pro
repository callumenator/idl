pro wid_pool, name, widx, add=add, del=del, get=get, init=init, destroy=destroy, $
              action=action, refresh=refresh, all=all, specific_cleanup=specific_cleanup, $
              edit=edit, validate_only=validate_only
common wid_pool, wid_pool

;--Check if we need to create the widget pool:
   nwid = n_elements(wid_pool)
   ng     = 0
   if keyword_set(init) or nwid eq 0 then begin
      wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
   endif

;--At every call, make sure there are no invalid "orphan" widgets in the pool:
   goods    = where(widget_info(wid_pool.id, /valid) ne 0, ng)
   if ng gt 0 then begin
      wid_pool = wid_pool(goods) 
   endif else begin
      wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
   endelse
   nwid = n_elements(wid_pool)
   
;--Exit now if we are just validating the pool:
   if n_elements(validate_only) gt 0 then return

;--This option lets us see whats in the pool (useful only for debugging):
   if n_elements(edit) gt 0 then begin
      obj_edt, wid_pool, tagz=edit
      return
   endif

;--Add a new widget to the pool
   if keyword_set(add) and n_elements(widx) ne 0 then begin
      if widget_info(widx, /valid) then begin
         wid_pool = [wid_pool, wid_pool(0)]
         wid_pool(nwid).name = name
         wid_pool(nwid).id   = widx
         wid_pool(nwid).action = 'None'
         wid_pool(nwid).specific_cleanup = 'None'
         if keyword_set(action) then wid_pool(nwid).action = action
         if keyword_set(specific_cleanup) then begin
            wid_pool(nwid).specific_cleanup = specific_cleanup
            if widget_info(wid_pool(nwid).id, /valid) then widget_control, wid_pool(nwid).id, kill_notify=specific_cleanup 
         endif
      endif
   endif

if keyword_set(destroy) then begin
   nfnd   = 0
   widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)
   while nfnd gt 0 do begin
      widsave = wid_pool(widsel(0))
      widx = wid_pool(widsel(0)).id
      if keyword_set(destroy) then begin
         if widget_info(widx, /valid_id) then begin
            widget_control, widx, /destroy 
         endif 
      endif

      goods    = where(widget_info(wid_pool.id, /valid) ne 0, ng)
      if ng gt 0 then begin
         wid_pool = wid_pool(goods) 
      endif else begin
         wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
      endelse
      widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)
      wait, 0.01

      if nfnd gt 0 then begin
         if wid_pool(widsel(0)).id eq widsave.id then begin
            if n_elements(wid_pool) gt 1 then begin
               veceldel, wid_pool, widsel(0)
            endif else begin
               wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
            endelse
            widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)         
         endif
         endif
   endwhile
   goods    = where(widget_info(wid_pool.id, /valid) ne 0, ng)
   if ng gt 0 then begin
      wid_pool = wid_pool(goods) 
   endif else begin
      wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
   endelse
   widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)
endif

if keyword_set(del) then begin
   nfnd   = 0
   widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)
   while nfnd gt 0 do begin
         if n_elements(wid_pool) gt 1 then begin
            veceldel, wid_pool, widsel(0)
         endif else begin
            wid_pool = {s_wid, name: 'Bound to not-exist, I hope', id: -1l, action: 'None', specific_cleanup: 'None'}
         endelse
         widsel = where(strpos(strupcase(strtrim(wid_pool.name, 2)), strupcase(name)) ge 0, nfnd)         
      wait, 0.01
   endwhile
endif

if keyword_set(get) then begin
   nfnd   = 0
   widsel = where(strpos(strupcase(wid_pool.name), strupcase(name)) eq 0, nfnd)
   if nfnd gt 0 then widx = wid_pool(widsel).id else widx = -1L
endif

if keyword_set(all) then begin
   widx = wid_pool(*).id
endif

if keyword_set(action) then begin
   nfnd   = 0
   widsel = where(strpos(strupcase(wid_pool.name), strupcase(name)) ge 0, nfnd)
   if nfnd gt 0 then begin
      widx = wid_pool(widsel).id 
      wid_pool(widsel).action = action
   endif else widx = -1L
endif

if keyword_set(refresh) then begin
   nfnd   = 0
   widsel = where(wid_pool.action ne 'None', nfnd)
   if nfnd gt 0 then begin
      for j=0,nfnd-1 do begin
          widx = wid_pool(widsel(j)).id 
          cmd = wid_pool(widsel(j)).action + ', wid_pool(widsel(j)).name'
          status = execute(cmd)
      endfor
   endif else widx = -1L
endif

end