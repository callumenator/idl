function READFITS, filename, header, heap, NOSCALE = noscale, $
		   SILENT = silent, EXTEN_NO = exten_no, NUMROW = numrow, $
                   POINTLUN = pointlun, STARTROW = startrow, $
		   NaNvalue = NaNvalue, NSLICE = nslice, $
                   nodata=nodata,shorthead=shorthead,nobig=nobig,hfile=hfile

;+
; NAME:
;	READFITS
; PURPOSE:
;	Read a FITS file into IDL data and header variables. 
; EXPLANATION:
;	Under Unix, READFITS() can also read gzip or Unix compressed FITS files.
;
; CALLING SEQUENCE:
;	Result = READFITS( Filename,[ Header, heap, /NOSCALE, EXTEN_NO=,
;			NSLICE=, /SILENT , NaNVALUE =, STARTROW =, NUMROW = ] )
;
; INPUTS:
;	FILENAME = Scalar string containing the name of the FITS file  
;		(including extension) to be read.   If the filename has
;		a *.gz extension, it will be treated as a gzip compressed
;		file.   If it has a .Z extension, it will be treated as a
;		Unix compressed file.
;
; OUTPUTS:
;	Result = FITS data array constructed from designated record.
;		If the specified file was not found, then Result = -1
;
; OPTIONAL OUTPUT:
;	Header = String array containing the header from the FITS file.
;       heap = For extensions, the optional heap area following the main
;		data array (e.g. for variable length binary extensions).
;
; OPTIONAL INPUT KEYWORDS:
;
;	EXTEN_NO - scalar integer specify the FITS extension to read.  For
;		example, specify EXTEN = 1 or /EXTEN to read the first 
;		FITS extension.    Extensions are read using recursive
;		calls to READFITS.
;
;	NaNVALUE - This scalar is only needed on architectures (such as VMS) 
;		that do not recognize the IEEE "not a number" (NaN) convention.
;		It specifies the value to translate any IEEE "not a number"
;		values in the FITS data array.    In addition, if the data is
;		stored as integer (BITPIX = 16 or 32), and BSCALE is present,
;		then NaNValue gives the values to pixels assigned with the
;		BLANK keyword.
;   
;	NOSCALE - If present and non-zero, then the ouput data will not be
;		scaled using the optional BSCALE and BZERO keywords in the 
;		FITS header.   Default is to scale.
;
;	NSLICE - An integer scalar specifying which N-1 dimensional slice of a 
;		N-dimensional array to read.   For example, if the primary 
;		image of a file 'wfpc.fits' contains a 800 x 800 x 4 array, 
;		then 
;
;			IDL> im = readfits('wfpc.fits',h, nslice=2)
;		is equivalent to 
;			IDL> im = readfits('wfpc.fits',h)
;			IDL> im = im(*,*,2)
;		but the use of the NSLICE keyword is much more efficient.
;
;	NUMROW -  This keyword only applies when reading a FITS extension. 
;		If specifies the number of rows (scalar integer) of the 
;		extension table to read.   Useful when one does not want to
;		read the entire table.
;
;	POINT_LUN  -  Position (in bytes) in the FITS file at which to start
;		reading.   Useful if READFITS is called by another procedure
;		which needs to directly read a FITS extension.    Should 
;		always be a multiple of 2880.
;
;	SILENT - Normally, READFITS will display the size the array at the
;		terminal.  The SILENT keyword will suppress this
;
;	STARTROW - This keyword only applies when reading a FITS extension
;		It specifies the row (scalar integer) of the extension table at
;		which to begin reading. Useful when one does not want to read 
;		the entire table.
;
; keywords added by FMW: NOBIG - set to NOT read array if >200000 bytes
; keywords added by FMW: NODATA - set to return header and 0 for data array
; keywords added by FMW: HFILE - set to header to disk file.
; keywords added by FMW: SHORTHEAD - (def) set to limit header to 78 characters
;
; EXAMPLE:
;	Read a FITS file TEST.FITS into an IDL image array, IM and FITS 
;	header array, H.   Do not scale the data with BSCALE and BZERO.
;
;		IDL> im = READFITS( 'TEST.FITS', h, /NOSCALE)
;
;	If the file contain a FITS extension, it could be read with
;
;		IDL> tab = READFITS( 'TEST.FITS', htab, /EXTEN )
;
;	The function TBGET() can be used for further processing of a binary 
;	table, and FTGET() for an ASCII table.
;	To read only rows 100-149 of the FITS extension,
;
;		IDL> tab = READFITS( 'TEST.FITS', htab, /EXTEN, 
;					STARTR=100, NUMR = 50 )
;
;	To read in a file that has been compressed:
;
;		IDL> tab = READFITS('test.fits.gz',h)
;
; ERROR HANDLING:
;	If an error is encountered reading the FITS file, then 
;		(1) the system variable !ERROR is set (via the MESSAGE facility)
;		(2) the error message is displayed (unless /SILENT is set),
;			and the message is also stored in !ERR_STRING
;		(3) READFITS returns with a value of -1
; RESTRICTIONS:
;	(1) Cannot handle random group FITS
;
; NOTES:
;	(1) If data is stored as integer (BITPIX = 16 or 32), and BSCALE
;	and/or BZERO keywords are present, then the output array is scaled to 
;	floating point (unless /NOSCALE is present) using the values of BSCALE
;	and BZERO.   In the header, the values of BSCALE and BZERO are then 
;	reset to 1. and 0., while the original values are written into the 
;	new keywords O_BSCALE and O_BZERO.     If the BLANK keyword was
;	present, then any input integer values equal to BLANK in the input
;	integer image are scaled to NaN (or the value of the NaNValue
;	keyword) after the scaling to floating point.
;	
;	(2) The procedure FXREAD can be used as an alternative to READFITS.
;	FXREAD has the option of reading an arbitary subsection of the 
;	primary FITS data.
;
;	(3) The use of the NSLICE keyword is incompatible with the NUMROW
;	or STARTROW keywords.
; PROCEDURES USED:
;	Functions:   SXPAR(), WHERENAN()
;	Procedures:  IEEE_TO_HOST, SXADDPAR, FDECOMP
;
; MODIFICATION HISTORY:
;	MODIFIED, Wayne Landsman  October, 1991
;	Added call to TEMPORARY function to speed processing     Feb-92
;	Added STARTROW and NUMROW keywords for FITS tables       Jul-92
;	Work under "windows"   R. Isaacman                       Jan-93
;	Check for SIMPLE keyword in first 8 characters           Feb-93
;	Removed EOF function for DECNET access                   Aug-93
;	Work under "alpha"                                       Sep-93
;       Null array processing fixed:  quotes in a message 
;          properly nested, return added.  Affected case when
;          readfits called from another procedure.   R.S.Hill    Jul-94
;	Correct size of variable length binary tables W.Landsman Dec-94
;	To read in compressed files on Unix systems. J. Bloch	 Jan-95
;	Check that file is a multiple of 2880 bytes              Aug-95
;	Added FINDFILE check for file existence K.Feggans        Oct-95
;	Consistent Error Handling W. Landsman                    Nov-95
;	Handle gzip image extensions  W. Landsman                Apr-96
;	Fixed bug reading 1-d data introduced Apr-96 W. Landsman Jun-96
;	Don't use FINDFILE (too slow), & check for Blank values WBL Oct-96
;	!VALUES wasn't compatible with IDL V3.6                 WBL Jan-97
;	Added ability to read Unix compressed (.Z) files        WBL Jan-97
;	Changed a FIX to LONG to handle very large tables       WBL Apr-97
;	Force use of /bin/sh shell with gzip                    WBL Apr-97
;       Recognize BSCALE, BZERO in IMAGE extensions             WBL Jun-97
;	Added NSLICE keyword                                    WBL Jul-97
;	Added ability to read heap area after extensions        WBL Aug-97	
;	Suppress *all* nonfatal messages with /SILENT           WBL Dec-97
;	Fix NaN assignment for int data		C. Gehman/JPL	Mar-98
;	Fix bug with NaNvalue = 0.0		C. Gehman/JPL	Mar-98
;       FW updates                                              April 1997
;-
;  On_error,2                    ;Return to user   ;***FMW
im=-7                                              ;***FMW
if not keyword_set(nodata) then nodata=0           ;***FMW
if n_elements(shorthead) eq 0 then shorthead=1     ;***FMW

; Check for filename input

   if N_params() LT 1 then begin		
      print,'Syntax - im = READFITS( filename, [ h, heap, /NOSCALE, /SILENT,
      print,'                 NaNValue = ,EXTEN_NO =, STARTROW = , NUMROW='
      print,'                 NSLICE = ]
      return, -1
   endif
;
;  	Determine if file exists.
;
oldfile=filename                 ;*** FMW ~
if not ffile(filename) and noext(filename) then begin    ;no extension - try defaults
   case 1 of
      ffile(filename+'.fits'): filename=filename+'.fits'
      ffile(filename+'.fit'): filename=filename+'.fit'
      ffile(filename+'.fts'): filename=filename+'.fts'
      ffile(filename+'.'): filename=filename+'.'
      else:
      endcase
   endif                         ;*** FMW ^
;

   silent = keyword_set( SILENT )
   openr, lun, filename, ERROR=error,/get_lun
   if error EQ 0 then free_lun,lun else begin
	message,/con,NoPrint=Silent,' ERROR - Unable to locate file ' + filename
	return, -1
   end   
;
;	Determine if the input file is compressed with gzip by the extension
;
   fdecomp,filename,disk,dir,name,ext,ver
   if (ext EQ "gz") or (ext EQ "Z") then gzip = 1 else gzip = 0
;
;
   if not keyword_set( EXTEN_NO ) then exten_no = 0

; Open file and read header information

    if gzip then begin

	if (not silent) and (exten_no EQ 0) then $
	    message,"Input file compressed with gzip",/inform
	spawn,"gzip -l "+filename,unit=unit
	tmp=" "
	readf,unit,tmp,format="(A80)"
	compsize=0L
	filesize=0L
	dum = " "
	origpcnt = " "
	readf,unit,compsize,filesize,origpcnt
	free_lun,unit
; Alternate means of obtaining filesize for 'compress'-ed files
        if filesize eq -1 then begin
           spawn,"zcat "+filename+" | wc -c ",unit=unit
           readf,unit,filesize
           free_lun,unit
           fcompr = (filesize-compsize)/float(filesize)
           origpcnt=string(fcompr*100,dir+name,format='(f6.1,"% ",a)')
       endif

	if (not silent) and (exten_no EQ 0) then begin

	    message,"Compressed size:"+string(compsize)+" bytes",/inform
	    message,"Uncompressed size:"+string(filesize)+" bytes",/inform
	    message,"% Compress/Original Filename: "+origpcnt,/inform

	endif

	spawn,"gzip -cd "+filename,unit=unit,/sh
	file=fstat(unit)

    endif else begin

  	openr, unit, filename, /GET_LUN, /BLOCK
        file = fstat(unit)
        flen = file.size/2880.
        if (long(flen) NE flen) then $
                 message,'WARNING - File size of ' + strupcase(filename) + $
                  ' is not a multiple of 2880 bytes',/CONT,NOPRINT=silent
    endelse

        if keyword_set( POINTLUN) then begin

		if gzip then begin

			tmp=bytarr(pointlun)
			readu,unit,tmp

		endif else begin

			point_lun, unit, pointlun 

		endelse

	endif else pointlun = 0

	if gzip then nbytesleft = filesize - pointlun else $
		nbytesleft = file.size - pointlun 

      	hdr = bytarr( 80, 36, /NOZERO )
        if nbytesleft LT 2880 then begin 
           free_lun, unit
           message,/CON,NoPrint=Silent, $
		'ERROR - EOF encountered while reading FITS header'
	   return, -1
        endif
        readu, unit, hdr
	nbytesleft = nbytesleft - 2880
        header = string( hdr > 32b )
        if ( pointlun EQ 0 ) then $
		if strmid( header(0), 0, 8)  NE 'SIMPLE  ' then begin
		message,/CON,NoPrint=Silent, $
		'ERROR - Header does not contain required SIMPLE keyword'
		free_lun, unit
		return, -1
        endif

        endline = where( strmid(header,0,8) EQ 'END     ', Nend )
        if Nend GT 0 then header = header( 0:endline(0) ) 

        while Nend EQ 0 do begin
            if nbytesleft LT 2880 then begin
                message,/CON,NoPrint=Silent, $
		'ERROR - EOF encountered while reading FITS header'
                free_lun, unit 
		return, -1
             endif
        readu, unit, hdr
        nbytesleft = nbytesleft - 2880
        hdr1 = string( hdr > 32b )
        endline = where( strmid(hdr1,0,8) EQ 'END     ', Nend )
        if Nend GT 0 then hdr1 = hdr1( 0:endline(0) ) 
        header = [ header, hdr1 ]
        endwhile

; Get parameter values

 Naxis = sxpar( header, 'NAXIS' )

 bitpix = sxpar( header, 'BITPIX' )
 if !ERR EQ -1 then begin 
	message,/CON,NoPrint=Silent, $
	'ERROR - FITS header missing required BITPIX keyword'
	free_lun, unit
	return, -1
 endif
 gcount = sxpar( header, 'GCOUNT') > 1
 pcount = sxpar( header, 'PCOUNT')

 case BITPIX of 
	   8:	IDL_type = 1          ; Byte
	  16:	IDL_type = 2          ; Integer*2
	  32:	IDL_type = 3          ; Integer*4
	 -32:   IDL_type = 4          ; Real*4
         -64:   IDL_type = 5          ; Real*8
        else:   begin
		message,/CON,NoPrint=Silent, $
		'ERROR - Illegal value of BITPIX (= ' +  $
                strtrim(bitpix,2) + ') in FITS header'
		free_lun,unit
		return, -1
		end
  endcase     

; Check for dummy extension header

 if Naxis GT 0 then begin 
        Nax = sxpar( header, 'NAXIS*' )	  ;Read NAXES
        ndata = nax(0)
        if naxis GT 1 then for i = 2, naxis do ndata = ndata*nax(i-1)

  endif else ndata = 0

  nbytes = (abs(bitpix)/8) * gcount * (pcount + ndata)

if keyword_set(nobig) then begin                            ;***FMW
   if not keyword_set(nodata) and (nbytes gt 2100000L) then nodata=1 $
      else nodata=0
   endif

  if pointlun EQ 0 then begin 

          extend = sxpar( header, 'EXTEND') 
   	  if !ERR EQ -1 then extend = 0
          if not ( SILENT) then begin
             if (exten_no GT 0) and  (not EXTEND) then message,NoPrint=Silent, $
               'ERROR - EXTEND keyword not found in primary header',/CON
          endif

  endif

  if keyword_set( EXTEN_NO ) then begin

           nrec = long(( nbytes +2879)/ 2880)

	   if gzip then pointlun = filesize - nbytesleft else $
           point_lun, -unit, pointlun          ;Current position

           pointlun = pointlun + nrec*2880l     ;Next FITS extension
           free_lun, unit
           im = READFITS( filename, header, heap, POINTLUN = pointlun, $
                          SILENT = silent, NUMROW = numrow, $
                          EXTEN = exten_no - 1, STARTROW = startrow, $
                          nodata=nodata,nobig=nobig )
if keyword_set(shorthead) then begin   ;********** truncate header lines
   bh=byte(header)
   bh=bh(0:78,*)
   header=string(bh)
   endif
if keyword_set(nodata) then begin     ;*** FMW ~
   close,unit & free_lun,unit
   return,0        ;header only
   endif                              ;*** FMW ^

           return, im
  endif                  

;
if keyword_set(shorthead) then begin   ;********** truncate header lines
   bh=byte(header)
   bh=bh(0:78,*)
   header=string(bh)
   endif
if keyword_set(nodata) then begin              ;header only  ;*** FMW ~
   close,unit & free_lun,unit
   return,0        ;header only
   endif                                       ;***  FMW ^

 if nbytes EQ 0 then begin
	if not SILENT then message, $
  	        "FITS header has NAXIS or NAXISi = 0,  no data array read",/CON
	free_lun, unit
	return,-1
 endif

; Check for FITS extensions, GROUPS

 groups = sxpar( header, 'GROUPS' ) 
 if groups then MESSAGE,'WARNING - FITS file contains random GROUPS', /CON

; If an extension, did user specify row to start reading, or number of rows
; to read?

   if not keyword_set(STARTROW) then startrow = 0
   if naxis GE 2 then nrow = nax(1) else nrow = ndata
   if not keyword_set(NUMROW) then numrow = nrow
       
  if pointlun GT 0 then begin
	xtension = strtrim( sxpar( header, 'XTENSION' , Count = N_ext),2)
	if N_ext EQ 0 then message, /CON, NoPRINT = Silent, $
		'ERROR - Header missing XTENSION keyword'
  endif 


   if (pointlun GT 0) and ((startrow NE 0) or (numrow NE nrow)) then begin
        nax(1) = nax(1) - startrow    
        nax(1) = nax(1) < numrow
        sxaddpar, header, 'NAXIS2', nax(1)
	if gzip then pointlun = filesize - nbytesleft else $
        point_lun, -unit, pointlun          ;Current position
        pointlun = pointlun + startrow*nax(0)      ;Next FITS extension
	if gzip then begin
		if startrow GT 0 then begin
			tmp=bytarr(startrow*nax(0))
			readu,unit,tmp
		endif 
	endif else point_lun, unit, pointlun
    endif else if keyword_set(NSLICE) then begin
	lastdim = nax(naxis-1)
	if nslice GE lastdim then message,/CON, NoPRINT = Silent, $
	'ERROR - Value of NSLICE must be less than ' + strtrim(lastdim,2)
	nax = nax(0:naxis-2)
	sxdelpar,header,'NAXIS' + strtrim(naxis,2)
	naxis = naxis-1
	sxaddpar,header,'NAXIS',naxis
	ndata = ndata/lastdim
		if gzip then currpoint = filesize - nbytesleft else $
        point_lun, -unit, currpoint          ;Current position
        currpoint = currpoint + nslice*ndata*abs(bitpix/8) 
	if gzip then begin
   			tmp = make_array( DIM = nax, TYPE = IDL_type, /NOZERO)
			if nslice GT 0 then for i=0,nslice-1 do readu,unit,tmp 
	endif else point_lun, unit, currpoint
  endif


  if not (SILENT) then begin   ;Print size of array being read

         if pointlun GT 0 then message, $
                     'Reading FITS extension of type ' + xtension, /INF
         snax = strtrim(NAX,2)
         st = snax(0)
         if Naxis GT 1 then for I=1,NAXIS-1 do st = st + ' by '+SNAX(I) $
                            else st = st + ' element'
         st = 'Now reading ' + st + ' array'
	 if (pointlun GT 0) and (pcount GT 0) then st = st + ' + heap area'
	 message,/INF,st   
   endif

; Read Data in a single I/O call

    data = make_array( DIM = nax, TYPE = IDL_type, /NOZERO)

    if nbytesleft LT N_elements(data) then begin
	message,/CON,NoPRINT=Silent, $
		'ERROR - End of file encountered while reading data array'
	free_lun,unit
	return,-1
    endif
    readu, unit, data
    if (pointlun GT 0) and (pcount GT 0) then begin
	theap = sxpar(header,'THEAP')
	skip = theap - N_elements(data)
	if skip GT 0 then begin 
		temp = bytarr(skip,/nozero)
		readu, unit, skip
	endif
	heap = bytarr(pcount*gcount*abs(bitpix)/8)
	readu, unit, heap
    endif

    free_lun, unit

; If necessary, replace NaN values, and convert to host byte ordering
        
   check_NaN = (bitpix LT 0) and (N_elements(NaNvalue) GT 0)
   if check_NaN then NaNpts = whereNaN( data, Count)
   ieee_to_host, data
   if check_NaN then $
	if ( Count GT 0 ) then data( NaNpts) = NaNvalue

; Scale data unless it is an extension, or /NOSCALE is set
; Use "TEMPORARY" function to speed processing.  

   do_scale = not keyword_set( NOSCALE )
   if (do_scale and ( PointLun GT 0)) then do_scale = xtension EQ 'IMAGE' 
   if do_scale then begin

	  Nblank = 0
	  if bitpix GT 0 then begin
		blank = sxpar( header, 'BLANK') 
		if !ERR NE -1 then $ 
			blankval = where( data EQ blank, Nblank)
	  endif

          bscale = float( sxpar( header, 'BSCALE' ))
	  if !ERR NE -1  then $ 
	       if ( Bscale NE 1. ) then begin
                   data = temporary(data) * Bscale 
                   sxaddpar, header, 'BSCALE', 1.
                   sxaddpar, header, 'O_BSCALE', Bscale,' Original BSCALE Value'
   	       endif

         bzero = float( sxpar ( header, 'BZERO' ) )
	 if !ERR NE -1  then $
	       if (Bzero NE 0) then begin
                     data = temporary( data ) + Bzero
                     sxaddpar, header, 'BZERO', 0.
                     sxaddpar, header, 'O_BZERO', Bzero,' Original BZERO Value'
	       endif

	if Nblank GT 0 then begin
	       if keyword_set(NaNValue) then $
			data(blankval) = NaNvalue else $
			data(blankval) = float( [127b,192b,0b,0b],0,1);NaN default
	endif

	endif

; Return array

	return, data    
 end 
