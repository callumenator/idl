
function sdi_Spectrum::init

	common SDIControl

	self.save_tags = ['']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings

	base = widget_base(group=sdic_widget.root, col=1, uval={descr:'plugin_base', object:self}, title = 'Spectrum')
	view = widget_draw(base, xs = 500, ys = 500)
	btn = widget_button(base, value = 'Press Me', uval={descr:'plugin_event', object:self, method:'BtnEvent'})

	SDIControl_RegisterPlugin, base, self, /frame

	;self.id = base
	return, 1
end

pro sdi_Spectrum::frame

end

pro sdi_Spectrum__define
	state = {SDI_Spectrum, INHERITS SDIPlugin}
end


