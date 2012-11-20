
;\\ CLEANUP ROUTINE FOR THE DCAI GUI
;\\ Use the object keyword to specify a plugin object to destroy
pro DCAI_Control_Cleanup, id, object=object

	COMMON DCAI_Control, dcai_global

	if not keyword_set(object) then begin
		widget_control, get_uval = uval, id
	endif else begin
		uval = {tag:'plugin_base', object:object}
	endelse


	if size(uval, /type) eq 8 then begin

		case uval.tag of

			;\\ A PLUGIN HAS BEEN CLOSED. REMOVE IT FROM THE TIMER/FRAME LIST(S), AND DESTROY IT
			'plugin_base': begin
				;\\ IF THE MAIN CONSOLE HAS BEEN CLOSED, THERE IS NO NEED TO CLEAR THE FRAME/TIMER LISTS
				if dcai_global.info.gui_closed eq 0 then begin
					if size(*dcai_global.info.timer_list, /n_dimensions) ne 0 then begin
						tidxs = where(*dcai_global.info.timer_list eq uval.object, ntimer)
						if ntimer gt 0 then *dcai_global.info.timer_list = delete_elements(*dcai_global.info.timer_list, tidxs)
					endif
					if size(*dcai_global.info.frame_list, /n_dimensions) ne 0 then begin
						fidxs = where(*dcai_global.info.frame_list eq uval.object, nframe)
						if nframe gt 0 then *dcai_global.info.frame_list = delete_elements(*dcai_global.info.frame_list, fidxs)
					endif
				endif

				;\\ CHECK TO SEE IF THIS OBJECT STARTED AN ACTIVE SCAN, IF SO, STOP THE SCAN
					for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
						if dcai_global.scan.scanning[k] ne 0 and dcai_global.scan.scanner[k] eq uval.object then begin
							success = DCAI_ScanControl('stop', 'dummy', {caller:'control', etalon:k})
						endif
					endfor


				;\\ DESTROY THE OBJECT, CAUSING IT TO SAVE ITS SETTINGS
					obj_destroy, uval.object

				;\\ REMOVE IT FROM THE LIST OF PLUGINS
					if ptr_valid(dcai_global.info.plugins) then begin
						if size(*dcai_global.info.plugins, /n_dimensions) ne 0 then begin
							pidxs = where(*dcai_global.info.plugins eq uval.object, nplugs)
							if nplugs gt 0 then begin
								new_list = delete_elements(*dcai_global.info.plugins, pidxs)
								if size(new_list, /type) eq 2 then begin
									ptr_free, dcai_global.info.plugins
									dcai_global.info.plugins = ptr_new(/alloc)
								endif else begin
									*dcai_global.info.plugins = new_list
								endelse
							endif
						endif
					endif
			end

			else:

		endcase

	endif else begin


		;\\ THE MAIN GUI CONSOLE HAS BEEN CLOSED
			dcai_global.info.gui_closed = 1
			dcai_global.info.run = 0

		;\\ PERFORM HARDWARE SHUTDOWN
			DCAI_Hardware, /deinit

		;\\ CLOSE THE LOG FILE
			close, dcai_global.log.file_handle
			free_lun, dcai_global.log.file_handle
			dcai_global.log.log_filename = ''
			dcai_global.log.file_handle = 0

		;\\ CLEAN UP THE HEAP VARIABLES
			ptr_free, dcai_global.info.camera_caps
			ptr_free, dcai_global.info.image
			ptr_free, dcai_global.info.raw_image
			ptr_free, dcai_global.info.phasemap
			ptr_free, dcai_global.info.current_queue
			ptr_free, dcai_global.info.plugins
			ptr_free, dcai_global.info.timer_list
			ptr_free, dcai_global.info.frame_list

		;\\ IF PROFILING, PRINT OUT THE REPORT
			;PROFILER, /REPORT, data = perf
			print, ptr_valid()

	endelse

end