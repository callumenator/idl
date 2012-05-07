
;\\ Turn a 12-bit unsigned (0-4095) integer into a 3-character HEX string
function sdi_cs100_etalon_driver_make_hex, i

	;\\ 12-bit integer number, force into range without wrapping
	if i lt 0 then i = 0
	if i gt 4095 then i = 4095

	hex_string = string(i, f='(z03)')
	return, hex_string
end

;\\ Offset code a 12-bit signed iteger
function sdi_cs100_etalon_driver_offset, i

	;\\ Force into range
	if i lt -2048 then i = -2048
	if i gt 2047 then i = 2047

	return, i + 2048
end


;\\ Driver for the CS100 Queensgate/ICOS etalon
pro sdi_cs100_etalon_driver, command, in, out, err

	command = strlowcase(command)
	err = 'none'
	out = 0

	case command of

		'initialise':begin
			;\\ Set auto response on
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = '++auto 1' + string(13B)
			;\\ The etalon controller's address is 8
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = '++addr 8' + string(13B)
			;\\ Enable EOI assertion - not sure if this is required, probably not
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = '++eoi 1' + string(13B)
			;\\ Define the read ports Q-T
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = '*QT' + string(13B)
			;\\ Open X, Y, Z ports, set to zero, latch, close buffers
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'I7000P1P0I0' + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /read, data=data, err=err
			out = data
			err = err
		end

		'set_spacing': begin
			;\\ in = {port:0L, dll:'', comms:'moxa'/'com', spacing: integer [-2048,2047]}
			offset_code = sdi_cs100_etalon_driver_offset(fix(in.spacing))
			hex_string = sdi_cs100_etalon_driver_make_hex(offset_code)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'I4' + hex_string + 'P1P0' + string(13B)
		end

		'set_x_parallelism': begin
			;\\ in = {port:0L, dll:'', comms:'moxa'/'com', spacing: integer [-2048,2047]}
			offset_code = sdi_cs100_etalon_driver_offset(fix(in.spacing))
			hex_string = sdi_cs100_etalon_driver_make_hex(offset_code)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'I1' + hex_string + 'P1P0' + string(13B)
		end

		'set_y_parallelism': begin
			;\\ in = {port:0L, dll:'', comms:'moxa'/'com', spacing: integer [-2048,2047]}
			offset_code = sdi_cs100_etalon_driver_offset(fix(in.spacing))
			hex_string = sdi_cs100_etalon_driver_make_hex(offset_code)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'I2' + hex_string + 'P1P0' + string(13B)
		end

		'read': begin	;\\ This is not required, since the GPIB automatically reads responses (++auto = 1)
			;\\ in = {port:0L, dll:'', comms:'moxa'/'com'}
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = '++read' + string(13B)
		end

		'set_operate_mode':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'O0' + string(13B)
		end

		'set_balance_mode':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, $
				data = 'O1' + string(13B)
		end

		else: begin
			err = 'Unknown Command'
			return
		end
	endcase
end