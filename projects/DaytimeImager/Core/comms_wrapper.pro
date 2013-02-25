;\\ Code formatted by DocGen


;\D\<No Doc>
pro comms_wrapper, port, $        ;\A\<No Doc>
                   dll_name, $    ;\A\<No Doc>
                   type=type, $   ;\A\<No Doc>
                                  ;\A\<No Doc>
				   open=open, $		;\\ These are all switches, indicating required operation. No values.
				   close=close, $
				   read=read, $
				   write=write, $	;\\ Also equaivalent to dio_write8, if using DIO.
				   flush_input=flush_input, $	;\\ Implemented for moxa only
				   flush_output=flush_output, $	;\\ Implemented for moxa only

				   moxa_setbaud=moxa_setbaud, $	;\\ Moxa-specific: baud index, 0-19. 12 = 9600 baud

				   dio_write8=dio_write8, $		;\\ DIO-specific keywords
				   dio_writeall=dio_writeall, $
				   dio_config=dio_config, $

				   delay=delay, $	;\\ For standard COM writes, delay in milliseconds, defaults to 1

				   data=data, $		;\\ if /read, this is will hold the read string, else
						  			;\\ should contain the string to write.
						  			;\\ If opening a standard com port, this can be the init string, ie:
						  			;\\ "COM1: baud=9600 data=8 parity=N stop=1", but there is a default for this.

				   errcode=errcode	;\\ Returned error code

	port = long(port)

	if not keyword_set(type) then type = 'com' $
		else type = strlowcase(type)


	;\\ COMMS USING MOXA API
	if type eq 'moxa' then begin

		if keyword_set(read) then begin
			;\\ Check data size waiting in com port buffer
				inlen = call_external(dll_name, 'uMoxaCheckPort', port)

			;\\ Create a buffer to hold data
				str = ''
				for n = 0, inlen - 1 do str = str + ' '
				;for n = 0, 50 do str = str + ' '
				inlen = strlen(str)

			;\\ Grab the com port data
				errcode = call_external(dll_name, 'uMoxaReadAllPort', port, inlen, str)

				data = str
				return
		endif

		if keyword_set(write) then begin
			if size(data, /type) ne 7 then begin
				print, 'No Data string provided (set DATA keyword = "command string")'
				return
			endif
			errcode = call_external(dll_name, 'uMoxaWriteAllPort', port, data)
			return
		endif

		if keyword_set(open) then begin
			errcode = call_external(dll_name, 'uMoxaOpenPort', port)
			;\\ This lets /moxa_setbaud to be used when opening the port
			if keyword_set(moxa_setbaud) then begin
				wait, 0.5	;\\ Need to wait so the port is open before setting IOCTL...
				dummy = call_external(dll_name, 'uMoxaSetIOCTL', port, moxa_setbaud)
			endif

			return
		endif

		if keyword_set(moxa_setbaud) then begin
			;\\ Remember moxa_setbaud should be an index from 0-19: 12 = 9600, 13 = 19200
			errcode = call_external(dll_name, 'uMoxaSetIOCTL', port, moxa_setbaud)
			return
		endif

		if keyword_set(close) then begin
			errcode = call_external(dll_name, 'uMoxaClosePort', port)
			return
		endif

		if keyword_set(flush_input) then begin
			func = 0L
			errcode = call_external(dll_name, 'uMoxaFlush', port, func)
			return
		endif

		if keyword_set(flush_output) then begin
			func = 1L
			errcode = call_external(dll_name, 'uMoxaFlush', port, func)
			return
		endif


	endif


	;\\ STANDARD SERIAL COMMS USING WINDOWS API
	if type eq 'com' then begin

		if keyword_set(read) then begin
			BA = 0UL
			errcode = call_external(dll_name, 'uCheckPort', port, BA, /UL_Value)
			instr = ''
			for x = 0, BA - 1 do instr = instr + ' '

			errcode = call_external(dll_name, 'uReadPort', port, BA, instr, 0, /UL_Value)
			data = instr
			return
		endif

		if keyword_set(write) then begin
			if not keyword_set(delay) then delay = 1 else delay = fix(delay)
			if size(data, /type) ne 7 then begin
				print, 'No Data string provided (set DATA keyword = "command string")'
				return
			endif
			errcode = call_external(dll_name, 'uWritePort', port, data, delay, /UL_Value)
			return
		endif

		if keyword_set(open) then begin
			if size(data, /type) ne 7 then begin
				print, 'No Init string provided, using default...'
				data = "COM" + string(port, f='(i01)') + ": baud=9600 data=8 parity=N stop=1"
				print, data
			endif
			errcode = call_external(dll_name, 'uOpenPort', port, data, /UL_Value)
			return
		endif

		if keyword_set(close) then begin
			errcode = call_external(dll_name, 'uClosePort', port, /UL_Value)
			return
		endif

	endif


	;\\ AIOUSB COMMS
	if type eq 'dio' then begin

		if keyword_set(dio_config) then begin
			if size(data, /type) eq 0 then begin
				print, 'No Data string provided (set DATA keyword = "command string")'
				return
			endif
			if n_elements(data) ne 4 then begin
				print, 'Data must be a four-element vector...'
				return
			endif
			errcode = call_external(dll_name, 'uDIO_Config', $
							byte(data[0]), $
							byte(data[1]), $
							byte(data[2]), $
							byte(data[3]), /all_value)
			return
		endif

		;\\ Use either DIO-specific or generic keyword for this type of write...
		if keyword_set(dio_write8) or keyword_set(write) then begin
			if size(data, /type) eq 0 then begin
				print, 'No Data string provided (set DATA keyword = "command string")'
				return
			endif
			errcode = call_external(dll_name, 'uDIO_Write8', ulong(port), byte(data))
			return
		endif

		if keyword_set(dio_writeall) then begin
			if size(data, /type) eq 0 then begin
				print, 'No Data string provided (set DATA keyword = "command string")'
				return
			endif
			if n_elements(data) ne 4 then begin
				print, 'Data must be a four-element vector...'
				return
			endif
			errcode = call_external(dll_name, 'uDIO_WriteAll', $
							byte(data[0]), $
							byte(data[1]), $
							byte(data[2]), $
							byte(data[3]), /all_value)
			return
		endif

	endif

end
