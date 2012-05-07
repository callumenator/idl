

;\\ Settings file written (UT): 2012-03-28
pro dcai_settings, settings = settings

	settings.etalon[0].port = 4
	settings.etalon[0].gap_mm = 3.0000
	settings.etalon[0].refractive_index = 1.0000
	settings.etalon[0].steps_per_order = 16.7076
	settings.etalon[0].scan_voltage = 55000
	settings.etalon[0].reference_voltage = 53363
	settings.etalon[0].parallel_offset = [0, -1509, 7]
	settings.etalon[0].leg_gain = [1.0000, 1.0000, 1.0000]
	settings.etalon[0].leg_voltage = [53363, 51854, 53370]
	settings.etalon[0].wedge_voltage = [35460, 60134, 10000]
	settings.etalon[0].voltage_range = [0, 65535]

	settings.etalon[1].port = 5
	settings.etalon[1].gap_mm = 0.2460
	settings.etalon[1].refractive_index = 1.0000
	settings.etalon[1].steps_per_order = 16.0310
	settings.etalon[1].scan_voltage = 21000
	settings.etalon[1].reference_voltage = 21271
	settings.etalon[1].parallel_offset = [0, 1038, -1519]
	settings.etalon[1].leg_gain = [1.0000, 0.9275, 0.6896]
	settings.etalon[1].leg_voltage = [19380, 20558, 18447]
	settings.etalon[1].wedge_voltage = [53712, 5393, 5393]
	settings.etalon[1].voltage_range = [0, 65535]

	settings.filter.port = 0
	settings.filter.name = ['one', 'two', 'three', 'four', 'five', 'six']
	settings.filter.current = 0

	settings.paths.log = 'c:\users\DaytimeImager\Logs\'
	settings.paths.persistent = 'c:\users\DaytimeImager\Persistent\'
	settings.paths.plugin_base = 'c:\users\DaytimeImager\Plugins\'
	settings.paths.plugin_settings = 'c:\users\DaytimeImager\Plugins\Plugin_Settings\'
	settings.paths.screen_capture = 'c:\users\DaytimeImager\Plugins\ScreenCaps\'
	settings.paths.zonemaps = 'C:\users\DaytimeImager\Scripts\Zonemap\'

	settings.site.name = 'DCAI at the GI'
	settings.site.code = 'DCAI_Test'
	settings.site.geo_lat = 65.0000
	settings.site.geo_lon = -147.0000

	settings.external_dll = 'SDI_External.dll'


end
