@dcai_script_utilities

function DCAI_ScanCalibrate::init

	common DCAI_Control, dcai_global

	;\\ DEFAULTS
		dims = size(*dcai_global.info.image, /dimensions)
		self.color_table = 0
		self.auto_scale = 0
		self.manual_scale_factor = 1
		self.zoom = 1
		self.center = [dims[0], dims[1]] / 2
		self.radius = 20

	;\\ SAVE FIELDS
		self.save_tags = ['color_table', 'auto_scale', 'manual_scale_factor', 'zoom', 'center', 'radius']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings
		self.draw_size = [dims[0], dims[1]]*self.zoom > [10,10]

	;\\ CREATE THE GUI
		_base = widget_base(group=dcai_global.gui.base, col=2, uval={tag:'plugin_base', object:self}, title = 'ScanCalibrate', $
							xoffset = self.xpos, yoffset = self.ypos, mbar=menu, /base_align_center)
		_menu = widget_button(menu, value = 'Zoom', /menu)
		_zoom_reset = widget_button(_menu, value = 'Reset', uval = {tag:'plugin_event', object:self, method:'ZoomReset'})


		left_base = widget_base(_base, col = 1, /base_align_center)

		info_base = widget_base(left_base, row = 2*n_elements(dcai_global.settings.etalon))
		cws = dcai_global.scan.center_wavelength
		for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
			label = widget_label(info_base, value = 'Etalon ' + string(k, f='(i0)'), font=dcai_global.gui.font+'*Bold')
			self.info_ids[k] = widget_list(info_base, font='Courier*5', ysize = 11)
		endfor
		self->UpdateInfo

		edit_base = widget_base(left_base, row = 2)

		widget_edit_field, edit_base, label = 'Manual Scale Factor', font = dcai_global.gui.font, ids = ids, start_val = string(self.manual_scale_factor, f='(i0)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'ScaleFactorEdit'}, edit_xs = 15

		widget_edit_field, edit_base, label = 'Color Table', font = dcai_global.gui.font, ids = ids, start_val = string(self.color_table, f='(i0)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'ColorTableEdit'}, edit_xs = 10

		widget_edit_field, edit_base, label = 'Zoom Factor', font = dcai_global.gui.font, ids = ids, start_val = string(self.zoom, f='(f0.2)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'Zoom'}, edit_xs = 10
		self.edit_ids.zoom = ids.text

		widget_edit_field, edit_base, label = 'Center', font = dcai_global.gui.font, ids = ids, start_val = strjoin(string(self.center, f='(i0)'), ', '), $
							edit_uval = {tag:'plugin_event', object:self, method:'CenterEdit'}, edit_xs = 10
		self.edit_ids.center = ids.text

		widget_edit_field, edit_base, label = 'Radius', font = dcai_global.gui.font, ids = ids, start_val = string(self.radius, f='(i0)'), $
							edit_uval = {tag:'plugin_event', object:self, method:'RadiusEdit'}, edit_xs = 10
		self.edit_ids.radius = ids.text

		auto_scale_base = widget_base(edit_base, /nonexclusive, col=1)
		auto_scale_check = widget_button(auto_scale_base, value = 'Auto Scale?', font=dcai_global.gui.font, $
								uval = {tag:'plugin_event', object:self, method:'AutoScaleCheck'}	)
		if self.auto_scale eq 1 then widget_control, auto_scale_check, /set_button

		btn_base = widget_base(left_base, col=2)
		apply_button = widget_button(btn_base, value = 'Calculate Calibrate Info', font=dcai_global.gui.font + '*Bold', $
									 uval={tag:'plugin_event', object:self, method:'Calibrate'}, xs = 200)
		clear_button = widget_button(btn_base, value = 'Clear Calibration Data', font=dcai_global.gui.font + '*Bold', $
									 uval={tag:'plugin_event', object:self, method:'Clear'}, xs = 200)

		view_base = widget_base(_base, row=5)
		_view = widget_draw(view_base, xs = self.draw_size[0], ys = self.draw_size[1], uname = 'draw', /align_center, $
							/button_events, uval={tag:'plugin_event', object:self, method:'ViewEvent'}, keyboard_events=1)
		self.draw_id = _view
		_info = widget_label(view_base, value = 'Right Click = Position Center', font=dcai_global.gui.font+'*Bold')
		_info = widget_label(view_base, value = 'Left Click = Select Radius', font=dcai_global.gui.font+'*Bold')
		_info = widget_label(view_base, value = 'Arrow Keys = Move Center', font=dcai_global.gui.font+'*Bold')
		_info = widget_label(view_base, value = 'CRTL+Up/Down = Increase/Decrease Radius', font=dcai_global.gui.font+'*Bold')


	;\\ REGISTER FOR FRAME EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /frame

	widget_control, get_value = wind_id, _view
	self.draw_window = wind_id
	self.id = _base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_ScanCalibrate::frame

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

	loadct, 0, /silent
	plots, (self.center[0] + self.radius*cos(!DTOR*findgen(722)/2.))*self.zoom, $
		   (self.center[1] + self.radius*sin(!DTOR*findgen(722)/2.))*self.zoom, $
		   /device, color = 0, thick = 3
	plots, (self.center[[0,0]] + [-self.radius, self.radius])*self.zoom, self.center[[1,1]]*self.zoom, $
		   /device, color = 0, thick = 3
	plots, self.center[[0,0]]*self.zoom, (self.center[[1,1]] + [-self.radius, self.radius])*self.zoom, $
		   /device, color = 0, thick = 3


end


;\\ APPLY/CALCULATE CALIBRATION INFO
pro DCAI_ScanCalibrate::Calibrate, event

	COMMON DCAI_Control, dcai_global

	;\\ ASK FOR THE WAVELENGTH VIEWED
	lambda = 0.0
	xvaredit, lambda, name = 'Enter Viewing Wavelength (nm)', group=self.id
	if lambda eq 0.0 then return


	;\\ IF WAVELENGTH IS ALREADY DEFINED, OVERWRITE, ELSE FIND AN
	;\\ EMPTY SLOT IN THE CENTER WAVELENGTH ARRAY
	cws = dcai_global.scan.center_wavelength
	match = where(cws.view_wavelength_nm eq lambda, n_match)
	if n_match ne 0 then begin
		indices = array_indices(cws, match)
		cws_index = indices[1,0]
	endif else begin
		free = min(where(total(cws.view_wavelength_nm, 1) eq 0, nfree))
		if nfree eq 0 then begin
			res = dialog_message('No Free Wavelength Slots in CenterWavelength!')
			return
		endif
		cws_index = free
	endelse


	;\\ CALCULATE CENTRAL WAVELENGTH FOR EACH ETALON, BASED ON THE PHASEMAP
	;\\ AND ETALON GAP
	for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
		if size(*dcai_global.info.phasemap[k], /type) eq 0 then begin
			res = dialog_message('No Phasemap for etalon ' + string(k, f='(i0)') + $
								 ', unable to calibrate!')
		endif else begin

			etz = dcai_global.settings.etalon[k]
			pmap = *dcai_global.info.phasemap[k]

			;\\ CALCULATE FREE SPECTRAL RANGE (IN NM)
			fsr = (lambda*1E-9*lambda*1E-9) / (2.*etz.refractive_index*etz.gap_mm*1E-3)
			fsr /= 1E-9

			;\\ WRAP THE PHASEMAP
			pmap = (pmap mod 1)

			;\\ CREATE A DISTANCE MAP FROM SELECTED CENTER
			dims = size(pmap, /dimensions)
			dist_circle, dist_map, dims, self.center[0], self.center[1]

			;\\ CALCULATE ORDER AT CENTER AND MEAN ORDER AT SELECTED RADIUS
			center_order = pmap[self.center[0], self.center[1]]
			pts = where(dist_map gt .98*self.radius and dist_map lt 1.02*self.radius, npts)
			radius_order = median(pmap[pts])

			;\\ CONVERT ORDER DIFFERENCE TO WAVELENGTH
			del_lambda = (center_order - radius_order)*fsr

			;\\ CALCULATE CENTRAL WAVELENGTH
			center_lambda = lambda + abs(del_lambda)

			;\\ ADD THE CALIBRATION INFO
			new_entry = {view_wavelength_nm:lambda, $
						 center_wavelength_nm:center_lambda, $
						 home_voltage:etz.leg_voltage[0], $
						 fsr:fsr, $
						 center:self.center}

			dcai_global.scan.center_wavelength[k,cws_index] = new_entry

		endelse
	endfor

	;\\ SAVE THIS LATEST DATA
		DCAI_Control_Persistent, /save

	self->UpdateInfo
end


;\\ CLEAR CALIBRATION INFO
pro DCAI_ScanCalibrate::Clear, event
	COMMON DCAI_Control, dcai_global

	;\\ ASK TO CONFIRM
	confirm = dialog_message('Really Delete Calibration Information?', /question)
	if strlowcase(confirm) eq 'yes' then begin
		new_entry = {view_wavelength_nm:0.0, $
					 center_wavelength_nm:0.0, $
					 home_voltage:'', $
					 fsr:0.0}

		dcai_global.scan.center_wavelength[*,*] = new_entry
		self->UpdateInfo
	endif
end



;\\ UPDATE INFO TABLES
pro DCAI_ScanCalibrate::UpdateInfo
	COMMON DCAI_Control, dcai_global

	cws = dcai_global.scan.center_wavelength
	for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
		header = [string('View Lambda:', f='(a-12)'), $
				  string('Center Lambda:', f='(a-14)'), $
				  string('Home Voltage:', f='(a-12)'), $
				  string('FSR (nm):', f='(a-10)'), $
				  string('Center:', f='(a-9)')]
		list = strjoin(header, '   ')

		for i = 0, n_elements(cws[k,*]) - 1 do begin
			sub_list = [string(cws[k,i].view_wavelength_nm, f='(f12.3)'), $
						string(cws[k,i].center_wavelength_nm, f='(f14.5)'), $
						string(cws[k,i].home_voltage, f='(i12)'), $
						string(cws[k,i].fsr, f='(f10.5)'), $
						strjoin(string(cws[k,i].center, f='(i4)'), ',') ]
			list = [list, strjoin(sub_list, '   ')]
		endfor

		widget_control, set_value=list, self.info_ids[k]
	endfor
end


;\\ VIEWPORT CLICK EVENT
pro DCAI_ScanCalibrate::ViewEvent, event

	;\\ MOUSE BUTTON PRESS
	if event.type eq 0 then begin

		if event.press eq 4 then begin
			;\\ RIGHT CLICK - SELECTING CENTER
			self.center = [event.x, event.y] / self.zoom
		endif

		if event.press eq 1 then begin
			;\\ LEFT CLICK - SELECTING RADIUS
			self.radius = sqrt((event.x/self.zoom - self.center[0])^2. + (event.y/self.zoom - self.center[1])^2.)
		endif

	endif


	;\\ NON-ASCII KEY PRESS
	if event.type eq 6 and event.press eq 1 then begin

		if event.modifiers eq 2 then ctrl = 1 else ctrl = 0

		case event.key of
			5: begin ;\\ LEFT
				self.center += [-1,0]
			end
			6: begin ;\\ RIGHT
				self.center += [1,0]
			end
			7: begin ;\\ UP
				if ctrl eq 0 then begin
					self.center += [0,1]
				endif else begin
					self.radius ++
				endelse
			end
			8: begin ;\\ DOWN
				if ctrl eq 0 then begin
					self.center += [0,-1]
				endif else begin
					self.radius --
					self.radius = self.radius > 0
				endelse
			end
		endcase

	endif

	;\\ UPDATE WIDGET EDIT FIELDS
	widget_control, set_value = strjoin(string(self.center, f='(i0)'), ', '), self.edit_ids.center
	widget_control, set_value = string(self.radius, f='(i0)'), self.edit_ids.radius

end

;\\ CENTER EDIT
pro DCAI_ScanCalibrate::CenterEdit, event
	widget_control, get_value = val, event.id
	split = strtrim(strcompress(strsplit(val, ',', /extract), /remove), 2)
	if n_elements(split) ne 2 then begin
		widget_control, set_value=strjoin(string(self.center, f='(i0)'), ', '), event.id
	endif else begin
		self.center = [fix(split[0], type=3), fix(split[1], type=3)]
	endelse
end

;\\ RADIUS EDIT
pro DCAI_ScanCalibrate::RadiusEdit, event
	widget_control, get_value = val, event.id
	self.radius = fix(val, type=3) > 0
end


;\\ SCALE FACTOR EDIT
pro DCAI_ScanCalibrate::ScaleFactorEdit, event
	widget_control, get_value = new_scale, event.id
	new_scale = float(new_scale)
	if new_scale eq 0 then new_scale = 1
	self.manual_scale_factor = new_scale
end

;\\ AUTO SCALE CHECKBOX
pro DCAI_ScanCalibrate::AutoScaleCheck, event
	self.auto_scale = event.select
end

;\\ COLOR TABLE EDIT
pro DCAI_ScanCalibrate::ColorTableEdit, event
	widget_control, get_value = new_ctable, event.id
	new_ctable = fix(new_ctable)
	if new_ctable gt 39 then new_ctable = 39
	if new_ctable lt 0 then new_ctable = 0
	self.color_table = new_ctable
end

;\\ WINDOW ZOOM
pro DCAI_ScanCalibrate::Zoom, event
	COMMON DCAI_Control, dcai_global
	widget_control, get_value = val, event.id
	self.zoom = fix(val, type=4)
	if self.zoom eq 0 then self.zoom = 1
	dims = size(*dcai_global.info.image, /dimensions)
	self.draw_size = dims*self.zoom
	widget_control, self.draw_id, xsize=self.draw_size[0], ysize=self.draw_size[1]
end

;\\ WINDOW ZOOM RESET
pro DCAI_ScanCalibrate::ZoomReset, event
	COMMON DCAI_Control, dcai_global
	dims = size(*dcai_global.info.image, /dimensions)
	self.draw_size = dims
	self.zoom = 1
	widget_control, set_value = '1.00', self.edit_ids.zoom
	widget_control, self.draw_id, xsize=self.draw_size[0], ysize=self.draw_size[1]
end


;\\ DEFINITION
pro DCAI_ScanCalibrate__define
	COMMON DCAI_Control, dcai_global

	state = {DCAI_ScanCalibrate, draw_window:0, $
						   draw_id:0L, $
						   edit_ids:{scancalibrate_edit_ids, zoom:0L, center:0L, radius:0L}, $
						   info_ids:lonarr(n_elements(dcai_global.settings.etalon)), $
						   zoom:0.0, $
						   draw_size:[0,0], $
						   color_table:0, $
						   auto_scale:0, $
						   manual_scale_factor:0.0, $
						   center:[0,0], $
						   radius:0, $
						   INHERITS DCAI_Plugin}
end
