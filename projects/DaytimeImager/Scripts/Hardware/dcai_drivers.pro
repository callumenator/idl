
;\\ Turn a 16-bit unsigned (0-4095) integer into a 3-character HEX string
function DCAI_Drivers_Etalon_MakeHEX, i

	;\\ 16-bit integer number, force into range without wrapping
	if i lt 0 then i = 0
	if i gt 65535 then i = 65535

	hex_string = string(i, f='(z04)')
	return, hex_string
end



pro DCAI_Drivers, command

	COMMON DCAI_Control, dcai_global


	case command.device of

		'etalon_setlegs':begin

			tx = string(13B)
			voltage = command.voltage > 0
			voltage = voltage < 65535
			hex_string = string(voltage, f='(z04)')
			vol_string = strjoin(hex_string)

			cmd_string = 'u' + string(command.number + 1, f='(i1)') + vol_string + tx

			comms_wrapper, dcai_global.settings.etalon[command.number].port, dcai_global.settings.external_dll, $
				   		   type='moxa', /write, data=cmd_string
			wait, 0.02
			comms_wrapper, dcai_global.settings.etalon[command.number].port, dcai_global.settings.external_dll, $
				   		   type='moxa', /read, data=read_in

		end


		'etalon_init':begin

			dcai_log, 'Initialising Etalons'

			for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[k].port, dcai_global.settings.external_dll, $
					   		   	   type='moxa', /open, err=err, moxa_setbaud=15
				dcai_log, 'Open Port: ' + string(dcai_global.settings.etalon[k].port, f='(i0)') + ' ' + string(err, f='(i0)')
			endfor


			tx = string(13B)
			cmds = ['E1R1CC150', 'E1R1CF128', 'E1R1RC231', 'E1R1RF150', $
					'E1R2CC150', 'E1R2CF128', 'E1R2RC231', 'E1R2RF150', $
					'E1R3CC150', 'E1R3CF128', 'E1R3RC231', 'E1R3RF150', $

					'E1L1CC092', 'E1L1CF128', 'E1L1RC232', 'E1L1RF080', $
					'E1L2CC085', 'E1L2CF129', 'E1L2RC230', 'E1L2RF154', $
					'E1L3CC095', 'E1L3CF132', 'E1L3RC231', 'E1L3RF060', $

					'E1L1DD246', 'E1L1DG60000', $
					'E1L2DD246', 'E1L2DG60000', $
					'E1L3DD246', 'E1L3DG60000'  ]


			comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
			wait, .1
			for i = 0, n_elements(cmds) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /write, data=cmds[i] + tx
				wait, 0.2
				comms_wrapper, dcai_global.settings.etalon[0].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
				dcai_log, cmds[i] + ': ' + read_in
			endfor

			cmds = ['E2R1CC150', 'E2R1CF128', 'E2R1RC231', 'E2R1RF150', $
					'E2R2CC150', 'E2R2CF128', 'E2R2RC231', 'E2R2RF150', $
					'E2R3CC150', 'E2R3CF128', 'E2R3RC231', 'E2R3RF150', $

					'E2L1CC095', 'E2L1CF132', 'E2L1RC231', 'E2L1RF091', $
					'E2L2CC101', 'E2L2CF110', 'E2L2RC229', 'E2L2RF162', $
					'E2L3CC100', 'E2L3CF131', 'E2L3RC228', 'E2L3RF065', $

					'E2L1DD244', 'E2L1DG60000', $
					'E2L2DD244', 'E2L2DG60000', $
					'E2L3DD245', 'E2L3DG60000'  ]

			wait, .1
			comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
			wait, .1
			for i = 0, n_elements(cmds) - 1 do begin
				comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /write, data=cmds[i] + tx
				wait, 0.2
				comms_wrapper, dcai_global.settings.etalon[1].port, dcai_global.settings.external_dll, $
				   		   	   type='moxa', /read, data=read_in
				dcai_log, cmds[i] + ': ' + read_in
			endfor

		end


		'filter_select':begin


		end


		'camera_flush':begin
			Andor_Camera_Driver, dcai_global.settings.external_dll, 'uFreeInternalMemory', 0, out, res, /auto_acq
		end




		else:begin

		end


	endcase

end