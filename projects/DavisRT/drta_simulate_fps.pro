
;\\ Move files, in intervals, into newdata

pro drta_simulate_fps

	moved_dirs_file = 'c:\cal\idlsource\davisrtnew\moved_dirs.dat'
	if file_test(moved_dirs_file) then begin
		restore, moved_dirs_file
	endif else begin
		moved_dirs = ''
	endelse

	base_dir = 'E:\Davis\06data\'
	to_dir = 'c:\cal\idlsource\davisrtnew\drta\newdata\'


	openw, log, 'c:\cal\idlsource\davisrtnew\drta\logs\move_log.txt', /append, /get_lun

		printf, log, systime()
		printf, log

		spec_dir_list = file_search(base_dir + '*SPECS', count = nspec_dirs)
		pics_dir_list = file_search(base_dir + '*PICS', count = npics_dirs)

		;spec_from_dir = 'C:\Cal\IDLSource\Davis Code Copy\070518SPECS\'
		;pics_from_dir = 'C:\Cal\IDLSource\Davis Code Copy\070518PICS\'

		for dir = 0, nspec_dirs - 1 do begin

			match = where(file_basename(spec_dir_list(dir)) eq file_basename(moved_dirs), nmtch)

			if nmtch eq 0 then begin

				list = file_search(to_dir, '*', count = nfiles)
				if nfiles lt 2000 then begin

					slist = file_search(spec_dir_list(dir), '*.630', count = nspec)
					plist = file_search(pics_dir_list(dir), '*.tif', count = npics)

					for n = 0, nspec - 1 do begin

						if strmid(file_basename(slist(n)),0,strlen(file_basename(slist(n)))-4) eq $
						   strmid(file_basename(plist(n)),0,strlen(file_basename(plist(n)))-4) then begin

							file_copy, slist(n), to_dir	+ file_basename(slist(n)), /verbose, /over
							file_copy, plist(n), to_dir	+ file_basename(plist(n)), /verbose, /over

						endif


						wait, .05
					endfor

					moved_dirs = [moved_dirs, spec_dir_list(dir)]
					save, filename = moved_dirs_file, moved_dirs
					print, systime(), 'Moved - ', spec_dir_list(dir)
					printf, log, systime(), ' - Moved - ', spec_dir_list(dir)


				endif else begin

					print, 'Too many files in Newdata'
					printf, log, systime(), ' - Too many files in Newdata'
					goto, DRTA_SIMULATE_FPS_END

				endelse

			endif else begin

				print, spec_dir_list(dir), 'Already copied..'

			endelse

			print, dir
			wait, .01
		endfor


DRTA_SIMULATE_FPS_END:
close, log
free_lun, log
end