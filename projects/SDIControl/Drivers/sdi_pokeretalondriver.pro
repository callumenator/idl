
;\\ Poker Flat Etalon Driver (awaiting a better name...)
;\\ in = {leg_id:0, leg_voltage:0, ??? Motor position ??? }

pro SDI_PokerEtalonDriver, dll, command, in, out, result, unload=unload

	data = [byte((in.leg_voltage and '300'xu)/256), $
			byte(in.leg_voltage and 255us), $
			byte(in.legid+20), $
			byte(0)]

	comms_wrapper, 0, dll, type = 'dio', /dio_config, data = data, err = err
	result = err

	data[2] = byte(in.legid+4)

	comms_wrapper, 0, dll, type = 'dio', /dio_writeall, data = data, err = err
	result = [result, err]

	if keyword_set(unload) then res = call_external(dll, 'uDLLUnloader', /unload)
end