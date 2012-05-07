
pro SDIControl_FindPlugins, path

	common SDIControl

	list = file_search(path, 'sdi_*__define.pro', count = nplugins)

	name = list
	for j = 0, nplugins - 1 do begin
		fname = file_basename(list[j])
		name[j] = strmid(fname, 0, strlen(fname) - 12)
	endfor

	sdic_plugins = {fullPath:list, $
				   name:name }

end