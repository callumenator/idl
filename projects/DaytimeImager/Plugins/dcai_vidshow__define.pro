@dcai_script_utilities

function DCAI_Vidshow::init

	common DCAI_Control, dcai_global

	;\\ DEFAULTS
		dims = size(*dcai_global.info.image, /dimensions)
		self.color_table = 0
		self.auto_scale = 0
		self.manual_scale_factor = 1
		self.zoom = 1
		self.capture_type = 'PNG'
		self.capture_path = dcai_global.settings.paths.screen_capture
		capture_formats = ['PNG', 'JPG']
		self.cross_hairs_on = 0
		self.cross_hairs_isect = dims/2

	;\\ SAVE FIELDS
		self.save_tags = ['color_table', 'auto_scale', 'manual_scale_factor', 'capture_type', $
						  'capture_path', 'zoom', 'cross_hairs_on', 'cross_hairs_isect']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings
		self.draw_size = [dims[0], dims[1]]*self.zoom > [10,10]

	;\\ CREATE THE GUI
		_base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'VidShow', $
							xoffset = self.xpos, yoffset = self.ypos, mbar=menu, /base_align_center)
		_menu = widget_button(menu, value = 'Zoom', /menu)
		_zoom_reset = widget_button(_menu, value = 'Reset', uval = {tag:'plugin_event', object:self, method:'ZoomReset'})
		_view = widget_draw(_base, xs = self.draw_size[0], ys = self.draw_size[1], uname = 'draw', /align_center, $
							/button_events, uval={tag:'plugin_event', object:self, method:'ViewClick'})
		self.draw_id = _view
		_info = widget_label(_base, value = 'Frame Rate:', font=dcai_global.gui.font+'*Bold', xs=300, /align_center)

		edit_base = widget_base(_base, col = 4)

		widget_edit_field, edit_base, label = 'Manual Scale Factor', font = dcai_global.gui.font, ids = ids, start_val = string(self.manual_scale_factor, f='(i0)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'ScaleFactorEdit'}, edit_xs = 15

		widget_edit_field, edit_base, label = 'Color Table', font = dcai_global.gui.font, ids = ids, start_val = string(self.color_table, f='(i0)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'ColorTableEdit'}, edit_xs = 10

		widget_edit_field, edit_base, label = 'Zoom Factor', font = dcai_global.gui.font, ids = ids, start_val = string(self.zoom, f='(f0.2)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'Zoom'}, edit_xs = 10
		self.zoom_id = ids.text

		widget_edit_field, edit_base, label = 'X-Hair Center', font = dcai_global.gui.font, ids = ids, $
							start_val = strjoin(string(self.cross_hairs_isect, f='(i0)'), ', '), $
							edit_uval = {tag:'plugin_event', object:self, method:'CrossHairsISect'}, edit_xs = 10
		self.isect_id = ids.text

		auto_scale_base = widget_base(edit_base, /nonexclusive, row=2)
		auto_scale_check = widget_button(auto_scale_base, value = 'Auto Scale?', font=dcai_global.gui.font, $
								uval = {tag:'plugin_event', object:self, method:'AutoScaleCheck'}	)
		if self.auto_scale eq 1 then widget_control, auto_scale_check, /set_button

		cross_hairs_check = widget_button(auto_scale_base, value = 'Cross Hairs?', font=dcai_global.gui.font, $
								uval = {tag:'plugin_event', object:self, method:'CrossHairsCheck'}	)
		if self.cross_hairs_on eq 1 then widget_control, cross_hairs_check, /set_button

		cap_base = widget_base(_base, col = 1, frame=1)

			cap_base_0 = widget_base(cap_base, col=1)
				label = widget_label(cap_base_0, value = 'Capture Status: Not Capturing Frames', font=dcai_global.gui.font+'*Bold')
				self.capture_status_id = label

				type_base = widget_base(cap_base_0, col=2)
					pt = where(self.capture_type eq capture_formats, npt)
					if npt eq 0 then stop

					label = widget_label(type_base, value='Image Capture Format:', font=dcai_global.gui.font)
					type = widget_droplist(type_base, value=capture_formats, uval={tag:'plugin_event', object:self, method:'CaptureType', $
											types:capture_formats}, font=dcai_global.gui.font)
					widget_control, set_droplist_select=pt[0], type

				widget_edit_field, cap_base_0, label = 'Image Capture Path', font = dcai_global.gui.font, ids = ids, start_val=self.capture_path, $
							edit_uval = {tag:'plugin_event', object:self, method:'CapturePath'}, edit_xs = 40, /column

			cap_base_1 = widget_base(cap_base, col=3)
				scr_capture = widget_button(cap_base_1, value = 'Capture Frame', font=dcai_global.gui.font, /align_center, $
											uval = {tag:'plugin_event', object:self, method:'Capture'})
				seq_cap_start = widget_button(cap_base_1, value = 'Start Sequence Capture', font=dcai_global.gui.font, /align_center, $
											uval = {tag:'plugin_event', object:self, method:'CaptureSequence', action:'start'})
				seq_cap_stop = widget_button(cap_base_1, value = 'Stop Sequence Capture', font=dcai_global.gui.font, /align_center, $
											uval = {tag:'plugin_event', object:self, method:'CaptureSequence', action:'stop'})



	;\\ REGISTER FOR FRAME EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /frame

	widget_control, get_value = wind_id, _view
	self.draw_window = wind_id
	self.info_text = _info
	self.id = _base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_Vidshow::frame

	COMMON DCAI_Control, dcai_global

	dims = size(*dcai_global.info.image, /dimensions)
	id = widget_info(self.id, find_by_uname = 'draw')

	loadct, self.color_table, /silent
	wset, self.draw_window

	image = *dcai_global.info.image
	image -= min(smooth(image, 20, /edge))
	image = image > 0
	image = congrid(image, self.draw_size[0], self.draw_size[1])

	if self.manual_scale_factor eq 0 then self.manual_scale_factor = max(image)
	if self.auto_scale eq 1 then tv, bytscl(image) $
		else tv, image*self.manual_scale_factor

	;\\ CROSS HAIRS
		if self.cross_hairs_on eq 1 then begin
			loadct, 0, /silent
			plots, [0, dims[0]]*self.zoom, self.cross_hairs_isect[[1,1]]*self.zoom, line=1, color = 255, /device
			plots, self.cross_hairs_isect[[0,0]]*self.zoom, [0, dims[1]]*self.zoom, line=1, color = 255, /device
		endif


	;\\ UPDATE THE FRAME RATE
		widget_control, set_value = 'Frame Rate: ' + string(dcai_global.info.frame_rate, f='(f0.2)') $
							+ ' Hz', self.info_text

	;\\ IF CAPTURING IMAGE SEQUENCE, CAPTURE THE CURRENT FRAME
		if self.capture_sequence eq 1 then self->Capture, 0

end


;\\ VIEWPORT CLICK EVENT
pro DCAI_Vidshow::ViewClick, event
	if event.press eq 1 and self.cross_hairs_on eq 1 then begin
		self.cross_hairs_isect = [event.x, event.y]/self.zoom
		widget_control, set_value=strjoin(string(self.cross_hairs_isect, f='(i0)'), ', '), self.isect_id
	endif
end

;\\ SCALE FACTOR EDIT
pro DCAI_Vidshow::ScaleFactorEdit, event
	widget_control, get_value = new_scale, event.id
	new_scale = float(new_scale)
	if new_scale eq 0 then new_scale = 1
	self.manual_scale_factor = new_scale
end

;\\ AUTO SCALE CHECKBOX
pro DCAI_Vidshow::AutoScaleCheck, event
	self.auto_scale = event.select
end

;\\ CROSS HAIRS CHECKBOX
pro DCAI_Vidshow::CrossHairsCheck, event
	self.cross_hairs_on = event.select
end

;\\ CROSS HAIRS INTERSECT POINT
pro DCAI_Vidshow::CrossHairsISect, event
	widget_control, get_value = val, event.id
	split = strtrim(strcompress(strsplit(val, ',', /extract), /remove), 2)
	if n_elements(split) ne 2 then begin
		widget_control, set_value=strjoin(string(self.cross_hairs_isect, f='(i0)'), ', '), event.id
	endif else begin
		self.cross_hairs_isect = [fix(split[0], type=3), fix(split[1], type=3)]
	endelse
end

;\\ COLOR TABLE EDIT
pro DCAI_Vidshow::ColorTableEdit, event
	widget_control, get_value = new_ctable, event.id
	new_ctable = fix(new_ctable)
	if new_ctable gt 39 then new_ctable = 39
	if new_ctable lt 0 then new_ctable = 0
	self.color_table = new_ctable
end

;\\ WINDOW ZOOM
pro DCAI_Vidshow::Zoom, event
	COMMON DCAI_Control, dcai_global
	widget_control, get_value = val, event.id
	self.zoom = fix(val, type=4)
	if self.zoom eq 0 then self.zoom = 1
	dims = size(*dcai_global.info.image, /dimensions)
	self.draw_size = dims*self.zoom
	widget_control, self.draw_id, xsize=self.draw_size[0], ysize=self.draw_size[1]
end

;\\ WINDOW ZOOM RESET
pro DCAI_Vidshow::ZoomReset, event
	COMMON DCAI_Control, dcai_global
	dims = size(*dcai_global.info.image, /dimensions)
	self.draw_size = dims
	self.zoom = 1
	widget_control, set_value = '1.00', self.zoom_id
	widget_control, self.draw_id, xsize=self.draw_size[0], ysize=self.draw_size[1]
end

;\\ CAPTURE FRAME
pro DCAI_Vidshow::Capture, event

	COMMON DCAI_Control, dcai_global

	;\\ CHECK FOR VALID CAPTURE PATH
		test = file_test(self.capture_path, /directory)
		if test eq 0 then begin
			;\\ THROW UP AN INFO DIALOG
			message = dialog_message('Invalid Capture Path!')
			;\\ TURN OFF SEQUENCE CAPTURE, SINCE THE PATH IS INVALID
			self.capture_sequence = 0
			return
		endif

	tstamp = strjoin(HourUtHHMMSS_SSS_Array(), '')
	wset, self.draw_window
	image = tvrd(/true)
	filename = self.capture_path + '\Vidshow_ScreenCap_' + $
				DateStringUT_YYYYMMDD_Nosep() + '_' + tstamp

	case self.capture_type of
		'PNG': write_png, filename + '.png', image
		'JPG': write_jpeg, filename + '.jpg', image, quality=100, /true
		else:
	endcase
end


;\\ SET CAPTURE TYPE
pro DCAI_Vidshow::CaptureType, event
	widget_control, get_uval = uval, event.id
	self.capture_type = uval.types[event.index]
end

;\\ SET CAPTURE PATH
pro DCAI_Vidshow::CapturePath, event
	widget_control, get_val=val, event.id
	self.capture_path = val
end

;\\ CAPTURE SEQUENCE (RECORD EACH FRAME)
pro DCAI_Vidshow::CaptureSequence, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	case uval.action of
		'start': begin
			;\\ THROW UP A CONFIRMATION BOX JUST TO MAKE SURE
				confirm = strlowcase(dialog_message(/question, 'Really Start Capturing Frames?'))
				if confirm eq 'yes' then begin
					self.capture_sequence = 1
					widget_control, set_value = 'Capture Status: Capturing Frames!', self.capture_status_id
				endif
		end
		'stop': begin
			self.capture_sequence = 0
			widget_control, set_value = 'Capture Status: Not Capturing Frames', self.capture_status_id
		end
		else:
	endcase
end

;\\ DEFINITION
pro DCAI_Vidshow__define
	state = {DCAI_Vidshow, draw_window:0, $
						   draw_id:0L, $
						   zoom_id:0L, $
						   isect_id:0L, $
						   capture_status_id:0L, $
						   capture_sequence:0, $
						   capture_type:'', $
						   capture_path:'', $
						   zoom:0.0, $
						   draw_size:[0,0], $
						   info_text:0L, $
						   color_table:0, $
						   auto_scale:0, $
						   manual_scale_factor:0.0, $
						   cross_hairs_on:0, $
						   cross_hairs_isect:[0,0], $
						   INHERITS DCAI_Plugin}
end
