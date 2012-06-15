
function where_is, what

	path = ''

	external = 1

	if external eq 0 then data_prefix = 'e:\fpsdata\' $
		else data_prefix = 'z:\'


	what = strlowcase(what)
	case what of

		'geodata': path = 'c:\cal\geodata\'

		'fpsdata': path = data_prefix
		'davis_data': path = data_prefix+'Davis\'
		'mawson_data': path = data_prefix+'Mawson\'
		'poker_data': path = data_prefix+'Poker\'
		'gakona_data': path = data_prefix+'Gakona\'
		'gakona_thermal_log': path = 'C:\cal\Operations\SDI_Instruments\Gakona\ThermalLogs\'
		'pfisr_data': path = data_prefix+'PFISR\'

		'monostatic_fits': path = 'c:\cal\idlsource\newalaskacode\windfit\windfitsaveddata\'
		'bistatic_fits': path = 'c:\cal\idlsource\newalaskacode\windfit\windfitsaveddata\'
		'usolve_fits': path = 'c:\cal\idlsource\newalaskacode\windfit\windfitsaveddata\'

		'zone_overlaps': path = 'C:\Cal\IDLSource\NewAlaskaCode\WindFit\WindFitSavedData\'

		'papers': path = 'c:\cal\docs\latex\papers\'

		'color_tables': path = 'c:\cal\idlsource\newalaskacode\colortables\'

		'sdi_skymap_series': path = 'c:\cal\fpsdata\skymaps\'

		'mawson_davis_cv': path = 'C:\Cal\idlgit\Davis\CommonVolume\'

		'poker_asc': path = 'c:\cal\fpsdata\poker_asc\'

		'davis_lel': path = data_prefix + '\Davis_SensorLogs\'

		'windsim': path = 'c:\cal\idlsource\newalaskacode\windfit\windsim\'

		'good_data_list': path = 'c:\cal\SDI_Good_Dates.txt'

		else:
	end

	return, path

end