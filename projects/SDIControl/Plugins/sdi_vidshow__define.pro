
@sdi_include

function sdi_Vidshow::init

	common SDIControl

	;\\ DEFAULTS
		self.color_table = 0
		self.auto_scale = 0
		self.manual_scale_factor = 1

	;\\ SAVE FIELDS
		self.save_tags = ['color_table', 'auto_scale', 'manual_scale_factor']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings

	base = widget_base(group=sdic_widget.root, col=1, uval={descr:'plugin_base', object:self}, title = 'VidShow', $
						xoffset = self.xpos, yoffset = self.ypos)
	view = widget_draw(base, xs = 50, ys = 50, uname = 'draw', /align_center)
	info = widget_text(base, value = 'Frame Rate:', font=sdic_widget.font)

	edit_base = widget_base(base, col = 3)

		widget_edit_field, edit_base, label = 'Manual Scale Factor', font = sdic_widget.font, ids = ids, start_val = string(self.manual_scale_factor, f='(i0)'), $
							edit_uval = {descr:'plugin_event', object:self, method:'ScaleFactorEdit'}

		auto_scale_base = widget_base(edit_base, /nonexclusive)
		auto_scale_check = widget_button(auto_scale_base, value = 'Auto Scale?', font=sdic_widget.font, $
								uval = {descr:'plugin_event', object:self, method:'AutoScaleCheck'}	)
		if self.auto_scale eq 1 then widget_control, auto_scale_check, /set_button

		widget_edit_field, edit_base, label = 'Color Table', font = sdic_widget.font, ids = ids, start_val = string(self.color_table, f='(i0)'), $
							edit_uval = {descr:'plugin_event', object:self, method:'ColorTableEdit'}


	;\\\ REGISTER FOR FRAMES
		SDIControl_RegisterPlugin, base, self, /frame

	widget_control, get_value = wind_id, view
	self.draw_window = wind_id
	self.info_text = info
	self.id = base
	return, 1
end


;\\ FRAME EVENT
pro sdi_Vidshow::frame
	common SDIControl

	dims = size(*sdic_frame_buffer.image, /dimensions)
	id = widget_info(self.id, find_by_uname = 'draw')
	widget_control, xsize = dims[0], ysize = dims[1], id

	;\\ Frame rate
		thisRate = 1.0 / (systime(/sec) - self.last_frame_time)
		self.last_frame_time = systime(/sec)

	loadct, self.color_table, /silent
	wset, self.draw_window

	if self.manual_scale_factor eq 0 then self.manual_scale_factor = max(*sdic_frame_buffer.image)
	if self.auto_scale eq 1 then tv, bytscl(*sdic_frame_buffer.image) $
		else tv, *sdic_frame_buffer.image*self.manual_scale_factor


	;\\ Update the frame rate
	widget_control, set_value = 'Frame Rate: ' + string(thisRate, f='(f0.2)') + ' Hz', self.info_text
end


;\\ SCALE FACTOR EDIT
pro sdi_Vidshow::ScaleFactorEdit, event
	widget_control, get_value = new_scale, event.id
	new_scale = float(new_scale)
	if new_scale eq 0 then new_scale = 1
	self.manual_scale_factor = new_scale
end

;\\ AUTO SCALE CHECKBOX
pro sdi_Vidshow::AutoScaleCheck, event
	self.auto_scale = event.select
end

;\\ COLOR TABLE EDIT
pro sdi_Vidshow::ColorTableEdit, event
	widget_control, get_value = new_ctable, event.id
	new_ctable = fix(new_ctable)
	if new_ctable gt 39 then new_ctable = 39
	if new_ctable lt 0 then new_ctable = 0
	self.color_table = new_ctable
end

;\\ DEFINITION
pro sdi_Vidshow__define
	state = {SDI_Vidshow, draw_window:0, $
						  info_text:0L, $
						  color_table:0, $
						  auto_scale:0, $
						  manual_scale_factor:0.0, $
						  last_frame_time:0D, $
						  INHERITS SDIPlugin}
end
