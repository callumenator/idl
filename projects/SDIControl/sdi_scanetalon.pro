

pro sdi_ScanEtalon, errcode = errcode

	common SDIControl

	if scan.active eq 0 then return

	scan.leg_voltage = scan.leg_offset + scan.leg_gain*float(scan.channel)* $
										 scan.steps_per_channel*scan.wavelength_nm

	call_procedure, drivers.etalon, misc.dll, 'dummy', $
		{legid:1, leg_voltage:scan.leg_voltage[1], port:hardware.etalon.value}, out, res
	errcode = res

	call_procedure, drivers.etalon, misc.dll, 'dummy', $
		{legid:2, leg_voltage:scan.leg_voltage[2], port:hardware.etalon.value}, out, res
	errcode = [errcode, res]

	call_procedure, drivers.etalon, misc.dll, 'dummy', $
		{legid:3, leg_voltage:scan.leg_voltage[3], port:hardware.etalon.value}, out, res
	errcode = [errcode, res]

end