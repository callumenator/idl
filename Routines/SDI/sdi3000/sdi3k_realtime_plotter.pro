;==================================================================
; This is a batch-mode program to generate real-time analysis and
; real-time plots of Poker SDI data.
; Mark Conde, Fairbanks, November 2008.



;-------------------------------------------------------------------
;   This routine returns a data structure containing all the various
;   filenames that will be needed:
pro sdi3k_rt_build_filenames, skysrc, skydest, calsrc, caldest, semaphore, messages

    srcpath = '\\137.229.36.92\Data\spectra\'
    srcpath = 'C:\cal\FPSData\RTPlot_Test\'
    dstpath = 'C:\cal\FPSData\Gakona_Realtime\'

    skyfiles = mc_recent_files(path=srcpath, filter="*_Sky_*", max_age=0.9*86400L, count=nf)
    if nf eq 0 then exit, /no_confirm
    if nf gt 3 then skyfiles = skyfiles(0:2)

;---Check if the sky files are big enough to contain any data (spectra) yet. We don't want to attempt
;   to process files that have been created, but don't yet contain any spectra:
    if max(skyfiles.size) lt 5000 then exit, /no_confirm
    goods = where(skyfiles.size ge 5000, ng)
    if ng gt 0 then skyfiles = skyfiles(goods)

    skysrc  = skyfiles.name
    details = mc_fileparse(skyfiles.name)
    skydest = dstpath + details.namepart
    wait, 0.1


    calfiles = mc_recent_files(path=srcpath, filter="*_Cal_*", max_age=0.9*86400L, count=nf)
    if nf eq 0 then exit, /no_confirm
    if nf gt 1 then calfiles = calfiles(0)
    if calfiles(0).size lt 5000 then exit, /no_confirm

    calsrc  = calfiles(0).name
    details = mc_fileparse(calfiles.name)
    caldest = dstpath + details(0).namepart

    semaphore = dstpath + 'Nobody_but_sdi3k_rt_would_make_this.I_hope'
    messages  = 'c:\inetpub\wwwroot\conde\sdiplots\SDI_realtime_plot_log.tmp'

end

;-------------------------------------------------------------------
;   This routine checks if another instance of sdi3k_rtplot is already
;   running. If so, it exits IDL immediately.
pro sdi3k_rt_check_semaphore, semaphore
    xx = findfile(semaphore, count=cc)
    xx = mc_fileparse(semaphore)
    sems = mc_recent_files(path=xx.path, filter=xx.namepart, max_age=1800L, count=cc)
    if cc gt 0 then exit, /no_confirm else begin
       whoami, dir, file
       spawn, 'copy ' + dir + file + ' ' + semaphore
    endelse
end

;-------------------------------------------------------------------
;   This routine creates an empty destination netCDF file and defines
;   the required dimensions and variables for SDI data. Then, it
;   copies the "header" info from the corresponding source netCDF
;   file:
pro sdi3k_rt_establish_one_file, src, dest

       print, 'Creating file: ' + dest
       sdi3k_read_netcdf_data, src, metadata=mm, /close
       rem = ncdf_open (src)
       ncdf_varget,  rem, ncdf_varid(rem, 'Zone_Radii'),   radii,   offset = 0, count=mm.rings+1
       ncdf_varget,  rem, ncdf_varid(rem, 'Zone_Sectors'), sectors, offset = 0, count=mm.rings
       ncdf_close, rem

				ncdid = ncdf_create(dest, /clobber)

			;\\ Create some dimensions
				chan_dim_id = ncdf_dimdef(ncdid, 'Channel', mm.scan_channels)
				zone_dim_id = ncdf_dimdef(ncdid, 'Zone',    mm.nzones)
				time_dim_id = ncdf_dimdef(ncdid, 'Time',    /unlimited)
				rid 		= ncdf_dimdef(ncdid, 'Rings', 	mm.rings+1)
				rid2 		= ncdf_dimdef(ncdid, 'Rings2', 	mm.rings)
;---------------The following two dimensions are not used in the realtime local copy
;               files, but are needed for the netCDF reader to work correctly:
				xdim_id = ncdf_dimdef(ncdid, 'XDim',  512)
				ydim_id = ncdf_dimdef(ncdid, 'YDim',  512)

				bdate = bin_date(systime(/ut))
				date = string(bdate(2)) + '/' + string(bdate(1)) + '/' + string(bdate(0))


			;\\ Create the global attributes
				ncdf_attput, ncdid, /global, 'Start_Date_UT',date,  	       /char
				ncdf_attput, ncdid, /global, 'Site',      	 mm.site,      /char
				ncdf_attput, ncdid, /global, 'Site_code', 	 mm.site_code, /char
				ncdf_attput, ncdid, /global, 'Latitude',  	 mm.latitude,  /float
				ncdf_attput, ncdid, /global, 'Longitude', 	 mm.longitude, /float
				ncdf_attput, ncdid, /global, 'Operator',  	 mm.operator,  /char
				ncdf_attput, ncdid, /global, 'Comment',   	 mm.comment,   /char
				ncdf_attput, ncdid, /global, 'Software',  	 'November 2008',  /char

			;\\ Create the variables
				id = ncdf_vardef  (ncdid, 'Start_Time',      time_dim_id, /long)
		       	id = ncdf_vardef  (ncdid, 'End_Time',        time_dim_id, /long)
    		   	id = ncdf_vardef  (ncdid, 'Number_Scans',    time_dim_id, /short)
       			id = ncdf_vardef  (ncdid, 'X_Center',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Y_Center',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Cam_Temp',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Cam_Gain',        time_dim_id, /short)
      			id = ncdf_vardef  (ncdid, 'Cam_Exptime',     time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'X_Bin',             	  /short)
      			id = ncdf_vardef  (ncdid, 'Y_Bin',                /short)
     			id = ncdf_vardef  (ncdid, 'Gap',                  /float)
       			id = ncdf_vardef  (ncdid, 'Nm_Per_Step',     time_dim_id, /float)
       			id = ncdf_vardef  (ncdid, 'Scan_Channels',        /short)
       			id = ncdf_vardef  (ncdid, 'Gap_Refractive_Index', /float)
       			id = ncdf_vardef  (ncdid, 'Zone_Radii',      rid, /float)
       			id = ncdf_vardef  (ncdid, 'Zone_Sectors',    rid2, /byte)
				id = ncdf_vardef  (ncdid, 'Wavelength',      	  /float)
				id = ncdf_vardef  (ncdid, 'Leg1_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg2_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg3_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg1_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Leg2_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Leg3_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Spectra', [zone_dim_id, chan_dim_id, time_dim_id], /long)

			;\\ Write the attributes
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Start_Time'),           'Units', 'Julian seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'End_Time'),             'Units', 'Julian seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),         'Units', 'Etalon scans', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Zone_Radii'),           'Units', 'Zone ring radii percent fov', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Zone_Sectors'),         'Units', 'Sectors per ring', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Center'),             'Units', 'Image pixel number', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Center'),             'Units', 'Image pixel number', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),             'Units', 'Degrees', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),             'Units', 'Dimensionless', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'),          'Units', 'Seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Bin'), 	           'Units', 'Image x binning in pixels', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),     	       'Units', 'Image y binning in pixels', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Gap'),                  'Units', 'mm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Nm_Per_Step'),          'Units', 'nm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),        'Units', 'Etalon steps per interference order', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Gap_Refractive_Index'), 'Units', 'Dimensionless', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength'),   		   'Units', 'nm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg1_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg2_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg3_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg1_Offset'),   	   'Units', 'Dimensionless', /char
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg2_Offset'),   	   'Units', 'Dimensionless', /char
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg3_Offset'),   	   'Units', 'Dimensionless', /char
                ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectra'),              'Units', 'Camera digital units', /char
                ncdf_attput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'),    'Units', 'Camera digital units', /char

				ncdf_control, ncdid, /endef

;---------------Write the static variables:
				ncdf_varput, ncdid, ncdf_varid(ncdid, 'X_Bin'),	                1
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),                 1
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Gap'),                   mm.gap_mm
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),         mm.scan_channels
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Gap_Refractive_Index'),  mm.gap_refractive_index
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength'),  		    mm.wavelength_nm
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Zone_Radii'),            radii
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Zone_Sectors'),          sectors

				ncdf_control,ncdid, /sync
				ncdf_close,  ncdid

end

;-------------------------------------------------------------------
;   This routine checks if we have local copies of the current SDI
;   sky and ins data files. If not, it creates these files and copies
;   the "header" data from the sdi machine.
pro sdi3k_rt_establish_local_files, skysrc, calsrc, skydest, caldest
    for j=0,n_elements(skydest)-1 do begin
        if not(file_test(skydest(j))) then sdi3k_rt_establish_one_file, skysrc(j), skydest(j)
            wait, 0.01

    endfor
    if not(file_test(caldest(0))) then sdi3k_rt_establish_one_file, calsrc(0), caldest(0)
end

;-------------------------------------------------------------------
;   This routine appends the most recent data to the local copies
;   of the current SDI data files:
pro sdi3k_rt_update_local_files, remfile, locfile, count
    count = 0
    rem   = ncdf_open (remfile)
    loc   = ncdf_open (locfile, /write)

    ncdf_diminq, rem, ncdf_dimid(rem, 'Time'), dummy, maxrem
    ncdf_diminq, loc, ncdf_dimid(loc, 'Time'), dummy, maxloc

    if maxrem gt maxloc then begin
       ncdf_diminq, rem, ncdf_dimid(rem, 'Zone'),    dummy,  nz
       ncdf_diminq, rem, ncdf_dimid(rem, 'Channel'), dummy,  nchan
       spectra = ulonarr(nz, nchan)
       for record=maxloc, maxrem-1 do begin
           print, 'Appending record ' + strcompress(string(record), /remove_all) + ' to ' + locfile
;----------Read the exposure data from the SDI source file:
           ncdf_varget,  rem, ncdf_varid(rem, 'Spectra'),        spectra, offset=[0,0,record], $
                         count=[n_elements(spectra(*,0)), n_elements(spectra(0,*)), 1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Start_Time'),     stime, offset=[record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'End_Time'),       etime, offset=[record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Number_Scans'),   scanz, offset=[record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'X_Center'),       x_center, 			offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Y_Center'),       y_center, 			offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Nm_Per_Step'),    nm_per_step, 		offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Leg1_Start_Volt'),leg1_start_volt, 	offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Leg2_Start_Volt'),leg2_start_volt, 	offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Leg3_Start_Volt'),leg3_start_volt, 	offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Cam_Temp'),       cam_temp, 			offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Cam_Gain'),       cam_gain, 			offset = [record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Cam_Exptime'), 	 cam_exptime, 		offset = [record], count=[1]

;----------Write the exposure to the local destination file:
           ncdf_varput,  loc, ncdf_varid(loc, 'Spectra'),        spectra, offset=[0,0,record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Start_Time'),     stime,   offset=[record]
           ncdf_varput,  loc, ncdf_varid(loc, 'End_Time'),       etime,   offset=[record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Number_Scans'),   scanz,   offset=[record]

           ncdf_varput,  loc, ncdf_varid(loc, 'X_Center'),       x_center, 			offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Y_Center'),       y_center, 			offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Nm_Per_Step'),    nm_per_step, 		offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Leg1_Start_Volt'),leg1_start_volt, 	offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Leg2_Start_Volt'),leg2_start_volt, 	offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Leg3_Start_Volt'),leg3_start_volt, 	offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Cam_Temp'),       cam_temp, 			offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Cam_Gain'),       cam_gain, 			offset = [record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Cam_Exptime'), 	 cam_exptime, 		offset = [record]
           count = count + 1
           wait, 0.01
       endfor
    endif

    ncdf_close, rem
    ncdf_close, loc

end


;-------------------------------------------------------------------
;   This is the main program:

pro run_now

    print, 'Finding Files...'
    wait, 0.1
    empty
    jsnow  = dt_tm_tojs(systime(/utc))

    setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=AUTO'
    setenv, 'SDI_RED_ZERO_VELOCITY_FILE=AUTO'

    sdi3k_rt_build_filenames, skysrc, skydest, calsrc, caldest, semaphore, messages
    tlab = dt_tm_mak(js2jd(0d)+1, jsnow, format='Y$-n$-0d$, h$:m$:s$')
    start_tstamp =  'Real-time plot run began at ' + tlab + ' UT '

    sdi3k_rt_check_semaphore, semaphore

    print, 'Establish local files...'
    wait, 0.1
    empty
    sdi3k_rt_establish_local_files, skysrc, calsrc, skydest, caldest

    print, 'Update local files...'
    wait, 0.1
    empty

    newrex = intarr(n_elements(skydest))
    for j=0, n_elements(skysrc)-1 do begin
        sdi3k_rt_update_local_files, skysrc(j),   skydest(j), count
        newrex(j) = count
    endfor
    sdi3k_rt_update_local_files, calsrc, caldest

    print, 'Process...'
    wait, 0.1
    empty
    details = mc_fileparse(skydest)
    caldet  = mc_fileparse(caldest)
    for j=0, n_elements(skysrc)-1 do begin
        if newrex(j) gt 0 or strupcase(getenv('SDI3K_FORCE_REALTIME_PLOT_UPDATE') eq 'YES') then begin
           sdi3k_batch_autoprox, path=details(j).path, filter=[details(j).namepart, caldet.namepart], $
                                 calfit='new', skyfit='new', windfit='all', plotting='all', $
                                 lookback_seconds=1L*86400L, plot_folder='RealTime', drift='data'
           sdi3k_batch_plot_latest_spex, skydest(j)
        endif
    endfor
    spawn, 'del ' + semaphore
    jsnow = dt_tm_tojs(systime(/UTC))
    tlab = dt_tm_mak(js2jd(0d)+1, jsnow, format='Y$-n$-0d$, h$:m$:s$')
    openw, mlun, messages, /get_lun
    printf, mlun, start_tstamp +  'and ended at ' + tlab + ' UT.'
    printf, mlun, " "
    close, mlun
    free_lun, mlun
    xx = mc_fileparse(messages)
    spawn, 'del ' + xx.path + xx.name_only + '.txt'
    spawn, 'rename ' + messages + ' SDI_realtime_plot_log.txt'
    print, 'Done!'
end