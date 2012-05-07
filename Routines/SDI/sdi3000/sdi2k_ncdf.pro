;===============================================================================
;  This is a generic netcdf log file open routine for for the sdi2000 programs:
pro sdi2k_open_logging, otype
@sdi2kinc.pro
    if host.operation.logging.enable_logging eq 0 then begin
       if host.operation.logging.logging_off_alarm then begin
          sdi2k_user_message, ">>>Error: Request to open a log file failed; logging is disabled", /beep
       endif
       return
    endif
    vid     = strupcase(strcompress(otype, /remove_all)) eq 'INS'
    file    = sdi2k_filename(otype)
    flis    = findfile(file)
    exists  = flis(0) ne ''
    if host.operation.logging.log_overwrite then begin
       sdi2k_ncdf_create, file, ncid
    endif else begin
       if exists then sdi2k_ncopen,      file, ncid, vid  $
                 else sdi2k_ncdf_create, file, ncid, vid
    endelse
    host.operation.header.file_specifier = file

;---Create a note input widget, if we succeeded in opening a netcdf file.
;   First, do not proceed if we already have a note widget:
    wid_pool, 'sdi2k_widget_note', widget_note, /get
    if widget_info(widget_note, /valid) then return
    if ncid ge 0 then begin
       wid_pool, 'sdi2k_widget_nbase', note_base, /get
       widget_note = cw_field(note_base, font=host.controller.behavior.menu_font, $
                                        /return_events, /string, title='User note: ', xsize=55)
       wid_pool, 'sdi2k_widget_note', widget_note, /add
    endif
end

;========================================================================
;  Close any open netCDF files:
pro sdi2k_ncdf_close
@sdi2kinc.pro
    for j=0,n_elements(host.netcdf)-1 do begin
        if host.netcdf(j).ncid ne -1 then begin
           ncdf_close, host.netcdf(j).ncid
           host.netcdf(j).ncid = -1
        endif
    endfor
    wid_pool, 'sdi2k_widget_note', widx, /destroy
    host.operation.header.file_specifier = 'None'
end


;========================================================================
;  Open an existing netCDF logfile:
pro sdi2k_ncopen, file, ncid, vid
@sdi2kinc.pro

;------Check if we have an IDL save file rather than a netcdf file:
       fparse = mc_fileparse(file)

       if strpos(strupcase(fparse.extension), '.DAT') gt 0 then sdi2k_savefile_open, file, ncid, vid
       if strpos(strupcase(fparse.extension), '.DAT') gt 0 then return

       ncdf_control, 0, /verbose
       ncrecord  = 0

;------Try to open an existing file:
       ncid = -1
       host.netcdf(vid).ncid = ncid
       host.netcdf(vid).ncid = ncdf_open (file, /write)
       if host.netcdf(vid).ncid eq -1 then begin
          sdi2k_user_message, '>>>Error: Request to open existing log file ' + file + ' failed', /beep
          return
       endif

;------This is a bug workaround:
  ncdf_control, host.netcdf(vid).ncid, /verbose
  ncdf_control, host.netcdf(vid).ncid, /sync
  tries = 0

f1:
  tries = tries + 1
  on_error, 3
  on_ioerror, f1x

  ncdf_control, host.netcdf(vid).ncid, /redef
  goto, f1y
f1x:
  ncdf_control, host.netcdf(vid).ncid, /abort
  wait, 0.01
  host.netcdf(vid).ncid = ncdf_open (file, /write)
  if tries gt 200 then begin
     ncid = -1
     host.netcdf(vid).ncid = ncid
     return
  endif
  goto, f1


f1y:
  ncdf_control, host.netcdf(vid).ncid, /endef
  ncdf_control, host.netcdf(vid).ncid, /sync

       sdi2k_user_message, 'Opened existing log file: ' + file
       ncid = host.netcdf(vid).ncid

		nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
        	rname = 'Rings'
        	radii = 'Zone_Radii'
        	sectr = 'Zone_Sectors'
        	gap   = 'Gap'
        	rfov  = 'Rings2'
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'XDim'),    dummy,  xdim
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'YDim'),    dummy,  ydim
			host.hardware.video.columns = xdim
			host.hardware.video.rows = ydim
			view = uintarr(xdim, ydim)
        endif else begin
        	rname = 'Ring'
        	radii = 'Ring_Radii'
        	sectr = 'Sectors'
        	gap   = 'Plate_Spacing'
			rfov  = 'Rings2'
        endelse

;------Get dimension sizes:
       dummy = 'Return Name'
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nzones
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
       ncdf_diminq, ncid, ncdf_dimid(ncid,  rname),    dummy,  nrings
       host.netcdf(vid).ncmaxrec           = maxrec
       host.netcdf(vid).ncnzones           = nzones
       host.hardware.etalon.scan_channels  = nchan
       host.operation.zones.fov_rings      = nrings
       fovr = nrings - 1

       mc_nc_varget, ncid, ['Ring_Radii', 'Zone_Radii'], radii, intarr(fovr), 0, fovr
       if max(radii) lt 2. then radii = radii * 100

;------Get information regarding times, if the existing file has any:
       if maxrec gt 0 then begin
          ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'),           stime,   offset=(0), count=(1)
          ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),             etime,   offset=(maxrec-1), count=(1)
          host.netcdf(vid).ncstime                   = stime
          host.netcdf(vid).ncetime                   = etime
       endif

;------Get static variables:
       fovr = nrings - 1
       if nc_desc.ndims ge 7 or nrings gt 5 then begin
;          ncdf_varget, ncid, ncdf_varid(ncid, rfov),        	  fovr,    offset=0, count=1
;          ncdf_varget, ncid, ncdf_varid(ncid,  radii),           radii,   offset=0, count=fovr
          ncdf_varget, ncid, ncdf_varid(ncid, 'X_Center'),             xcen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Y_Center'),             ycen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Gap'),                  gap,     offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Nm_Per_Step'),          nmps,    offset=0, count=1
       endif else  begin
 ;         ncdf_varget, ncid, ncdf_varid(ncid, radii),           radii,   offset=0, count=fovr
          ncdf_varget, ncid, ncdf_varid(ncid, 'Plate_Spacing'),                  gap,     offset=0, count=1
          xcen = 128
          ycen =128
          nmps = .8
       endelse
       ncdf_varget, ncid, ncdf_varid(ncid, sectr),              sectors, offset=0, count=fovr
       mc_nc_varget, ncid, 'Start_Spacing',         strtspc, 0.,     0, 1
       mc_nc_varget, ncid, 'Gap_Refractive_Index',  refidx , 1.,     0, 1
       mc_nc_varget, ncid, ['Sky_Wavelength', 'Wavelength'], lamsky,  630.03, 0, 1
       mc_nc_varget, ncid, ['Cal_Wavelength', 'Wavelength'], lamcal, 632.8, 0, 1
       mc_nc_varget, ncid, 'Cal_Temperature',       caltemp, 300.,   0, 1
       mc_nc_varget, ncid, 'Sky_Mass',              skymass, 16.,    0, 1
       mc_nc_varget, ncid, 'Cal_Mass',              calmass, 10.,    0, 1
       mc_nc_varget, ncid, 'Sky_Ref_Finesse',       skynr,   20.,    0, 1
       mc_nc_varget, ncid, 'Cal_Ref_Finesse',       calnr,   20.,    0, 1
       mc_nc_varget, ncid, 'Sky_FOV',               fov,     75.,    0, 1

       host.operation.zones.ring_radii            = radii
       host.operation.zones.sectors               = sectors
       host.operation.zones.fov_rings             = fovr
       host.operation.zones.x_center              = xcen
       host.operation.zones.y_center              = ycen
       host.hardware.etalon.gap                   = gap
       host.hardware.etalon.start_spacing         = strtspc
       host.hardware.etalon.scan_channels         = nchan
       host.hardware.etalon.nm_per_step           = nmps
       host.hardware.etalon.gap_refractive_index  = refidx
       host.operation.calibration.sky_wavelength  = lamsky
       host.operation.calibration.cal_wavelength  = lamcal
       host.operation.calibration.cal_temperature = caltemp
       host.operation.calibration.sky_mass        = skymass
       host.operation.calibration.cal_mass        = calmass
       host.operation.calibration.sky_ref_finesse = skynr
       host.operation.calibration.cal_ref_finesse = calnr
       host.operation.calibration.sky_fov         = fov

;------Get global attributes:

       mc_glob_attget, ncid, 'Site', site, 'Poker Flat'
       mc_glob_attget, ncid, ['Site_Code', 'Site_code'], sitecd, 'PKR'
       mc_glob_attget, ncid, ['Start_Day_UT', 'Start Day UT'], doy, 0L
       mc_glob_attget, ncid, 'Year', year, dt_tm_mak(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$')
       mc_glob_attget, ncid, 'Longitude', lon, -150.
       mc_glob_attget, ncid, 'Latitude',  lat,  65.
       mc_glob_attget, ncid, 'Operator',  oper, -150.
       mc_glob_attget, ncid, 'Comment',   cmt,  'None'

       host.operation.header.site      = string(site)
       host.operation.header.site_code = string(sitecd)
       host.operation.header.doy       = string(doy)
       host.operation.header.year      = string(year)
       host.operation.header.longitude = lon
       host.operation.header.latitude  = lat
       host.operation.header.operator  = string(oper)
       host.operation.header.comment   = string(cmt)

;------Read the notes back from the file:
       for i=0,n_elements(host.operation.header.notes)-1 do begin
           mc_glob_attget, ncid, 'Note_' + string(i, format='(i2.2)'),   note,  'None'
           host.operation.header.notes(i) = string(note)
       endfor
bugfix:
;------Save netcdf descriptors:
       host.netcdf(vid).ncrecord = host.netcdf(vid).ncmaxrec
       host.netcdf(vid).ncid     = ncid
       host.netcdf(vid).ncnzones = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
       end


;========================================================================
;  This routine tries to read an attribute, based on a list of possible names:
pro   mc_nc_varget, ncid, namelist, targetvar, default, offset, count
		targetvar = default
		for j = 0, n_elements(namelist)-1 do begin
			id = NCDF_VARID(ncid, namelist(j))
			if id ge 0 then ncdf_varget, ncid, ncdf_varid(ncid, namelist(j)), targetvar, offset=offset, count=count
		endfor
end

;========================================================================
;  This routine tries to read an attribute, based on a list of possible names:
pro   mc_glob_attget, ncid, namelist, targetvar, default
		targetvar = default
		for j = 0, n_elements(namelist)-1 do begin
			desc = NCDF_ATTINQ( ncid,  namelist(j), /GLOBAL)
			if desc.datatype ne 'UNKNOWN' then ncdf_attget, ncid, namelist(j), targetvar, /GLOBAL
		endfor
end



;========================================================================
;  Open an existing IDL save file:
pro  sdi2k_savefile_open, file, ncid, vid
common savefile_vars, sky, las, images
@sdi2kinc.pro

       restore, file
       sdi2k_user_message, 'Opened existing log file: ' + file

       if n_elements(vid) eq 0 then begin
          vid = 0
          spex = sky
       endif else begin
          case vid of
               0: spex = sky
               1: spex = las
               else: begin
                     mcchoice, 'Which Spectra:', ['Sky', 'Laser'], choice
                     if choice.index eq 0 then spex = sky else spex = las
                     vid = 0
               endelse
          endcase
       endelse
       maxrec = n_elements(spex.start_time)

;------Get dimension sizes:
       dummy = 'Return Name'
       host.netcdf(vid).ncmaxrec           = spex.nexps
       host.netcdf(vid).ncnzones           = spex.nzones
       host.hardware.etalon.scan_channels  = spex.nchann
       host.operation.zones.fov_rings      = n_elements(spex.rads)-1

;------Get information regarding times, if the existing file has any:
       if spex.nexps gt 0 then begin
          host.netcdf(vid).ncstime                   = spex.start_time(0)
          host.netcdf(vid).ncetime                   = spex.end_time(maxrec-1)
       endif
;------Get static variables:
       host.operation.zones.ring_radii            = 100*spex.rads(1:host.operation.zones.fov_rings)
       host.operation.zones.sectors               = spex.secs
       host.operation.zones.x_center              = sky.xcen(0) - 256 + n_elements(view(*,0))/2
       host.operation.zones.y_center              = sky.ycen(0) - 256 + n_elements(view(0,*))/2
       host.hardware.etalon.gap                   = 25
       host.hardware.etalon.start_spacing         = 0
       host.hardware.etalon.scan_channels         = spex.nchann
       host.hardware.etalon.nm_per_step           = spex.nm_per_step(0)
       host.hardware.etalon.gap_refractive_index  = 1.
       host.operation.calibration.sky_wavelength  = sky.wavelength
       host.operation.calibration.cal_wavelength  = las.wavelength
       host.operation.calibration.cal_temperature = 0.
       host.operation.calibration.sky_mass        = 16.
       host.operation.calibration.cal_mass        = 20.
       host.operation.calibration.sky_ref_finesse = 25. ; ### Dummy guess
       host.operation.calibration.cal_ref_finesse = 20. ; ### Dummy guess
       host.operation.calibration.sky_fov         = max(sky.zen_ang)

;------Get global attributes:

       host.operation.header.site      = 'Mawson'
       host.operation.header.site_code = 'maw'
       host.operation.header.doy       = dt_tm_mak(js2jd(0d)+1, spex.start_time(0), format='doy$')
       host.operation.header.year      = dt_tm_mak(js2jd(0d)+1, spex.start_time(0), format='Y$')
       host.operation.header.longitude = spex.lon
       host.operation.header.latitude  = spex.lat
       host.operation.header.operator  = 'Callum'
       host.operation.header.comment   = 'No Comment'


;------Save netcdf descriptors:
       ncid = -99
       host.netcdf(vid).ncrecord = host.netcdf(vid).ncmaxrec
       host.netcdf(vid).ncid     = ncid
       host.netcdf(vid).ncnzones = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
       end


;========================================================================
; Create a new netCDF log file:
pro sdi2k_ncdf_create, file, ncid, vid, nospex=nospex, not_now=not_now
@sdi2kinc.pro

       ncdf_control, 0, /verbose
       host.netcdf(vid).ncrecord = 0

;------Open a new file:
       ncid = -1
       host.netcdf(vid).ncid = ncid
       host.netcdf(vid).ncid = ncdf_create (file, clobber=host.operation.logging.log_overwrite)
       if host.netcdf(vid).ncid eq -1 then begin
          sdi2k_user_message, '>>>Error: Request to create new log file ' + file + ' failed', /beep
          return
       endif else sdi2k_user_message, 'Created new log file: ' + file
       ncid = host.netcdf(vid).ncid

;------Create the dimensions:
       tid = ncdf_dimdef (ncid, "Time",    /unlimited)
       zid = ncdf_dimdef (ncid, "Zone",    total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       cid = ncdf_dimdef (ncid, "Channel", host.hardware.etalon.scan_channels)
       rid = ncdf_dimdef (ncid, "Ring",    host.operation.zones.fov_rings)

;------Create the variables:
       id = ncdf_vardef  (ncid, "Start_Time",      tid, /long)
       id = ncdf_vardef  (ncid, "End_Time",        tid, /long)
       if not(keyword_set(nospex)) then id = ncdf_vardef  (ncid, "Spectra",        [zid, cid, tid], /long)
       id = ncdf_vardef  (ncid, "Number_Summed",   tid, /short)
       id = ncdf_vardef  (ncid, "FOV_Rings",            /byte)
       id = ncdf_vardef  (ncid, "Ring_Radii",      rid, /float)
       id = ncdf_vardef  (ncid, "Sectors",         rid, /byte)
       id = ncdf_vardef  (ncid, "X_Center",             /float)
       id = ncdf_vardef  (ncid, "Y_Center",             /float)
       id = ncdf_vardef  (ncid, "Gap",                  /float)
       id = ncdf_vardef  (ncid, "Start_Spacing",        /short)
       id = ncdf_vardef  (ncid, "Channel_Spacing",      /float)
       id = ncdf_vardef  (ncid, "Nm_Per_Step",          /float)
       id = ncdf_vardef  (ncid, "Scan_Channels",        /short)
       id = ncdf_vardef  (ncid, "Gap_Refractive_Index", /float)
       id = ncdf_vardef  (ncid, "Sky_Wavelength",       /float)
       id = ncdf_vardef  (ncid, "Cal_Wavelength",       /float)
       id = ncdf_vardef  (ncid, "Cal_Temperature",      /float)
       id = ncdf_vardef  (ncid, "Sky_Mass",             /float)
       id = ncdf_vardef  (ncid, "Cal_Mass",             /float)
       id = ncdf_vardef  (ncid, "Sky_Ref_Finesse",      /float)
       id = ncdf_vardef  (ncid, "Cal_Ref_Finesse",      /float)
       id = ncdf_vardef  (ncid, "Sky_FOV",              /float)

;------Describe the units of each variable:
       ncdf_attput, ncid, ncdf_varid(ncid, "Start_Time"),           "Units", "Seconds since 00 UT on January 1, 2000", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "End_Time"),             "Units", "Seconds since 00 UT on January 1, 2000", /char
       if not(keyword_set(nospex)) then ncdf_attput, ncid, ncdf_varid(ncid, "Spectra"),              "Units", "Camera digital units", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Number_Summed"),        "Units", "Etalon scans", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "FOV_Rings"),            "Units", "Number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Ring_Radii"),           "Units", "Percent of field-of-view", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sectors"),              "Units", "Sectors per ring", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "X_Center"),             "Units", "Image pixel number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Y_Center"),             "Units", "Image pixel number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Gap"),                  "Units", "mm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Start_Spacing"),        "Units", "Scan steps", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Channel_Spacing"),      "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Nm_Per_Step"),          "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Scan_Channels"),        "Units", "Etalon steps per interference order", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Gap_Refractive_Index"), "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Wavelength"),       "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Wavelength"),       "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Temperature"),      "Units", "Kelvin", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Mass"),             "Units", "AMU", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Mass"),             "Units", "AMU", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Ref_Finesse"),      "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Ref_Finesse"),      "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_FOV"),              "Units", "Degrees 1/2 angle, from zenith", /char

;------Save some global attributes:
       if keyword_set(not_now) then begin
          ncdf_attput, ncid, "Start_Day_UT", host.operation.header.doy,  /char, /global
          ncdf_attput, ncid, "Year",         host.operation.header.year, /char, /global
       endif else begin
          ncdf_attput, ncid, "Start_Day_UT", dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='doy$'), /char, /global
          ncdf_attput, ncid, "Year",         dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$'), /char, /global
       endelse
       ncdf_attput, ncid, "Site",      host.operation.header.site, /char, /global
       ncdf_attput, ncid, "Site_Code", host.operation.header.site_code, /char, /global
       ncdf_attput, ncid, "Operator",  host.operation.header.operator, /char, /global
       ncdf_attput, ncid, "Latitude",  host.operation.header.latitude, /float, /global
       ncdf_attput, ncid, "Longitude", host.operation.header.longitude, /float, /global
       ncdf_attput, ncid, "Comment",   host.operation.header.comment, /char, /global
       ncdf_attput, ncid, "Software",  host.operation.header.software, /char, /global

;------Enter some notes, which can be over-written with other information later, if need be:
       for i=0,n_elements(host.operation.header.notes)-1 do begin
           ncdf_attput, ncid, 'Note_' + string(i, format='(i2.2)'), host.operation.header.notes(i), /char, /global
       endfor

;------Write the static variables now:
       ncdf_control,ncid, /endef
       ncdf_varput, ncid, ncdf_varid(ncid, 'X_Center'),              host.operation.zones.x_center
       ncdf_varput, ncid, ncdf_varid(ncid, 'Y_Center'),              host.operation.zones.y_center
       ncdf_varput, ncid, ncdf_varid(ncid, 'Gap'),                   host.hardware.etalon.gap
       ncdf_varput, ncid, ncdf_varid(ncid, 'Start_Spacing'),         host.hardware.etalon.start_spacing
       ncdf_varput, ncid, ncdf_varid(ncid, 'Channel_Spacing'),       host.hardware.etalon.nm_per_step*host.hardware.etalon.scan_gain
       ncdf_varput, ncid, ncdf_varid(ncid, 'Nm_Per_Step'),           host.hardware.etalon.nm_per_step
       ncdf_varput, ncid, ncdf_varid(ncid, 'Scan_Channels'),         host.hardware.etalon.scan_channels
       ncdf_varput, ncid, ncdf_varid(ncid, 'Gap_Refractive_Index'),  host.hardware.etalon.gap_refractive_index
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Wavelength'),        host.operation.calibration.sky_wavelength
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Wavelength'),        host.operation.calibration.cal_wavelength
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Temperature'),       host.operation.calibration.cal_temperature
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Mass'),              host.operation.calibration.sky_mass
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Mass'),              host.operation.calibration.cal_mass
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Ref_Finesse'),       host.operation.calibration.sky_ref_finesse
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Ref_Finesse'),       host.operation.calibration.cal_ref_finesse
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_FOV'),               host.operation.calibration.sky_fov
       ncdf_varput, ncid, ncdf_varid(ncid, 'FOV_Rings'),             host.operation.zones.fov_rings
       ncdf_varput, ncid, ncdf_varid(ncid, 'Ring_Radii'),            host.operation.zones.ring_radii(0:host.operation.zones.fov_rings-1)
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sectors'),               host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)

;------Force a commit to disk of the current file data:
       ncdf_control, ncid, /sync
end


;========================================================================
;  This routine adds a new note to the log file:
pro sdi2k_ncdf_putnote, note=note
@sdi2kinc.pro
    if not(keyword_set(note)) then begin
       wid_pool, 'sdi2k_widget_note', widget_note, /get
       widget_control, widget_note, get_value=user_note
       widget_control, widget_note, set_value=' '
    endif else user_note=note
    vid  = strupcase(strcompress(host.programs.spectra.observation_type, /remove_all)) eq 'INS'

    if host.netcdf(vid).ncid eq -1 then begin
       sdi2k_user_message, 'No NetCDF file. Failed to add note: ' + user_note
       return
    endif

    nnum = 0
    ncdf_attget, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    while strpos(note, '          ') ne 0 do begin
       nnum = nnum + 1
       ncdf_attget, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    endwhile
    tstr = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
    ncdf_attput, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), tstr + ' - ' + user_note, /char, /global
    sdi2k_user_message, 'Added Note ' +  strcompress(string(nnum+1), /remove_all) + ': ' + user_note
    host.operation.header.notes(nnum) = tstr + ' - ' + user_note
end

;======================================================================
;  This procedure checks if a variable is already defined in a netCDF
;  file and, if not, adds it to the file.

pro sdi2k_addvar, ncid, vname, dimids, units, status, byte=bt, char=ch, short=sh, $
                  long=lg, float=fl, double=db

       trycount = 0
addvar_entry:
       trycount = trycount + 1
    on_error, 3
       on_ioerror, addvar_trubble
       status = "Failure"

       ncdf_control, ncid, /noverbose
       id = ncdf_varid(ncid, vname)
       ncdf_control, ncid, /verbose

       if id ge 0 then return

       print, "Adding Variable: ", vname, ", with units of: ", units
       ncdf_control, ncid, /redef
       if (keyword_set(bt)) then $
           id = ncdf_vardef(ncid, vname, dimids, /byte)
       if (keyword_set(ch)) then $
           id = ncdf_vardef(ncid, vname, dimids, /char)
       if (keyword_set(sh)) then $
           id = ncdf_vardef(ncid, vname, dimids, /short)
       if (keyword_set(lg)) then $
           id = ncdf_vardef(ncid, vname, dimids, /long)
       if (keyword_set(fl)) then $
           id = ncdf_vardef(ncid, vname, dimids, /float)
       if (keyword_set(db)) then $
           id = ncdf_vardef(ncid, vname, dimids, /double)
       ncdf_attput, ncid, id, 'Units', units
       ncdf_control, ncid, /endef
    status = "Success"
addvar_trubble:
       if status ne "Success" then help, !ERROR_STATE, /struc
       if status ne "Success" and trycount lt 50 then goto, addvar_entry
end

;=============================================================================
;  This procedure adds variables to the netCDF logfile to store the
;  results of peak fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi2k_add_fitvars, ncid

       if ncid eq -99 then return
       ncdf_control, ncid, /fill, oldfill=nc_nodata
       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')

       sdi2k_addvar, ncid, 'Peak_Position',   [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Peak_Width',      [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Peak_Area',       [zoneid, timeid], $
                           'Signal Counts',   /float
       sdi2k_addvar, ncid, 'Background',      [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi2k_addvar, ncid, 'Sigma_Position',  [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Sigma_Width',     [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Sigma_Area',      [zoneid, timeid], $
                           'Signal Counts',   /float
       sdi2k_addvar, ncid, 'Sigma_Bgnd',      [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi2k_addvar, ncid, 'Chi_Squared',     [zoneid, timeid], $
                           'Dimensionless',   /float
       sdi2k_addvar, ncid, 'Signal_to_Noise', [zoneid, timeid], $
                           'Dimensionless',   /float

       ncdf_control, ncid, /noverbose
       attstat = ncdf_attinq(ncid, 'Peak Fitting Time', /global)
       ncdf_control, ncid, /verbose

       trycount = 0
       outcome = 'fail'
ATTRIB_ADDER:
       if attstat.datatype eq 'UNKNOWN' then begin
          trycount = trycount + 1
          on_error, 3
          on_ioerror, ATTRIB_TRUBBLE
          ncdf_control, ncid, /redef
          outcome = 'ok'
          nowtime = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
          ncdf_attput, ncid, 'Peak Fitting Time', nowtime, /global
          ncdf_attput, ncid, 'Peak Fitting Routine', $
                             'IDL sdi2000 suite', /global
          ncdf_control, ncid, /fill, oldfill=nc_nodata
          ncdf_control, ncid, /endef
       endif else return
ATTRIB_TRUBBLE:
        if outcome ne 'ok' and trycount lt 50 then goto, ATTRIB_ADDER

end

;========================================================================
;  This routine appends the results of the latest fit to the netCDF data
;  file:

pro sdi2k_write_fitpars, ncid, record, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                                       backgrounds, areas, widths, positions, savefile=sf
@sdi2kinc.pro
common savefile_vars, sky, las, images

    if not(keyword_set(sf)) then sf = {name: 'xx', type: 'ncdf'}
    if sf.type eq 'ncdf' then begin
       ncdf_control, ncid, /sync

       ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Width'),        widths,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Width'),       sigwid,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  record]
       ncdf_control, ncid, /sync
    endif else begin
       if sf.type eq 'sky' then begin
          sky.pkpos(*, record)      = positions
          sky.sigpos(*, record)     = sigpos
          sky.width(*, record)      = widths
          sky.sigwid(*, record)     = sigwid
          sky.area(*, record)       = areas
          sky.sigarea(*, record)    = sigarea
          sky.background(*, record) = backgrounds
          sky.sigback(*, record)    = sigbgnd
          sky.sig2noise(*, record)  = sig2noise
          sky.chisq(*, record)      = chi_squared
       endif else begin
          las.pkpos(*, record)      = positions
          las.sigpos(*, record)     = sigpos
          las.width(*, record)      = widths
          las.sigwid(*, record)     = sigwid
          las.area(*, record)       = areas
          las.sigarea(*, record)    = sigarea
          las.background(*, record) = backgrounds
          las.sigback(*, record)    = sigbgnd
          las.sig2noise(*, record)  = sig2noise
          las.chisq(*, record)      = chi_squared
       endelse
       save, sky, las, images, filename=sf.name
    endelse
end

pro sdi2k_read_fitpars, ncid, record, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                                      backgrounds, areas, widths, positions
@sdi2kinc.pro
    if ncid ne -99 then begin
       ncdf_control, ncid, /sync

       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nz
       ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Width'),        widths,      offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Width'),       sigwid,      offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  record], count=[nz, 1]
       ncdf_varget, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  record], count=[nz, 1]
       ncdf_control, ncid, /sync
    endif else begin
       positions   = spex.pkpos(*, record)
       sigpos      = spex.sigpos(*, record)
       widths      = spex.width(*, record)
       sigwid      = spex.sigwid(*, record)
       areas       = spex.area(*, record)
       sigarea     = spex.sigarea(*, record)
       backgrounds = spex.background(*, record)
       sigbgnd     = spex.sigback(*, record)
       sig2noise   = spex.sig2noise(*, record)
       chi_squared = spex.chisq(*, record)
    endelse
end

pro sdi2k_build_fitres, ncid, resarr
@sdi2kinc.pro
    if ncid ne -99 then ncdf_control, ncid, /sync
;    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
;    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nz
;    ncdf_varget, ncid, ncdf_varid(ncid, 'Scan_Channels'),        nchan,   offset=0, count=1
    if ncid ne -99 then ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec else maxrec = spex.nexps
    nchan  = host.hardware.etalon.scan_channels
    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    record = 0
    for rec=record,maxrec-1 do begin
        sdi2k_read_fitpars, ncid, rec, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                            backgrounds, areas, widths, positions
        if ncid ne -99 then begin
           ncdf_varget,  ncid, ncdf_varid(ncid, 'Start_Time'),    stime, offset=[rec], count=[1]
           ncdf_varget,  ncid, ncdf_varid(ncid, 'End_Time'),      etime, offset=[rec], count=[1]
		   mc_nc_varget, ncid, ['Number_Summed', 'Number_Scans'], scanz, 1, [record], [1]
        endif else begin
           stime = spex.start_time(rec)
           etime = spex.end_time(rec)
           scanz = spex.nscans(rec)
        endelse
;        resrec =           {s_resrec, record: rec, $
        resrec =           {record: rec, $
                        start_time: double(stime), $
                          end_time: double(etime), $
                     number_summed: scanz, $
                          velocity: positions, $
                       temperature: widths, $
                         intensity: areas, $
                        background: backgrounds, $
                       msis_height: widths - 9e9, $
             characteristic_energy: widths -9e9, $
                    sigma_velocity: sigpos, $
                 sigma_temperature: sigwid, $
                 sigma_intensities: sigarea, $
                  sigma_background: sigbgnd, $
                      signal2noise: sig2noise, $
                       chi_squared: chi_squared, $
                 units_temperature: 'K', $
                    units_velocity: 'm/s', $
                 units_msis_height: 'km', $
       units_characteristic_energy: 'keV'}

;                        zonal_wind: fltarr(nz), $
;                   meridional_wind: fltarr(nz), $
;                 wind_coefficients: fltarr(6), $
       if n_elements(resarr) eq 0 then resarr = resrec else resarr = [resarr, resrec]
    endfor
;---The following code removes "wrapped" orders in the peak fitting:
    posarr = resarr.velocity
    goods = where(abs(posarr) lt 1e4)
    cenpos = median(posarr(goods))
    nbad   = 1

    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr gt cenpos + nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) - nchan
          tries = tries + 1
    endwhile
    tries = 0
    nbad   = 1
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr lt cenpos - nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) + nchan
          tries = tries + 1
    endwhile
;---A second iteration of unwrapping, in case the median got changed by too much:
    goods = where(abs(posarr) lt 1e4)
    cenpos = median(posarr(goods))
    nbad   = 1
    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr gt cenpos + nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) - nchan
          tries = tries + 1
    endwhile
    nbad   = 1
    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr lt cenpos - nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) + nchan
          tries = tries + 1
    endwhile
    resarr.velocity = posarr
end

;=============================================================================
;  This procedure adds variables to the netCDF logfile to store the
;  results of peak fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi2k_add_windvars, ncid, windfit, wind_settings
@sdi2kinc.pro

       ncnrings = host.operation.zones.fov_rings
       ncdf_control, ncid, /fill, oldfill=nc_nodata

		nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
        	rname = 'Rings'
        	radii = 'Zone_Radii'
        	sectr = 'Zone_Sectors'
        	gap   = 'Gap'
        	rfov  = 'Rings2'
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'XDim'),    dummy,  xdim
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'YDim'),    dummy,  ydim
			host.hardware.video.columns = xdim
			host.hardware.video.rows = ydim
			view = uintarr(xdim, ydim)
        endif else begin
        	rname = 'Ring'
        	radii = 'Ring_Radii'
        	sectr = 'Sectors'
        	gap   = 'Plate_Spacing'
			rfov  = 'Rings2'
        endelse

       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')
       ringid = ncdf_dimid(ncid, rname)


       sdi2k_addvar, ncid, 'Zonal_Wind',      [zoneid, timeid], $
                           'Horizontal m/s, mag eastward +ve',   /float
       sdi2k_addvar, ncid, 'Meridional_Wind', [zoneid, timeid], $
                           'Horizontal m/s, mag northward +ve',   /float
       sdi2k_addvar, ncid, 'Fitted_LOS_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve away',   /float
       sdi2k_addvar, ncid, 'Fitted_Perpendicular_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve left seen from above',   /float
       sdi2k_addvar, ncid, 'Vertical_Wind',   [timeid], $
                           'm/s, +ve up',   /float
       sdi2k_addvar, ncid, 'U_0',             [ringid, timeid], $
                           'm/s, mag eastward +ve',   /float
       sdi2k_addvar, ncid, 'V_0',             [ringid, timeid], $
                           'm/s, mag northward +ve',   /float

       sdi2k_addvar, ncid, 'du_dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'du_dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'dv_dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'dv_dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'Wind_Chi_Squared',   [timeid], $
                           'Dimensionless',   /float
       sdi2k_addvar, ncid, 'Zone_Azimuths',     [zoneid], $
                           'Degrees east from geographic north',   /float
       sdi2k_addvar, ncid, 'Zone_Zenith_Angles',     [zoneid], $
                           'Degrees from geographic zenith',   /float
       sdi2k_addvar, ncid, 'Zone_Latitudes',     [zoneid], $
                           'Degrees north geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Longitudes',     [zoneid], $
                           'Degrees east geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Meridional_Distances',     [zoneid], $
                           'Meters north geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Zonal_Distances',     [zoneid], $
                           'Meters east geographic',   /float
       sdi2k_addvar, ncid, 'Time_Smoothing',    [timeid], $
                           '1/e half-width in exposure numbers',   /float
       sdi2k_addvar, ncid, 'Spatial_Smoothing',    [timeid], $
                           '1/e half-width in percent of FOV',   /float

       ncdf_control, ncid, /noverbose
       attstat = ncdf_attinq(ncid, 'Wind_Fitting_Time', /global)
       ncdf_control, ncid, /verbose

       trycount = 0
       outcome = 'fail'
WINDATT_ADDER:

       trycount = trycount + 1
       if attstat.datatype eq 'UNKNOWN' then begin
          on_error, 3
          on_ioerror, WINDATT_ERR
          ncdf_control, ncid, /redef
          outcome = 'ok'
          nowtime = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
          ncdf_attput, ncid, 'Wind_Fitting_Time', nowtime, /global
          ncdf_attput, ncid, 'Wind_Fitting_Routine', $
                             'IDL_sdi2000_suite', /global
          ncdf_attput, ncid, 'Wind_Fitting_Method', $
                             wind_settings.algorithm, /global
          ncdf_attput, ncid, 'Wind_Fitting_Assumption', $
                             wind_settings.dvdx_assumption, /global
          ncdf_attput, ncid, 'Assumed_Emission_Height_for_Wind_Fit', $
                             wind_settings.assumed_height, /global
          ncdf_attput, ncid, 'Geographic_azimuth_of_magnetic_north', $
                             '28.5_degrees', /global
          ncdf_control, ncid, /fill, oldfill=nc_nodata
          ncdf_control, ncid, /endef
       endif
WINDATT_ERR:
        if outcome ne 'ok' and trycount lt 50 then goto, WINDATT_ADDER

on_ioerror, NULL
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zonal_Wind'),                windfit.zonal_wind
       ncdf_varput, ncid, ncdf_varid(ncid, 'Meridional_Wind'),           windfit.meridional_wind
       ncdf_varput, ncid, ncdf_varid(ncid, 'Vertical_Wind'),             windfit.vertical_wind
       ncdf_varput, ncid, ncdf_varid(ncid, 'Fitted_LOS_Wind'),           windfit.fitted_los_wind
       ncdf_varput, ncid, ncdf_varid(ncid, 'Fitted_Perpendicular_Wind'), windfit.fitted_perpendicular_wind
       ncdf_varput, ncid, ncdf_varid(ncid, 'U_0'),                       transpose(windfit.u_zero)
       ncdf_varput, ncid, ncdf_varid(ncid, 'V_0'),                       transpose(windfit.v_zero)
       ncdf_varput, ncid, ncdf_varid(ncid, 'du_dx'),             transpose(windfit.dudx)
       ncdf_varput, ncid, ncdf_varid(ncid, 'du_dy'),             transpose(windfit.dudy)
       ncdf_varput, ncid, ncdf_varid(ncid, 'dv_dx'),             transpose(windfit.dvdx)
       ncdf_varput, ncid, ncdf_varid(ncid, 'dv_dy'),             transpose(windfit.dvdy)
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Azimuths'),             windfit.azimuths
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Zenith_Angles'),        windfit.zeniths
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Latitudes'),            windfit.zone_latitudes
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Longitudes'),           windfit.zone_longitudes
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Meridional_Distances'), windfit.meridional_distances
       ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Zonal_Distances'),      windfit.zonal_distances
       ncdf_varput, ncid, ncdf_varid(ncid, 'Wind_Chi_Squared'),          windfit.reduced_chi_squared
       ncdf_varput, ncid, ncdf_varid(ncid, 'Time_Smoothing'),            replicate(wind_settings.time_smoothing,  n_elements(windfit.reduced_chi_squared))
       ncdf_varput, ncid, ncdf_varid(ncid, 'Spatial_Smoothing'),         replicate(wind_settings.space_smoothing, n_elements(windfit.reduced_chi_squared))
end

;=============================================================================
pro sdi2k_windget, ncid, nc_varname, datstruc, fieldname, transpose=transpose
    nn       = 0
    field_id = where(tag_names(datstruc) eq strupcase(fieldname), nn)
    if nn gt 0 then field_id = field_id(0) else return
    buffarr = datstruc.(field_id)
    bsize = size(buffarr)
    if keyword_set(transpose) then buffarr = transpose(buffarr)
    ncdf_varget, ncid, ncdf_varid(ncid, nc_varname), buffarr
    if bsize(0) eq 0 then begin
       datstruc.(field_id) = buffarr
       return
    endif
    if keyword_set(transpose) then buffarr = transpose(buffarr)
    if bsize(0) eq 2 then datstruc.(field_id) = reform(buffarr, bsize(1), bsize(2)) $
       else datstruc.(field_id) = reform(buffarr, bsize(1))
end

;=============================================================================
pro sdi2k_build_windres, ncid, windfit, wind_settings
@sdi2kinc.pro
    ncdf_control, ncid, /sync
    ncdf_control, ncid, /fill, oldfill=nc_nodata

		nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
        	rname = 'Rings'
        	radii = 'Zone_Radii'
        	sectr = 'Zone_Sectors'
        	gap   = 'Gap'
        	rfov  = 'Rings2'
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'XDim'),    dummy,  xdim
			ncdf_diminq, ncid, ncdf_dimid(ncid, 'YDim'),    dummy,  ydim
			host.hardware.video.columns = xdim
			host.hardware.video.rows = ydim
			view = uintarr(xdim, ydim)
        endif else begin
        	rname = 'Ring'
        	radii = 'Ring_Radii'
        	sectr = 'Sectors'
        	gap   = 'Plate_Spacing'
			rfov  = 'Rings2'
        endelse

       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')
       ringid = ncdf_dimid(ncid, rname)

    ncdf_diminq, ncid, timeid, dummy,  maxrec
    ncdf_diminq, ncid, zoneid, dummy,  nz
    ncdf_diminq, ncid, ringid, dummy,  ncnrings

       windfit =  {zonal_wind: fltarr(nz, maxrec), $
              meridional_wind: fltarr(nz, maxrec), $
                vertical_wind: fltarr(maxrec), $
              fitted_los_wind: fltarr(nz, maxrec), $
    fitted_perpendicular_wind: fltarr(nz, maxrec), $
                      zeniths: fltarr(nz), $
                     azimuths: fltarr(nz), $
              zonal_distances: fltarr(nz), $
         meridional_distances: fltarr(nz), $
               zone_latitudes: fltarr(nz), $
              zone_longitudes: fltarr(nz), $
               assumed_height: 0., $
          reduced_chi_squared: fltarr(maxrec), $
                       u_zero: fltarr(maxrec, ncnrings), $
                       v_zero: fltarr(maxrec, ncnrings), $
                         dudx: fltarr(maxrec, ncnrings), $
                         dudy: fltarr(maxrec, ncnrings), $
                         dvdx: fltarr(maxrec, ncnrings), $
                         dvdy: fltarr(maxrec, ncnrings)}

    wind_settings = {time_smoothing: fltarr(maxrec), $
                    space_smoothing: fltarr(maxrec), $
                    dvdx_assumption: 'Unknown', $
                          algorithm: 'Unknown', $
                     assumed_height: -1.}
    hgt = 0.
    ncdf_attget, ncid, /global, 'Wind_Fitting_Method',                  alg
    alg = string(byte(alg))
    wind_settings.algorithm = alg
    ncdf_attget, ncid, /global, 'Wind_Fitting_Assumption',              ass
    ass = string(byte(ass))
    wind_settings.dvdx_assumption = ass
    ncdf_attget, ncid, /global, 'Assumed_Emission_Height_for_Wind_Fit', hgt
    wind_settings.assumed_height = hgt
    sdi2k_windget, ncid, 'Zonal_Wind',                windfit, 'zonal_wind'
    sdi2k_windget, ncid, 'Meridional_Wind',           windfit, 'meridional_wind'
    sdi2k_windget, ncid, 'Vertical_Wind',             windfit, 'vertical_wind'
    sdi2k_windget, ncid, 'Fitted_LOS_Wind',           windfit, 'fitted_los_wind'
    sdi2k_windget, ncid, 'Fitted_Perpendicular_Wind', windfit, 'fitted_perpendicular_wind'
    sdi2k_windget, ncid, 'U_0',                       windfit, 'u_zero', /transpose
    sdi2k_windget, ncid, 'V_0',                       windfit, 'v_zero', /transpose
    sdi2k_windget, ncid, 'du_dx',             windfit, 'dudx',   /transpose
    sdi2k_windget, ncid, 'du_dy',             windfit, 'dudy',   /transpose
    sdi2k_windget, ncid, 'dv_dx',             windfit, 'dvdx',   /transpose
    sdi2k_windget, ncid, 'dv_dy',             windfit, 'dvdy',   /transpose
    sdi2k_windget, ncid, 'Zone_Azimuths',             windfit, 'azimuths'
    sdi2k_windget, ncid, 'Zone_Zenith_Angles',        windfit, 'zeniths'
    sdi2k_windget, ncid, 'Zone_Latitudes',            windfit, 'zone_latitudes'
    sdi2k_windget, ncid, 'Zone_Longitudes',           windfit, 'zone_longitudes'
    sdi2k_windget, ncid, 'Zone_Meridional_Distances', windfit, 'meridional_distances'
    sdi2k_windget, ncid, 'Zone_Zonal_Distances',      windfit, 'zonal_distances'
    sdi2k_windget, ncid, 'Wind_Chi_Squared',          windfit, 'reduced_chi_squared'
    sdi2k_windget, ncid, 'Time_Smoothing',            wind_settings, 'time_smoothing'
    sdi2k_windget, ncid, 'Spatial_Smoothing',         wind_settings, 'space_smoothing'
end

;======================================================================
;  This routine attempts to open a file of name 'fname' to use as a
;  source of instrument profiles.  Since we have an imager we
;  need to obtain one insprof for each zone so the insprof array has
;  dimensions of (channel_number, zone_number).  The insprofs are
;  shifted to roughly channel zero so that fitted positions for sky
;  spectra allowing for convolution of the insprofs will be close to
;  the actual recorded positions.  Currently this is done simply by a
;  fixed 64-channel shift - better to come later maybe.  We also remove
;  any backgrounds, normalise to max amplitudes of one and calculate
;  the power spectrum of the insprofs:

pro sdi2k_load_insprofs, insfile, insprofs, insid, vid, norm=inorm
@sdi2kinc.pro
    sdi2k_ncopen, insfile, insid, vid
;    ncdf_diminq, insid, ncdf_dimid(insid, 'Channel'), dummy,  nchan
    nchan = host.hardware.etalon.scan_channels
    sdi2k_zenav_peakpos, insid, cpos, widths=widths
    widord = sort(widths)
    best   = widord(0.05*n_elements(widord))
    sdi2k_read_exposure, insid, best
    if insid ne -99 then ncdf_close, insid
    host.netcdf(vid).ncid = -1
    nz       = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    inorm     = fltarr(nz)

    for zidx=0,nz-1 do begin
        spectra(zidx, *) = spectra(zidx,*) - min(mc_im_sm(spectra(zidx,*), 7))
        spectra(zidx, *) = shift(spectra(zidx, *), nchan/2 - cpos)
    endfor

    insprofs = complexarr(n_elements(spectra(*,0)), n_elements(spectra(0,*)))
    inspower =     fltarr(n_elements(spectra(*,0)), n_elements(spectra(0,*)))
    for zidx=0,nz-1 do begin
        insprofs(zidx,*) = fft (spectra(zidx,*), -1)
        nrm              = abs(insprofs(zidx,1)) ;###
        inorm(zidx)      = nrm
        insprofs(zidx,*) = insprofs(zidx,*)/(nrm)
        spectra(zidx,*)  = spectra(zidx,*)/(nrm)
    endfor
    inspower = abs(insprofs*conj(insprofs))
    insprofs = spectra
    inorm    = inorm/max(inorm)
end

;==========================================================================================
;  This routine reads the times and spectral data corresponding to one
;  "exposure" of scanning Doppler imager data, which is to say
;  "ncnzones" spectra, each of "scan_channels" channels.  The result is
;  a complex array of dimensions (channel number, zone number):

pro sdi2k_read_exposure, ncid, record
@sdi2kinc.pro
    if ncid eq -99 then sdi2k_savefile_specread, ncid, record
    if ncid eq -99 then return
    sdi2k_reset_spectra
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nzones
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan

;    ncdf_varget,  ncid, ncdf_varid(ncid, 'Spectra'),       spectra, offset=[0,0,record], $
;                  count=[n_elements(spectra(*,0)), n_elements(spectra(0,*)), 1]
    ncdf_varget,  ncid, ncdf_varid(ncid, 'Spectra'),       spectra, offset=[0,0,record], $
                  count=[nzones, nchan, 1]
    ncdf_varget,  ncid, ncdf_varid(ncid, 'Start_Time'),    stime, offset=[record], count=[1]
    ncdf_varget,  ncid, ncdf_varid(ncid, 'End_Time'),      etime, offset=[record], count=[1]
    mc_nc_varget, ncid, ['Number_Summed', 'Number_Scans'], scanz, 1, [record], [1]

    host.programs.spectra.start_time = stime
    host.programs.spectra.integration_seconds = etime - host.programs.spectra.start_time
    host.programs.spectra.etalon_scans = scanz
    spectra = float(spectra)/host.programs.spectra.integration_seconds
end

pro sdi2k_savefile_specread, ncid, record
@sdi2kinc.pro
    spectra = spex.spectra(*,*,record)
    host.programs.spectra.start_time = spex.start_time(record)
    host.programs.spectra.integration_seconds = spex.end_time(record) - host.programs.spectra.start_time
    host.programs.spectra.etalon_scans = spex.nscans(record)
    spectra = float(spectra)/host.programs.spectra.integration_seconds
end


;==========================================================================================
;   Write spectra to the current netCDF file:

pro sdi2k_spex_writespex, otype
@sdi2kinc.pro
    if not(host.operation.logging.enable_logging) then begin
       if host.operation.logging.logging_off_alarm then begin
          sdi2k_user_message, '>>>Warning: Spectral write aborted; logging is disabled', /beep
       endif
       return
    endif

    vid  = strupcase(strcompress(otype, /remove_all)) eq 'INS'
    ncid = host.netcdf(vid).ncid
    if ncid eq -1 then return

    dummy = 'Dummy'
    ncdf_control, ncid, /sync
    ncdf_diminq,  ncid, ncdf_dimid(ncid, 'Time'),          dummy,  maxrec
    ncdf_varput,  ncid, ncdf_varid(ncid, 'Spectra'),       spectra, offset=[0,0,maxrec]
    ncdf_varput,  ncid, ncdf_varid(ncid, 'Start_Time'),    host.programs.spectra.start_time, offset=[maxrec]
    ncdf_varput,  ncid, ncdf_varid(ncid, 'End_Time'),      dt_tm_tojs(systime()), offset=[maxrec]
    ncdf_varput,  ncid, ncdf_varid(ncid, 'Number_Summed'), host.programs.spectra.etalon_scans, offset=[maxrec]
    host.operation.header.records = maxrec + 1
    ncdf_control, ncid, /sync
end




