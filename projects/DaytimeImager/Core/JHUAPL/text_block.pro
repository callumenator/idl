;-------  text_block.pro = Print or return a block of inline text.  ---------
;	R. Sterner, 1998 Mar 3
 
	pro text_block, out, quiet=quiet, help=hlp
 
	if keyword_set(hlp) then begin
help:	  print,' Print or return a block of inline text (lines starts with ;).'
	  print,' text_block, out'
	  print,'   out = returned text block.       out'
	  print,' Keywords:'
	  print,'   /QUIET    Do not print text.'
	  print,' Notes: Block of text must directly follow text_block.'
	  print,' Examples:'
	  print,'     text_block'
	  print,'   ; This is a test.'
	  print,' '
	  print,' text_block'
	  print,'; Line 1'
	  print,'; Line 2'
	  print,'; Line 3'
	  print,' '
	  print,' <> The semicolon comment character must be in column 1.'
	  print,' <> The first character is dropped (semicolon is not printed).'
	  return
	end
 
	whocalledme, dir, file, line=n		; Find who called data_block.
	if file eq '' then goto, help
	name = filename(dir,file,/nosym)
	txt = getfile(name)			; Read in calling routine.
	last = n_elements(txt)-1		; Last line in routine.
 
	out = strarr((last-n)>1)		; Set up max possible space.
 
	;-----  Search until no more comment lines  --------
	for i=n, last do begin
	  if strmid(txt(i),0,1) ne ';' then goto, done	; Not a comment?
	  out(i-n) = strmid(txt(i),1,99)		; It was, grab it.
	endfor
 
done:	out = out(0:i-n-1)			; Keep only filled lines.
	if not keyword_set(quiet) then $	; Print if not /quiet.
	  for i=0,n_elements(out)-1 do print,out(i)
 
	end
