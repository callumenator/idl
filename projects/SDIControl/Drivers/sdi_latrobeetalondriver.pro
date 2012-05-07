
;\\ LaTrobe Etalon Driver (awaiting a better name...)
;\\ in = {leg_id:0, leg_voltage:0, port:0}

pro SDI_LaTrobeEtalonDriver, dll, command, in, out, result, unload=unload

	legid = long(in.legid)
    data = 'E1L' + string(legid, format='(i01)') + 'V' + string(in.leg_voltage, format = '(i04)') + string(13B)

	comms_wrapper, in.port, dll, type = 'moxa', /write, data = data, err = err
	result = err
	wait, 0.08

	if keyword_set(unload) then res = call_external(dll, 'uDLLUnloader', /unload)
end