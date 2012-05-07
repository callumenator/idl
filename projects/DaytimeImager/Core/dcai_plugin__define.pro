

;\\ BUILD A UID STRING FOR THIS OBJECT (THIS SHOULD BE OVERRIDDEN)
function DCAI_Plugin::uid, args=args
	return, ''
end


;\\ ATTEMPT TO SET THIS PLUGIN AS THE ACTIVE PLUGIN
;\\ RETURNS 1 IF SUCCESSFUL, 2 IF ALREADY ACTIVE, 0 OTHERWISE
function DCAI_Plugin::set_active, uid	;\\ uid is a string, uniquely identifying a plugin where necessary (e.g. spectra)

	common DCAI_Control, dcai_global

	;\\ IF THE OBJECT FIELD CURRENTLY HOLDS A VALID OBJECT, WE CAN'T SET THIS ONE AS ACTIVE
	;\\ UNLESS IT IS ALREADY ACTIVE
	if obj_valid(dcai_global.info.active_plugin.object) eq 1 then begin
		if dcai_global.info.active_plugin.object eq self and $
		   dcai_global.info.active_plugin.uid eq uid then return, 2 else return, 0
	endif

	dcai_global.info.active_plugin = {object:self, uid:uid}

	return, 1
end

;\\ ATTEMPT TO UNSET THIS PLUGIN AS THE ACTIVE PLUGIN
;\\ RETURNS 1 IF SUCCESSFUL, 0 OTHERWISE
function DCAI_Plugin::unset_active, uid	;\\ uid is a string, uniquely identifying a plugin where necessary (e.g. spectra)

	common DCAI_Control

	if dcai_global.info.active_plugin.object eq self and $
	   dcai_global.info.active_plugin.uid eq uid then begin
		dcai_global.info.active_plugin = {object:obj_new(), uid:''}
		return, 1
	endif else begin
		return, 0
	endelse
end


;\\ LOAD SAVED SETTINGS
pro DCAI_Plugin::load_settings

	common DCAI_Control

	self.xpos = 0
	self.ypos = 0

	save_name = dcai_global.settings.paths.plugin_settings + obj_class(self) + '.DCAI__settings'
	if file_test(save_name) eq 0 then return
	restore, save_name

	tags = strlowcase(tag_names(create_struct(name=obj_class(self))))

	for k = 0, n_elements(self.save_tags) - 1 do begin
		tag = strlowcase(strcompress(self.save_tags[k], /remove_all))
		if tag eq '' then continue
		match = (where(tags eq tag, yn))[0]

		if yn eq 1 then begin
			res = execute('self.' + tag + '=' + tag)
		endif
	endfor

	self.xpos = xpos
	self.ypos = ypos

end


;\\ SAVE SETTINGS ON CLEANUP
pro DCAI_Plugin::cleanup

	common DCAI_Control

	;\\ IF THIS PLUGIN IS ACTIVE, THIS WILL TRY TO UNSET IT
	success = self->unset_active(self->uid())

	save_vars = ''
	n_vars = 0
	tags = strlowcase(tag_names(create_struct(name=obj_class(self))))

	for k = 0, n_elements(self.save_tags) - 1 do begin
		tag = strlowcase(strcompress(self.save_tags[k], /remove_all))
		if tag eq '' then continue
		match = (where(tags eq tag, yn))[0]

		if yn eq 1 then begin
			res = execute(tag + '= self.' + tag)

			if n_vars eq 0 then begin
				save_vars += tag
			endif else begin
				save_vars += ', ' + tag
			endelse
			n_vars ++
		endif
	endfor

	;\\ Grab geometry settings
		if widget_info(self.id, /valid) then begin
			geom = widget_info(self.id, /geometry)
			xpos = geom.xoffset
			ypos = geom.yoffset
		endif else begin
			xpos = 0
			ypos = 0
		endelse
		if n_vars eq 0 then save_vars += 'xpos, ypos' $
			else save_vars += ', xpos, ypos'
		n_vars += 2

	if n_vars ne 0 then begin
		save_name = dcai_global.settings.paths.plugin_settings + obj_class(self) + '.DCAI__settings'
		save_str = 'save, filename = "' + save_name + '", ' + save_vars
		res = execute(save_str)
	endif

	;\\ DESTROY WIDGETS
		widget_control, /destroy, self.id
end


;\\ DEFINE THE PLUGIN SUPERCLASS
pro DCAI_Plugin__define

	struc = {DCAI_Plugin, id:0, $
						  save_tags:strarr(50), $
						  xpos:0, $
						  ypos:0, $
						  auto_mode:0 }
end