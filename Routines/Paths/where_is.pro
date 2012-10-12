
function where_is, what

	path = ''
	data_prefix = 'F:\SDIData\'

	what = strlowcase(what)
	case what of
		'fpsdata': path = data_prefix
		'davis_data': path = data_prefix+'Davis\'
		'mawson_data': path = data_prefix+'Mawson\'
		'poker_data': path = data_prefix+'Poker\'
		'toolik_data': path = data_prefix+'Toolik\'
		'gakona_data': path = data_prefix+'Gakona\'
		'pfisr_data': path = data_prefix+'PFISR\'
		'zone_overlaps': path = data_prefix+'MultiStatic\Overlaps\'
		else:
	end

	return, path

end