
;\\ Create the SDI Console/Interface

pro SDIControl_CreateInterface, title=title, font=font

	common SDIControl

	if not keyword_set(font) then font = 'Ariel*16*Bold'
	if not keyword_set(title) then title = 'SDI Control'

	root_base = widget_base(col = 1, title=title, mbar=menu, uval={descr:'root_base'})

	plugin_menu = widget_button(menu, value='Plugins')
	for j = 0, n_elements(sdic_plugins.name) - 1 do $
		plugin_add = widget_button(plugin_menu, value=sdic_plugins.name[j], $
			uval={descr:'plugin', plugin:sdic_plugins.name[j]})

	tab_base = widget_tab(root_base, font=font)

	tab_1_log = widget_base(tab_base, title = 'Log')
	tab_1_log_list = widget_list(tab_1_log, xsize=70, ysize = 20, font=font)	;\\ Logging window

	tab_2_cam = widget_base(tab_base, title = 'Camera', col=1)
	tab_3_eta = widget_base(tab_base, title = 'Etalon', col=1)
	tab_4_mot = widget_base(tab_base, title = 'Motor', col=1)

	widget_control, /realize, root_base
	widget_control, root_base, timer = sdic_misc.timer_interval

	sdic_widget = {root:root_base, $
				  tab_base:tab_base, $
				  cam_tab:tab_2_cam, $
				  eta_tab:tab_3_eta, $
				  mot_tab:tab_4_mot, $
				  font:font}
end