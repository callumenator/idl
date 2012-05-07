pro mc_packngo, folder=folder
    whoami, dir, file
    if not(keyword_set(folder)) then folder = dialog_pickfile(path=dir, title='EMPTY Directory to assemble files?', /dir)
    if strlen(folder) eq 0 then return
    flis = findfile(folder + '*.*')
    hstr = 'Existing files are:' + string([13b, 10b, 13b, 10b])
    for j=2,n_elements(flis)-1 do begin
        fname = strmid(flis(j), strlen(folder), 999)
        hstr = hstr + fname + string([13b, 10b])
    endfor
    mcchoice, 'What to do:', ['Yes, delete files', 'No, leave existing'], choice, $
	       heading = {text: 'Delete existing files?', font: 'Helvetica*Bold*Proof*30'}, $
	       help=hstr, hbox=[40, n_elements(flis)]
    if choice.index eq 0 then begin
       mcchoice, 'What to do:', ['Yes, delete files', 'No, leave existing'], choice, $
		  heading = {text: 'Are you sure?', font: 'Helvetica*Bold*Proof*30'}, $
		  help=hstr, hbox=[40, n_elements(flis)]
       if choice.index eq 0 then spawn, 'del ' + folder + '*.*'
    endif

    resolve_all, /cont

    prose   = routine_info(source='name')
    funx    = routine_info(source='name', /func)
    prose   = [prose.path, funx.path]
    distn   = filepath('')
    keepers = where(strpos(prose, distn) lt 0)
    prose   = prose(keepers)
    keepers = where(strpos(strupcase(prose), 'MC_PACKNGO.PRO') lt 0)
    prose   = prose(keepers)

    for j=0, n_elements(prose)-1 do begin
        copycmd = 'copy ' + prose(j) + ' ' + folder
        spawn, copycmd
        wait, 0.2
    endfor
end