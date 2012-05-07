

;\\ Initialize the ASC user interface
pro ASC_InitGui, running = running

	COMMON ASC_Control, info, gui

	font = 'Ariel*16'
	asc_base = widget_base(title = 'ASC', col = 3)

	b1 = widget_base(asc_base, row = 4)
	  asc_script_label = widget_label(b1, value = 'Current Schedule: ', font = 'Ariel*17')
	  b1_1 = widget_base(b1, row = 2)
		asc_list_label = widget_label(b1_1, value = 'Log:', font='Ariel*17')
	    asc_list = widget_text(b1_1, xs = 58, ys = 24, font='Ariel*14', /scroll)
	  b1_2 = widget_base(b1, row = 2)
	    asc_list_label = widget_label(b1_2, value = 'Current Queue:', font='Ariel*17')
	    asc_queue = widget_list(b1_2, xs = 70, ys = 8, font='Ariel*14')
	  b1_3 = widget_base(b1, row = 2)
      asc_info_label = widget_label(b1_3, value = 'Info:', font='Ariel*17')
      asc_info = widget_list(b1_3, xs = 70, ys = 4, font='Ariel*14')

	b2 = widget_base(asc_base, row = 4)
	  asc_wind = widget_draw(b2, xs = 300, ys = 300)

	  b2_1 = widget_base(b2, col = 2, frame=0, xs = 300)

	    b2_2 = widget_base(b2_1, row = 2, xs = 100)
	      asc_min_lab = widget_label(b2_2, value = 'Scale Min.', font = font)
	      asc_min_txt = widget_text(b2_2, value = string(info.image_scale.imin, f='(i0)'), font=font, /edit, uval = {tag:'image_scale_min'})

	    b2_3 = widget_base(b2_1, row = 2, xs = 100)
	      asc_max_lab = widget_label(b2_3, value = 'Scale Max.', font = font)
	      asc_max_txt = widget_text(b2_3, value = string(info.image_scale.imax, f='(i0)'), font=font, /edit, uval = {tag:'image_scale_max'})

	  b3 = widget_base(b2, col = 2)

	    b4 = widget_base(b3, col = 1, /base_align_center)

	      bs = 130
	      if keyword_set(running) then btn_val = 'Start Script Exec.' else btn_val = 'Stop Script Exec.'
	      start_stop_button = widget_button(b4, value = btn_val, font = font, uval = {tag:'stop_start_button'}, xs=bs)
	      asc_btn = widget_button(b4, value = 'Debug Script', font = font, uval = {tag:'debug_script_button'}, xs=bs)
	      asc_btn = widget_button(b4, value = 'Load Script', font = font, uval = {tag:'load_script_button'}, xs=bs)
	      asc_btn = widget_button(b4, value = 'Reset Script', font = font, uval = {tag:'reset_script_button'}, xs=bs)
		  asc_btn = widget_button(b4, value = 'Start Camera Driver', font = font, uval = {tag:'start_camera_driver'}, xs=bs)
		  asc_btn = widget_button(b4, value = 'Home Filter Wheel', font = font, uval = {tag:'home_filter_wheel'}, xs=bs)


		b5 = widget_base(b3, col = 1, /base_align_center)

		  b5_2 = widget_base(b5, col = 1, /align_right, /base_align_left, /nonexclusive)
		    show_frames = widget_button(b5_2, value = 'Show Frames', font = font, uval = {tag:'show_frames'})   		  
        daily_scripts = widget_button(b5_2, value = 'Run Daily Scripts', font = font, uval = {tag:'run_daily_scripts'})

		  b5_0 = widget_base(b5, col=2, /base_align_left)
		    asc_filt_lab = widget_label(b5_0, value = 'Filter', font=font, xs = 50)
		    asc_filt_list = widget_droplist(b5_0, value = info.comms.filter.lookup[1:*], font=font, uval = {tag:'command_filter'})

		  b5_1 = widget_base(b5, col=2, /base_align_left)
		    asc_shut_lab = widget_label(b5_1, value = 'Shutter', font=font, xs = 50)
		    asc_shut_list = widget_droplist(b5_1, value = ['open','close'], font=font, uval = {tag:'command_shutter'})


	widget_control, asc_base, /realize
	widget_control, get_value = draw1, asc_wind
	widget_control, asc_base, timer = info.timer_tick_interval

	gui = {base:asc_base, $
     	   draw1:draw1, $
     	   script_label:asc_script_label, $
     	   log:asc_list, $
     	   queue:asc_queue, $
     	   info:asc_info, $
     	   start_stop_button:start_stop_button, $
     	   filter_list:asc_filt_list, $
     	   shutter_list:asc_shut_list, $
     	   show_frames_check:show_frames, $
     	   daily_scripts_check:daily_scripts, $
     	   image_scale:{imin:asc_min_txt, imax:asc_max_txt}}

end
