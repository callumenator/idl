
pro rename_image_files_consecutive

	folder = 'C:\cal\IDLSource\NewAlaskaCode\TempZoneOverlapPics'
	list = file_search(folder, '*', count = nfiles)
	extension = '.png'
	for k = 0L, nfiles - 1 do begin
		file_move, list[k], file_dirname(list[k]) + '\' + $
			'Image_' + string(k, f='(i05)') + extension
		;print, file_dirname(list[k]) + '\' + $
		;	'Image_' + string(k, f='(i05)') + extension
	endfor

end