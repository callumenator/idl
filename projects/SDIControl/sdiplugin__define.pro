
@sdi_include

;\\ LOAD SAVED SETTINGS
pro SDIPlugin::load_settings
	common SDIControl

	self.xpos = 0
	self.ypos = 0

	save_name = sdic_paths.settings + obj_class(self) + '.sdi_settings'
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
pro SDIPlugin::cleanup
	common SDIControl

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
		save_name = sdic_paths.settings + obj_class(self) + '.sdi_settings'
		save_str = 'save, filename = "' + save_name + '", ' + save_vars
		res = execute(save_str)
	endif
end


;\\ DEFINE THE PLUGIN SUPERCLASS
pro SDIPlugin__define
	struc = {SDIPlugin, id:0, $
						save_tags:strarr(50), $
						xpos:0, $
						ypos:0 }
end