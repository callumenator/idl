

;\\ INITIALIZE THE DCAI USER INTERFACE
pro DCAI_InitGui, running = running

	COMMON DCAI_Control, dcai_global

	font = 'Ariel*16'

	b0 = widget_base(title = 'Daytime Auroral Imager', col = 1, mbar = menu, /base_align_center)
	DCAI_script_label = widget_label(b0, value = 'Current Schedule: ', font = 'Ariel*17', /align_left)

	b0_top = widget_base(b0, col = 3)

		b0_top_1 = widget_base(b0_top, row = 4)

			script_base = widget_base(b0_top_1, col = 3)
	 		bs = 130
	 		ys = 0
	 		btn_font = 'Ariel*14'
			if keyword_set(running) then btn_val = 'Start Script Exec.' else btn_val = 'Stop Script Exec.'
			start_stop_button = widget_button(script_base, value = btn_val, font = btn_font, uval = {tag:'stop_start_button'}, xs=bs, ys=ys, $
											  tooltip = 'Start/top executing the current schedule script')
			DCAI_btn = widget_button(script_base, value = 'Load Script', font = btn_font, uval = {tag:'load_script_button'}, xs=bs, ys=ys, $
									 tooltip = 'Load a schedule script')
			DCAI_btn = widget_button(script_base, value = 'Reset Script', font = btn_font, uval = {tag:'reset_script_button'}, xs=bs, ys=ys, $
									 tooltip = 'Send reset command to current schedule script')
			sets_base = widget_base(b0_top_1, col = 3)
			DCAI_btn = widget_button(sets_base, value = 'Load Settings', font = btn_font, uval = {tag:'load_settings_button'}, xs=bs, ys=ys, $
									 tooltip = 'Load a new settings file')
			DCAI_btn = widget_button(sets_base, value = 'Save Settings', font = btn_font, uval = {tag:'save_settings_button'}, xs=bs, ys=ys, $
									 tooltip = 'Save the current settings')
			DCAI_btn = widget_button(sets_base, value = 'Show Settings', font = btn_font, uval = {tag:'show_settings_button'}, xs=bs, ys=ys, $
									 tooltip = 'Display the current settings')
			cam_base = widget_base(b0_top_1, col = 3)
			DCAI_btn = widget_button(cam_base, value = 'Camera Driver', font = btn_font, uval = {tag:'start_camera_driver'}, xs=bs, ys=ys, $
									 tooltip = 'Launch an interface to the camera')
			init_base = widget_base(b0_top_1, col = 1)
			DCAI_btn = widget_button(init_base, value = 'Re-Init', font = btn_font, uval = {tag:'reinit'}, xs=bs, ys=ys, $
									 tooltip = 'Reinitialize etalons')

		b0_top_2 = widget_base(b0_top, row = 5)

			;\\ IF A FILTTER WHEEL IS PRESENT, ADD A DROPLIST TO SELECT FILTERS
			tags = tag_names(dcai_global.settings)
			match = where(tags eq 'FILTER', filter_yn)
			if filter_yn eq 1 then begin
				drop1 = widget_base(b0_top_2, col=2, /base_align_left)
					DCAI_filt_lab = widget_label(drop1, value = 'Filter', font=font, xs = 50)
	  				DCAI_filt_list = widget_droplist(drop1, value = dcai_global.settings.filter.name, font=font, uval = {tag:'command_filter'})
			endif

		  	drop2 = widget_base(b0_top_2, col=2, /base_align_left)
		  	  	DCAI_shut_lab = widget_label(drop2, value = 'Shutter', font=font, xs = 50)
		  	  	DCAI_shut_list = widget_droplist(drop2, value = ['open','close'], font=font, uval = {tag:'command_shutter'})

	b0_bottom = widget_base(b0, col = 2)

		b0_bottom_1 = widget_base(b0_bottom, col = 1, /base_align_left)

	  		DCAI_info_label = widget_label(b0_bottom_1, value = 'Info:', font='Ariel*17')
      		DCAI_info = widget_list(b0_bottom_1, xs = 45, ys = 28, font='Ariel*14')

		b0_bottom_2 = widget_base(b0_bottom, row = 2, /base_align_left)

			  	b1_1 = widget_base(b0_bottom_2, row = 2)
					DCAI_list_label = widget_label(b1_1, value = 'Log:', font='Ariel*17')
			    	DCAI_list = widget_text(b1_1, xs = 58, ys = 16, font='Ariel*14', /scroll)

			  	b1_2 = widget_base(b0_bottom_2, row = 2)
			    	DCAI_list_label = widget_label(b1_2, value = 'Current Queue:', font='Ariel*17')
			    	DCAI_queue = widget_list(b1_2, xs = 70, ys = 8, font='Ariel*14')

	n_etalons = n_elements(dcai_global.settings.etalon)
	leg_wids = lonarr(n_etalons, 3)
	b0_leg_indicators = widget_base(b0, col = n_etalons)
		for k = 0, n_etalons - 1 do begin
			etalon_base = widget_base(b0_leg_indicators, row = 4, frame=1)
			label = widget_label(etalon_base, value = 'Etalon ' + string(k, f='(i0)'), font=font)
			leg_wids[k,0] = widget_draw(etalon_base, xs = 300, ys = 15)
			leg_wids[k,1] = widget_draw(etalon_base, xs = 300, ys = 15)
			leg_wids[k,2] = widget_draw(etalon_base, xs = 300, ys = 15)
		endfor


	widget_control, b0, /realize
	widget_control, b0, timer = dcai_global.info.timer_tick_interval

	leg_tvids = intarr(n_etalons, 3)
	for k = 0, n_etalons - 1 do begin
		widget_control, get_value = leg1_tv_id, leg_wids[k,0]
		widget_control, get_value = leg2_tv_id, leg_wids[k,1]
		widget_control, get_value = leg3_tv_id, leg_wids[k,2]
		leg_tvids[k,*] = [leg1_tv_id,leg2_tv_id,leg3_tv_id]
	endfor

	gui = {base:b0, $
		   font:font, $
		   menu:menu, $
    	   script_label:DCAI_script_label, $
    	   log:DCAI_list, $
    	   queue:DCAI_queue, $
    	   info:DCAI_info, $
    	   start_stop_button:start_stop_button, $
     	   filter_list:DCAI_filt_list, $
     	   leg_tvids:leg_tvids}

	dcai_global = create_struct('gui', gui, dcai_global)

end
