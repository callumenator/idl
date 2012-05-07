
pro sdi_null_driver, command, in, out, result

	print, 'SDI NUll Driver: ' + command
	help, in
	result = ''
	out = 0

end