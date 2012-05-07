pro sf_event, ev
  @sf_common
  @euv_imtool-commons
  
  widget_control, ev.id, get_uvalue = info

  if info eq 'sf_slider' then begin
      v = 0
      widget_control, sf_slider, get_value = v
      sftimespan = v / 100.0d
      if(sflasttime ne '') then sf_update, sflasttime
      return
  endif

  if info eq 'sf_dumppng' then begin
      wset, sf_hdraw
      img = tvrd(true = 1)
      img = 255B - img
      x = get_midpoint(jd)
      outfile = 'sw_' + strmid(x, 0, 4) + strmid(x, 5, 3) + $
	                strmid(x, 9, 2) + strmid(x, 12, 2) + '.png'
      write_png, outfile, img
  endif

  if info eq 'sf_modesw' then begin
    if sfmode eq 0 then begin
      sfmode = 1
      widget_control, sf_modeswitch, set_value = 'Auto'
      sf_update, sflasttime
    endif else begin
      sfmode = 0
      widget_control, sf_modeswitch, set_value = 'Fixed'
      sf_update, sflasttime
    endelse
  endif
end
