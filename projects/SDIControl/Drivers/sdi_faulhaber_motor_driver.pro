
pro sdi_Faulhaber_Motor_Driver, command, in, out, err

	command = strlowcase(command)
	err = 'empy'
	out = 0

	;\\ In = {port:0L, dll:'', comms:'moxa'/'com', ....}

	case command of

		'enable':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'EN'+string(13B), err=err
		end

		'disable':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'DI'+string(13B), err=err
		end

		'get_status':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'GST'+string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /read, data = status, err=err
			out = status
		end

		'set_pos_0':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'HO'+string(13B), err=err
		end

		'verbatim':begin
			;\\ in = {.... verbatim:''}
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = in.verbatim, err=err
		end

		'read_pos':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'POS'+string(13B), err=err
			comms_wrapper, in.port, in.dll, type=in.comms, /read, data = pos, err=err
			out = pos
		end

		'set_max_speed':begin
			;\\ In = {.... speed:0}
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = string(in.speed, f='(i0)') + string(13B), err=err
		end

		'set_max_accel':begin
			;\\ In = {.... accel:0}
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = string(in.accel, f='(i0)') + string(13B), err=err
		end

		'gohix':begin
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = 'GOHIX'+string(13B), err=err
		end

		'drive_to':begin
			;\\ In = {.... pos:0}
			data_str = 'LPC1200' + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

			data_str = 'NP' + string(in.pos, f='(i0)') + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

			data_str = 'LA' + string(in.pos, f='(i0)') + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

			data_str = 'M' + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

			pos_reached = 0
			count = 0
			while pos_reached eq 0 do begin

					count = count + 1

				;\\ Wait for position reached notification
					data_str = 'POS' + string(13B)
					pos = -9e9
					while pos lt -8e9 do begin
					    wait, 0.01
	 					comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err
	 					wait, 0.1
	 					comms_wrapper, in.port, in.dll, type=in.comms, /read, data = data_out, err=err
						pos = long(data_out)
					endwhile

					sdi_Faulhaber_Motor_Driver, 'get_status', {port:in.port, dll:in.dll, comms:in.comms}, status, err
					status = byte(status)

					;if status(4) eq 48 then pos_reached = 0 else pos_reached = 1
					if abs(pos - drive_to) lt 1000 then pos_reached = 1 else pos_reached = 0
					if count eq 30 then pos_reached = 1

					wait, 0.1
			endwhile
			goto, END_DRIVE_MOTOR
		end

		'direction':begin
			;\\ In = {.... direction:'forwards'/'backwards'}

			data_str = 'LPC1200' + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err
			data_str = 'LCC1200' + string(13B)
			comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err
			stopped = 0

			while stopped eq 0 do begin

				max_speed = 1200
				data_str = 'SP' + string(max_speed, f='(i0)') + string(13B)
				comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

				spin_time = 46.372 * (max_speed)^(-0.8847)

				;\\ Try to turn backwards/forwards by one revolution

					if in.direction eq 'backwards' then begin
						data_str = 'LR-' + string(increments, f='(i0)') + string(13B)
					endif else begin
						data_str = 'LR' + string(increments, f='(i0)') + string(13B)
					endelse
					comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

				;\\ Initiate the motion
					data_str = 'M' + string(13B)
					comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err

					time = systime(/sec)

				repeat begin
					dtime = float(systime(/sec) - time)

					if dtime gt (spin_time*1.1) then begin
						data_str = 'V0' + string(13B)
						comms_wrapper, in.port, in.dll, type=in.comms, /write, data = data_str, err=err
						stopped = 1
						break
					endif

					sdi_Faulhaber_Motor_Driver, 'get_status', {port:in.port, dll:in.dll, comms:in.comms}, status, err
					status = byte(status)

					wait, 0.1
				endrep until status(4) eq 49
				wait, 0.02
			endwhile

		end

		else:err = 'unknown command'
	endcase
END_DRIVE_MOTOR:
end



