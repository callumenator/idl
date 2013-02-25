
function DCAI_SettingsTemplate

	whoami, dir, file

	etalon = {port:0, $
			  gap_mm:0.0, $
			  refractive_index:1.0, $
			  steps_per_order:0.0, $
			  scan_voltage:0L, $
			  reference_voltage:0L, $
			  parallel_offset:[0l,0l,0l], $
			  leg_gain:[0.0, 0.0, 0.0], $
			  leg_voltage:[0l,0l,0l], $
			  wedge_voltage:[0L,0L,0L], $
			  voltage_range:[0l,0l]}

	filter = {port:0, $
			  name:['one','two','three','four','five','six'], $
			  current:0 }

	paths = {log:dir + '..\Logs\', $
			 persistent:dir + '..\Persistent\', $
			 plugin_base:dir + '..\Plugins\', $
			 plugin_settings:dir + '..\Plugins\Plugin_Settings\', $
			 screen_capture:dir + '..\Plugins\ScreenCaps\', $
			 zonemaps:dir + '..\Scripts\Zonemap\'}

	site = {name:'', $
			code:'', $
			geo_lat:0.0, $
			geo_lon:0.0 }

	settings = {etalon:[etalon, etalon], $
				filter:filter, $
				paths:paths, $
				site:site, $
				external_dll:'SDI_External.dll' }

	return, settings
end


