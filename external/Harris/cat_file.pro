;-----------------------------------------------------------------
	pro cat_file,lun,thisfile, EXIT=exit, WILD_SPEC=wild_spec, DIR=dir, $
		ONCE=once, RESULT=result, FILENAME=files, REMOTE=remote, $
		SUPPRESS=suppress

;+
; NAME:		CAT_FILE
;
; PURPOSE:	To enable generic opening/reading of files 
;			(be they on the current host or on another host, 
;			 be they normal, compressed or in a zoo file)
;
; CATEGORY:	File input
;
; CALLING SEQUENCE:
;		
;	CAT_FILE,lun,thisfile, EXIT=exit, WILD_SPEC=wild_spec, DIR=dir, $
;		ONCE=once, RESULT=result, FILENAME=datafile, REMOTE=remote, $
;		SUPPRESS=suppress
;
; INPUTS:
;	All optional, BUT one of 'lun' or 'RESULT' must be used to allow output
;
;	thisfile	==> 	force CAT_FILE to use this file 
;				(also inhibits prompt for filename)
;	WILD_SPEC	==>	Use this string as the file specifier. 
;				Follows standard UNIX conventions for 
;				wild_cards. 
;				Default is WILD_SPEC='*.*' so that everything 
;				is found, to give the user the full choice.
;	DIR		==>	Use this string as the default directory in 
;				which to search for files on the remote system.
;				Will also search this directory in the local
;				system if the search file is not found in the
;				current directory, prior to asking for a remote
;				system to search.
;	ONCE		==>	Give only one choice for the files, otherwise 
;				CAT_FILE will let you keep choosing files 
;				until you select the EXIT option on the menu. 
;				Then all the selected files will be CATted,
;				ZCATted or Zoo piped as one continuous file.
;	REMOTE		==>	Use this string to define the default remote 
;				host
;	SUPPRESS	==>	Suppress CAT_FILE's informative messages
;
; OUTPUTS:
;	All optional, BUT one of 'lun' or 'RESULT' must be used to allow output
;
;	lun		==>	The unit number which has the open file 
;				attached to it, ready for reading using 
;				READF,LUN
;	RESULT		==>	If used then force IDL to read ALL the file 
;				into an array which is passed out to RESULT.
;				This is an efficient way to read a small file,
;				but may take a long time or use alot of memory
;				for a large file.
;				Overrides the lun parameter.
;	EXIT		==>	= 0 if everything is fine
;				= 1 if you have chosen EXIT from the menu 
;					without having chosen any file
;				= 2 if you have chosen to CONTINUE with the 
;					same data 
;				When EXIT <> 0 CAT_FILE exits without doing 
;				anything. The EXIT keyword is there so that 
;				your program knows why CAT_FILE has exitted.
;	FILENAME	==>	Will contain the name of the file chosen
;
;
; COMMON BLOCKS:
;	none.
;
; RESTRICTIONS and SIDE EFFECTS:
;	Uses my routine CHOICES
;	Will spawn a process (one or a combination of CAT,ZCAT,ZOO,RSH,
;	and your default shell). If you abort IDL, or exit without closing 
;	or deallocating LUN (by using free_lun,lun) then these spawned 
;	processes may hang around to annoy you and the system administrator.
;
; COMMENTS:
;
;       You can use this routine to read a normal/compressed/zoo-ed file from
;	the current host or any other remote host.
;	NB: the files must be in the working directory on the current host
;	otherwise a remote host is asked for and the files searched for on that
;	system
;
;       Then to use the procedure within your program use the line
;
;       cat_file,lun,dir='whatever_directory_the_file_is_in',$
;			rem='name_of_remote_host',/once
;
;       "lun" need not be defined
;       What the procedure will do is ask you for a file name, then prompt
;       for a remote device (which you have set to default to 
;	'name_of_remote_host' by using the REM keyword, so you can just hit 
;	return). It will then go to the directory set in the DIR keyword on 
;	the remote device and try to cat/zcat/zoo the file. 
;	If you DONT enter a file name at the file prompt BUT ENTER r INSTEAD 
;	then it will go to the remote device and list the directory contents
;	(using the WILD_SPEC) and let you choose a file. 
;	If you DONT enter anything at the file prompt then the current host 
;	and directory are used (try this first).
;	Once the file is selected it is opened for reading and attached to a 
;	unit number which is passed to lun. 
;	So once you exit "cat_file" the file you want is opened for reading 
;	on unit lun, so use something like
;				readf,lun,whatever
;
;       CAT_FILE simply replaces the openr,lun,file,/get_lun call.
;
;	REMEMBER to free the unit, if you use the lun option, by calling
;			free_lun,lun
;	BEFORE you exit IDL.
;
;
;	EXAMPLES ----
;
;	To see what it does, use cat_file like this,
;
;	cat_file,lun
;
;	OR
;
;	cat_file,lun,wild='*.data data/*.data',rem='eve',dir='DATA/winds'
;
;       If you want the ENTIRE file read into an array, use cat_file like this,
;
;       cat_file,result=array,dir='/mod/tharris/DATA',$
;		rem='strato.physics',/once
;
;	BEWARE, this may take a LONG time and use ALOT of memory if the file 
;	is TOO LARGE !!!!
;
;       If you already know the file name, use cat_file like this,
;
;       cat_file,lun,filename,result=array,dir='/mod/tharris/DATA',$
;		rem='strato.physics',/once
;
;       with or without the RESULT keyword.
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Ammended: 
;		Added SUPPRESS keyword and ZOO option on local host
;		April 1992, T.J.H.
;	Ammended to also handle VMS operating system
;		At this stage the file to be read must be in standard format
;		(NOT zooed NOR compressed)
;		Temporary patch July, 1992, T.J.H.
;
;-

if (strpos(strupcase(!version.os),'VMS') ge 0) then vms = 1b else vms = 0b

;set default values for all options
default_remote = 'eve'
default_wildspec = '*.*'
default_dir = 'DATA'

if (vms) then dir_delimit = '' else dir_delimit = '/'

if (not keyword_set(suppress)) then begin
	print,' '
	print,' .... Entered CAT_FILE  '
	print,' '
endif

exit = 0
answer = ' '
use_local = 0
if (not keyword_set(wild_spec)) then wild_spec = default_wildspec
if (not keyword_set(dir)) then dir = default_dir

home = getenv('HOME')
i = strpos(wild_spec,'~')	 &	loop = 0
while (i ge 0) and (loop lt 100) do begin
	;replace the ~ with the full path name 
	;(IDL should do this by default !!!)
	wild_spec = strmid(wild_spec,0,i)+home+strmid(wild_spec,i+1,256)
	i = strpos(wild_spec,'~')	&	loop = loop + 1
endwhile
i = strpos(dir,'~')	 &	loop = 0
while (i ge 0) and (loop lt 100) do begin
	;replace the ~ with the full path name 
	;(IDL should do this by default !!!)
	dir = strmid(dir,0,i)+home+strmid(dir,i+1,256)
	i = strpos(dir,'~')	&	loop = loop + 1
endwhile

;under VMS we must place all references to directories inside square brackets 
;and separate with . (rather than simply separating with /)
if (vms) then begin
	dir = unix2vms(dir)
	wild_spec = unix2vms(wild_spec)
endif

on_ioerror,endd

if (n_elements(thisfile) gt 0 ) then begin
	n = n_elements(thisfile)-1
	for i=0,n do answer = answer+thisfile(i)+' '
endif else begin
	print, ' '
	print,' Enter the name of the file containing the data '
	print,'     ( Auto ==> <RETURN> , current data ==> c, Remote ==> r, EXIT ==> x ) '
	read,answer
	print, ' '
endelse
case strlowcase(answer) of
        ''  : answer = wild_spec
        ' ' : answer = wild_spec
        'r' : begin
		if (not keyword_set(remote)) then remote = default_remote
		answer = wild_spec
	      end
        'n' : goto, bypass
        'c' : goto, bypass
        'x' : goto, endd
        'q' : goto, endd
        else: ;continue
endcase

if (strpos(answer,'.zoo') gt 0) then begin
	i = strpos(answer,',') 
	if ( i le 2) then i = strpos(answer,':')
	if ( i gt 2) then begin
		search_file = strmid(answer,0,i)
	endif else begin
		search_file = answer
	endelse
endif else begin
	search_file = answer
endelse

if (not keyword_set(suppress)) then $
print,' ......Searching for data file, ',search_file

if (keyword_set(remote)) then begin
	found = ' '
	use_local = -1
endif else $
	found = findfile(search_file,count=use_local)

if (use_local le 0) and (not keyword_set(remote)) then begin 
	if (not keyword_set(suppress)) then $
	print,' ......Searching for data file, ',dir+dir_delimit+search_file
	found = findfile(dir+dir_delimit+search_file,count=use_local)
	if (use_local gt 0) then answer = dir+dir_delimit+search_file
endif else found = basename(found)

if (use_local gt 1) then begin
	datafile = ' '
	answer = ' '
	while(strpos(answer,'No File') lt 0) do begin
		answer = choice(found,title=' Choose a File ') 
		if (strpos(answer,'.zoo') gt 0) then once=1
		datafile =[datafile,answer]
		if (keyword_set(once)) then begin
			answer = 'No File'
			datafile =[datafile,answer]
		endif
	endwhile
	datafile = datafile(1:*)	;remove dummy first element
	n = n_elements(datafile)-1
	if (n lt 1) then goto,endd 	;no files where chosen, EXIT, else
	datafile = [datafile(0:n-1)]	;remove the EXIT string at end
	if (strpos(datafile(0),'No File') ge 0) then goto,endd
					;no files where chosen, EXIT
endif else datafile = [answer]

;open the data file
datafile = strtrim(datafile,2)
titleh = ' '

zoofile = ' '

if (use_local gt 0) then begin
	; these lines are for use when the file is on the current machine

	;check to see if a zoo file has been specified
	if (strpos(datafile(0),'.zoo') gt 0) then begin
		answer = strcompress(datafile(0),/rem)
		i = strpos(answer,',') 
		if ( i le 2) then i = strpos(answer,':')
		if ( i gt 2) then begin
			zoofile = strmid(answer,0,i)
			datafile(0) = strmid(answer,i+1,strlen(answer))
		endif else begin
			zoofile = datafile(0)
			datafile(0) = wild_spec
		endelse
	endif

	if (zoofile eq ' ') then begin

		if (datafile(0) eq wild_spec) then datafile=[strtrim(found,2)]
		n = n_elements(datafile)-1
		files = ' '
		for i=0,n do files = files+datafile(i)+' '
		files = strtrim(files,2)
		i = strlen(datafile(0))-1
		if (strmid(datafile(0),i-1,2) eq '.Z') then $
			command = 'zcat '+files $
		else $
			command = 'cat '+files
		if (not keyword_set(suppress)) then begin
			print,' '
			print,' Opening data file ---- ',files
		endif

	endif else begin
		;file has to be extracted from a zoo file
		if (not keyword_set(suppress)) then $
		print,'     .....searching for zoo file, ',zoofile

		if (datafile(0) eq wild_spec) then begin
			command = 'zoo ld '+strcompress(zoofile,/rem)
			spawn,command,output
			files = choice(output,title=' Select a File from '+strcompress(zoofile,/rem))
			if (strpos(files,'No File') ge 0) then goto,endd
			files = strmid(files,46,strlen(files))
		endif else begin
			n = n_elements(datafile)-1
			files = ' '
			for i=0,n do files = files+datafile(i)+' '
		endelse

		files = strtrim(files,2)
		if (not keyword_set(suppress)) then $
		print,'     .....extracting data file, ',files
		command = 'zoo xpq '+strcompress(zoofile,/rem)+' '+files
	endelse

endif else begin
	; these lines are for use when the file is on another machine

	if (vms) then begin
		print,'....... FILE NOT FOUND..'
		print,' No remote machine access is allowed under VMS '
		goto, endd
	endif
	
	if (not keyword_set(remote)) then begin
		remote = ' '
		print,' Enter the name of the remote machine where the file is stored'
		read,remote
	endif

	if (strlen(remote) lt 3) then remote = default_remote
	remote = strcompress(remote,/rem)

	i = strpos(remote,',') 
	if ( i le 2) then i = strpos(remote,':')
	if ( i gt 2) then begin
		remote_dir = strmid(remote,i+1,strlen(remote))
		remote = strmid(remote,0,i)
	endif else begin
		remote_dir = dir
	endelse

	;check to see if a zoo file has been specified
	if (strpos(remote_dir,'.zoo') gt 0) then zoofile = remote_dir else begin
		n = strlen(remote_dir)-1
		if (strmid(remote_dir,n,1) ne dir_delimit) then remote_dir = strcompress(remote_dir+dir_delimit,/rem)

		if (datafile(0) eq wild_spec) then begin
			command = 'rsh '+strcompress(remote,/rem)+' -n "cd '+strcompress(remote_dir,/rem)+' ; ls -lFa '+strtrim(datafile,2)+'"'
			if (not keyword_set(suppress)) then print,command
			spawn,command,output
			if (total([strlen(output)]) lt 2) then goto,endd
			datafile = ' '
			answer = ' '
			while(strpos(answer,'No File') lt 0) do begin
				answer = choice(output,title=' Select a File from '+strcompress(remote+': '+remote_dir,/rem))
				if (strpos(answer,'.zoo') gt 0) then once=1
				datafile =[datafile,answer]
				if (keyword_set(once)) then begin
					answer = 'No File'
					datafile =[datafile,answer]
				endif
			endwhile
			datafile = datafile(1:*)	;remove dummy first element
			n = n_elements(datafile)-1
			if (n lt 1) then goto,endd 	;no files chosen, EXIT, else
			datafile = [datafile(0:n-1)]	;remove the EXIT string at end
			n = strlen(datafile(0))
			if (n lt 2) then goto,endd
			datafile = strmid(datafile,45,180)
		endif

		datafile = strcompress(remote_dir+datafile,/rem)
		;check to see if a zoo file has been specified
		if (strpos(datafile(0),'.zoo') gt 0) then begin
			zoofile = datafile(0)
			datafile(0) = wild_spec
		endif

	endelse

	if (zoofile eq ' ') then begin
		n = n_elements(datafile)-1
		files = ' '
		for i=0,n do files = files+datafile(i)+' '
		i = strlen(datafile(0))-1
		if (strmid(datafile(0),i-1,2) eq '.Z') then $
			command = 'rsh '+remote+' -n "zcat '+files+'"' $
		else $
			command = 'rsh '+remote+' -n "cat '+files+'"' 
		if (not keyword_set(suppress)) then begin
			print,' '
			print,' Opening data file ---- ',remote+':'+files
		endif

	endif else begin
		;file has to be extracted from a remote zoo file
		if (not keyword_set(suppress)) then begin
			print,'     .....searching for zoo file, ',zoofile
			print,'          on remote machine, ',remote
		endif

		if (datafile(0) eq wild_spec) then begin
			command = 'rsh '+strcompress(remote,/rem)+' -n zoo ld '+strcompress(zoofile,/rem)
			spawn,command,output
			files = choice(output,title=' Select a File from '+strcompress(remote,/rem)+': '+strcompress(zoofile,/rem))
			if (strpos(files,'No File') ge 0) then goto,endd
			files = strmid(files,46,strlen(files))
		endif else begin
			n = n_elements(datafile)-1
			files = ' '
			for i=0,n do files = files+datafile(i)+' '
		endelse

		files = strtrim(files,2)
		if (not keyword_set(suppress)) then $
		print,'     .....extracting data file, ',files
		command = 'rsh '+strcompress(remote,/rem)+' -n zoo xpq '+strcompress(zoofile,/rem)+' '+files
	endelse
endelse
if (not keyword_set(suppress)) then print,command
if (not keyword_set(suppress)) then print,' '
if (keyword_set(result)) then spawn,command,result else $
	if (n_params() gt 0) then $
		if (vms) then openr,lun,datafile(0),/get_lun $
		else spawn,command,unit=lun $
	else begin
		print,'... No variable to pass unit number out '
		print,'... No keyword parameter RESULT to pass result out to '
		goto,endd
	endelse

exit = 0
return

bypass:
print, '...............continue with same data file '
exit = 2
return

endd:
exit = 1
return
end

