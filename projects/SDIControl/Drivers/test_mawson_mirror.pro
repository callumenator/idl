
pro test_mawson_mirror

	port = 7L
	dll = 'c:\mawsoncode\sdi_external\sdi_external.dll'


	comms_wrapper, port, dll, type='moxa', /open, err=err
	print, 'Open: ' + string(err, f='(i0)')

	comms_wrapper, port, dll, type='moxa', moxa_setbaud=12, err=err
	print, 'SetBaud: ' + string(err, f='(i0)')

	comms_wrapper, port, dll, type='moxa', /write, data='pos'+string(13b), err=err
	print, 'Write: ' + string(err, f='(i0)')

	comms_wrapper, port, dll, type='moxa', /read, data=data, err=err
	print, 'Read: ' + string(err, f='(i0)')
	print, 'Output of read pos command: ' + data

	print, 'Test 1:'
	if total(byte(data) - 32) eq 0 then begin
		print, 'Failed to Receive Reply from Motor'
	endif else begin
		print, 'Received a reply from the motor! Yay!'
	endelse


	comms_wrapper, port, dll, type='moxa', /write, data='gst'+string(13b), err=err
	print, 'Write: ' + string(err, f='(i0)')

	comms_wrapper, port, dll, type='moxa', /read, data=data, err=err
	print, 'Read: ' + string(err, f='(i0)')
	print, 'Output of read gst command: ' + data

	print, 'Test 2:'
	if total(byte(data) - 32) eq 0 then begin
		print, 'Failed to Receive Reply from Motor'
	endif else begin
		print, 'Received a reply from the motor! Yay!'
	endelse


	comms_wrapper, port, dll, type='moxa', /close, err=err
	print, 'Close: ' + string(err, f='(i0)')

end