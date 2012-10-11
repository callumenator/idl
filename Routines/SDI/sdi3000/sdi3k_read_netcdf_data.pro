;==========================================================================================
;   This routine maintains a lookup table of ncids versus filename:
function sdi3k_nc_get_ncid, filename, write_allowed=write_allowed
@sdi3k_ncdf_inc.pro
  if not(keyword_set(write_allowed)) then write_allowed = 0
  if n_elements(ncid_index) lt 1 then $
     ncid_index = {filename: "bound_to_not_exist", $
                       ncid: -1, $
              write_allowed: write_allowed, $
                       xdim: 256, $
                       ydim: 256, $
                   zone_map: intarr(1024, 1024), $
                 zmap_valid: 0}

;-See if we already have an entry for this file:
  idx  = where(ncid_index.filename eq filename, nfnd)
  idx  = idx(0)

;-Check if the returned index works, and if the ncdf file has the same write state as recorded in the index table.
; If both of these conditions are true, then return. Else close and reopen the ncdf file:
  if idx ge 0 then begin
     on_error, 3
     on_ioerror, inq_cont
     res = ncdf_inquire(ncid_index(idx).ncid)
inq_cont:
     if n_elements(res) gt 0 then begin
        if ncid_index(idx).write_allowed eq write_allowed then return, ncid_index(idx).ncid
        ncdf_close, ncid_index(idx).ncid
     endif
     veceldel, ncid_index, idx
  endif

  on_error, 3
  on_ioerror, open_cont
  ncid       = -1
  ncid       = ncdf_open(filename, write = write_allowed)
open_cont:
  if ncid lt 0 then return, ncid
  ncid_index = [ncid_index, ncid_index(0)]
  this_nc    = n_elements(ncid_index) - 1
  ncid_index(this_nc).filename      = filename
  ncid_index(this_nc).ncid          = ncid
  ncid_index(this_nc).write_allowed = write_allowed
  return, ncid
end

;==========================================================================================
;   This function checks whether a time in seconds appears to be based on 01-JAN-1970
;   rather than 01-Jan-2000. If so, it makes the required correction:

function time_origin, intime
         base70 = fix(dt_tm_mk(js2jd(0d)+1, intime, format='Y$')) gt 2022
         outime = intime
         if base70 then outime = intime + ymds2js(1970,1,1,0)
         return, outime
end

;========================================================================
;   This routine tries to read a variable from a netCDF file, based on a list of possible names:
pro mc_nc_varget, ncid, namelist, targetvar, default, offset, count
    NCDF_CONTROL, 0, /NOVERBOSE
    targetvar = default
    for j = 0, n_elements(namelist)-1 do begin
        id = NCDF_VARID(ncid, namelist(j))
        if id ge 0 then ncdf_varget, ncid, ncdf_varid(ncid, namelist(j)), targetvar, offset=offset, count=count
    endfor
    NCDF_CONTROL, 0, /VERBOSE
end

;========================================================================
;   This routine tries to read an attribute from a netCDF file, based on a list of possible names:
pro mc_glob_attget, ncid, namelist, targetvar, default
    NCDF_CONTROL, 0, /NOVERBOSE
    targetvar = default
    for j = 0, n_elements(namelist)-1 do begin
        desc = NCDF_ATTINQ( ncid,  namelist(j), /GLOBAL)
        if desc.datatype ne 'UNKNOWN' then ncdf_attget, ncid, namelist(j), targetvar, /GLOBAL
    endfor
    NCDF_CONTROL, 0, /VERBOSE
end

;==========================================================================================
;   Read the metadata from an SDI netCDF file:
pro sdi3k_read_metadata, filename, ncid, metadata
@sdi3k_ncdf_inc.pro

  fparse = mc_fileparse(filename)
;  mtr = {s_sdi3k_ncdf_meta_data, $
  mtr = { $
         valid: 0, $
         start_time: 0D, $
         end_time: 0D, $
         maxrec: 0L, $
         rings: -1, $
         zone_radii: fltarr(64), $
         zone_sectors: bytarr(64), $
         nzones: 0, $
         scan_channels: 0, $
         rows: 0, $
         columns: 0, $
         xbin: -1, $
         ybin: -1, $
         x_center_pix: 0., $
         y_center_pix: 0., $
         gap_mm: 0., $
         nm_per_step: 0., $
         start_spacing: 0., $
         gap_refractive_index: 0., $
         ref_finesse: 0., $
         wavelength_nm: 0., $
         mass_amu: 0., $
         cal_temperature: 0., $
         sky_fov_deg: 0., $
         fov_shift_north: 0., $
         fov_shift_east: 0., $
         channels_to_velocity: 0., $
         oval_angle: 0., $
         magnetic_midnight: 0., $
         magnetic_declination: 0., $
         rotation_from_oval: 0., $
         site: 'unknown', $
         site_code: 'ukn', $
         start_day_ut: 0L, $
         year: 0, $
         longitude: 0., $
         latitude: 0., $
         altitude: 0., $
         operator: 'unknown', $
         comment: 'none', $
         notes: strarr(32), $
         spekfit_status: 'Unknown', $
         windfit_status: 'Unknown', $
         file_name: filename, $
          fullname: 'Unknown', $
              path: 'Unknown', $
          namepart: 'Unknown', $
         name_only: 'Unknown', $
         extension: 'Unknown', $
          viewtype: 'sky', $
         file_accessed: 0D, $
         file_created: 0D, $
         file_modified: 0D, $
         file_bytes: 0L}

         ifo = file_info(filename)
         mtr.file_accessed = ifo.atime + ymds2js(1970,1,1,0)
         mtr.file_created  = ifo.ctime + ymds2js(1970,1,1,0)
         mtr.file_modified = ifo.mtime + ymds2js(1970,1,1,0)
         mtr.file_bytes    = ifo.size
         mtr.fullname      = fparse.fullname
         mtr.path          = fparse.path
         mtr.namepart      = fparse.namepart
         mtr.name_only     = fparse.name_only
         mtr.extension     = fparse.extension
         mtr.viewtype      = 'cal'
;         if strpos(fparse.name_only, 'SKY') ge 0 then mtr.viewtype = 'sky'
        if strpos(strupcase(fparse.name_only), 'SKY') ge 0 then mtr.viewtype = 'sky'
        nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
            rname = 'Rings'
            radii = 'Zone_Radii'
            sectr = 'Zone_Sectors'
            gap   = 'Gap'
         ncdf_diminq, ncid, ncdf_dimid(ncid, 'XDim'),    dummy,  xdim
         ncdf_diminq, ncid, ncdf_dimid(ncid, 'YDim'),    dummy,  ydim
         mtr.columns = xdim
         mtr.rows    = ydim
         ncdf_varget, ncid, ncdf_varid(ncid, 'X_Bin'), xbin, offset=0, count=1
         ncdf_varget, ncid, ncdf_varid(ncid, 'Y_Bin'), ybin, offset=0, count=1
         mtr.xbin = xbin
         mtr.ybin = ybin
        endif else begin
            mtr.columns = -1
            mtr.rows    = -1
            rname = 'Ring'
            radii = 'Ring_Radii'
            sectr = 'Sectors'
            gap   = 'Plate_Spacing'
        endelse
        rfov  = 'Rings2'

;------Get dimension sizes:
       dummy = 'Return Name'
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
       if maxrec lt 1 then return
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nzones
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
       ncdf_diminq, ncid, ncdf_dimid(ncid,  rname),    dummy,  nrings
       mtr.maxrec        = maxrec
       mtr.nzones        = nzones
       mtr.scan_channels = nchan
       mtr.rings         = nrings
       ncdf_control, ncid, /noverbose
       id = ncdf_varid(ncid, 'du_dx')
       if id lt 0 then mtr.windfit_status = 'No wind data found' else mtr.windfit_status = 'Winds Fitted'
       id = ncdf_varid(ncid, 'Peak_Position')
       if id lt 0 then mtr.spekfit_status = 'No spectral fit data found' else mtr.spekfit_status = 'Spectra Fitted'
       ncdf_control, ncid, /verbose


       mc_nc_varget, ncid, ['Ring_Radii', 'Ring_Radius', 'Zone_Radii'], radii, intarr(nrings-1), 0, nrings
       if max(radii) lt 2. then radii = radii * 100

;------Get information regarding times, if the existing file has any:
       if maxrec gt 0 then begin
          ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'), stime,   offset=(0), count=(1)
          ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),   etime,   offset=(maxrec-1), count=(1)
          mtr.start_time = time_origin(stime)
          mtr.end_time   = time_origin(etime)
       endif

;------Get static variables:
       if nc_desc.ndims ge 7 or nrings gt 5 then begin
          ncdf_varget, ncid, ncdf_varid(ncid, 'X_Center'),             xcen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Y_Center'),             ycen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Nm_Per_Step'),          nmps,    offset=0, count=1
       endif else  begin
          xcen = 128
          ycen =128
          nmps = .8
       endelse
       NCDF_CONTROL, 0, /NOVERBOSE
       ncdf_varget,  ncid, ncdf_varid(ncid, sectr), sectors,  offset=0, count=nrings
       NCDF_CONTROL, 0, /VERBOSE
       while n_elements(radii) gt n_elements(sectors) do radii = radii(1:*)
       nrings = n_elements(radii)
       mtr.rings = nrings
       mc_nc_varget, ncid, ['Gap', 'Plate_Spacing'],gap,      20.0,   0, 1
       mc_nc_varget, ncid, 'Start_Spacing',         strtspc,  0.,     0, 1
       mc_nc_varget, ncid, 'Gap_Refractive_Index',  refidx ,  1.,     0, 1
       mc_nc_varget, ncid, ['Sky_Wavelength', 'Wavelength'],  lambda, 630.03, 0, 1
       mc_nc_varget, ncid, ['Cal_Wavelength', 'Wavelength'],  lamcal, 632.8, 0, 1
       mc_nc_varget, ncid, 'Cal_Temperature',       caltemp,  300.,   0, 1
       mc_nc_varget, ncid, ['Mass', 'Sky_Mass', 'Cal_Mass'],  mass, 16., 0, 1
       mc_nc_varget, ncid, ['Ref_Finesse', 'Sky_Ref_Finesse'],nr,   20., 0, 1
       mc_nc_varget, ncid, 'Sky_FOV',               fov,      75.,    0, 1

       mtr.zone_radii            = radii
       mtr.zone_sectors          = sectors
       mtr.x_center_pix          = xcen
       mtr.y_center_pix          = ycen
       mtr.gap_mm                = gap
       mtr.start_spacing         = strtspc
       mtr.scan_channels         = nchan
       mtr.nm_per_step           = nmps
       mtr.gap_refractive_index  = refidx
       mtr.wavelength_nm         = lambda
       mtr.cal_temperature       = caltemp
       mtr.mass_amu              = mass
       mtr.ref_finesse           = nr
       mtr.sky_fov_deg           = fov
       if strpos(fparse.name_only, 'SKY') lt 0 then begin
          viewtype = 'cal'
          mtr.wavelength_nm = lamcal
       endif

;------Get global attributes:

       mc_glob_attget, ncid, 'Site', site, 'Poker Flat'
       mc_glob_attget, ncid, ['Site_Code', 'Site_code'], sitecd, 'PKR'
       mc_glob_attget, ncid, ['Start_Day_UT', 'Start Day UT'], doy, 0L
       mc_glob_attget, ncid, 'Year', year, dt_tm_mak(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$')
       mc_glob_attget, ncid, 'Longitude', lon, -150.
       mc_glob_attget, ncid, 'Latitude',  lat,  65.
       mc_glob_attget, ncid, 'Operator',  oper, 'Conde'
       mc_glob_attget, ncid, 'Comment',   cmt,  'None'

       mtr.site         = string(site)
       mtr.site_code    = string(sitecd)
       mtr.start_day_ut = dt_tm_mk(js2jd(0d)+1, mtr.start_time, format='doy$')
       mtr.year         = dt_tm_mk(js2jd(0d)+1, mtr.start_time, format='Y$')
       mtr.longitude    = lon
       mtr.latitude     = lat
       mtr.operator     = string(oper)
       mtr.comment      = string(cmt)

;------Read the notes back from the file:
       for i=0,31 do begin
           mc_glob_attget, ncid, 'Note_' + string(i, format='(i2.2)'),   note,  'None'
           mtr.notes(i) = string(note)
       endfor

;------Set the field-of-view parameters by lookup:
       if strpos(mtr.site, 'Poker Flat') ge 0 then begin
          if mtr.start_time ge ymds2js(2010, 01, 01, 0.) then mtr.sky_fov_deg = 68. ; Calibrated by moon position by MC on 09-Jan-2012
          mtr.oval_angle = 23.12
          mtr.magnetic_midnight = 11.06
          mtr.rotation_from_oval = 0.
          mtr.magnetic_declination = 22.3
          mtr.gap_mm                = 20.02
          if mtr.start_time ge ymds2js(2011, 02, 20, 0.) and mtr.start_time lt ymds2js(2011, 03, 13, 0.) then mtr.sky_fov_deg = 82.
          if mtr.start_time ge ymds2js(2010, 01, 01, 0.) and mtr.start_time lt ymds2js(2010, 03, 01, 0.) then begin
             mtr.fov_shift_north = -4.78 ; Again, FOV calibrated using moon by MC on 09-Jan-2012
             mtr.fov_shift_east  = 3.98
          endif
       endif
       if strpos(mtr.site, 'HAARP') ge 0 then begin
          mtr.oval_angle = 22.16
          mtr.magnetic_midnight = 10.77
          mtr.rotation_from_oval = 0.
          mtr.magnetic_declination = 21.65
          mtr.sky_fov_deg = 80.
          mtr.gap_mm               = 18.600 ; As per Hovemere delivery report.
       endif
       if strpos(mtr.site, 'Mawson')     ge 0 then begin
          mtr.oval_angle = -46.09
          mtr.magnetic_midnight    = 22.63
         if mtr.year lt 2008 then mtr.rotation_from_oval = -21.12 else mtr.rotation_from_oval = 0.
;####### only for testing if mtr.year lt 2008 then mtr.rotation_from_oval = -67.21 else mtr.rotation_from_oval = 0.
          if mtr.year gt 2010 then mtr.rotation_from_oval = 180.
          mtr.magnetic_declination = -67.21
          mtr.gap_mm = 25.
       endif
       if strpos(mtr.site, 'Poker Flat') ge 0 and fix(mtr.year) lt 2008 then begin
          mtr.gap_mm = 20.
       endif

       if mtr.gap_mm lt 0.001 then mtr.gap_mm = 20.0

;--converting factor for going from peakpositions to winds:
       mtr.channels_to_velocity  = 3.e8*lambda*1e-9/(2.*mtr.gap_mm*1e-3*nchan)

;------Set rows and columns by lookup, if they're currently undefined:
       if mtr.rows eq -1 then begin
          if mtr.nzones eq 25 then begin
             mtr.rows    = 256
             mtr.columns = 256
          endif else begin
             mtr.rows    = 320
             mtr.columns = 242
             mtr.x_center_pix = mtr.columns/2
             mtr.y_center_pix = mtr.rows/2
          endelse
       endif

       mtr.valid = 1
       metadata = mtr

;------Update the xdim and ydim size info in the ncid_index table for potential later use in zone mapping:
       idx  = where(ncid_index.ncid eq ncid, nfnd)
       idx  = idx(0)
       ncid_index(idx).xdim = mtr.columns
       ncid_index(idx).ydim = mtr.rows

end

;==========================================================================================
;   This routine reads the spectra from an SDI netCDF file:
pro sdi3k_read_spex, ncid, spex, metadata, range, cadence=cadence

;---Get the range of records to be read:
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]
    spex = 'Error: No spectra found in file: ' + metadata.file_name
    if ncdf_varid(ncid, 'Spectra') eq -1 then return

;---Create a template record for spectral data, then replicate it to create an array to hold the requested records:
    spectra = lonarr(metadata.nzones, metadata.scan_channels)
    onespek = {  valid: 0, $
               spectra: fltarr(metadata.nzones, metadata.scan_channels), $
            start_time: 0D, $
              end_time: 0D, $
                 scans: 0, $
                record: 0}
    spex = replicate(onespek, 1 + (limz(1) - limz(0))/cadence)

;---Determine the order of dimensions for the spectral data (it isn't the same for all SDI data!)
    chanid  = ncdf_dimid(ncid, 'Channel')
    spekvar = ncdf_varid(ncid, 'Spectra')
    spekinf = ncdf_varinq(ncid, spekvar)
    spek_xpose = spekinf.dim(0) eq chanid
    if spek_xpose then scount = [metadata.scan_channels, metadata.nzones, 1] else scount = [metadata.nzones, metadata.scan_channels, 1]

;---Read the requested records:
    for j=limz(0),limz(1),cadence do begin
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Spectra'),       spx,   offset=[0,0,j], count=scount
        spx  = float(spx)
        negz = where(spx lt 0., nneg)
        while nneg gt 0 do begin
              incr = 4096
              drop = mean(abs(spx(negz)))
              if drop gt 1e6 then begin
                 pwr = fix(alog(drop)/alog(2)) - 1
                 incr = (2L^pwr) > 4096
              endif
              spx(negz) = spx(negz) + incr
              negz = where(spx lt 0., nneg)
              wait, 0.0001
        endwhile
        if spek_xpose then spectra = transpose(spx) else spectra = spx
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Start_Time'),    stime, offset=[j], count=[1]
        ncdf_varget,  ncid, ncdf_varid(ncid, 'End_Time'),      etime, offset=[j], count=[1]
        mc_nc_varget, ncid, ['Number_Summed','Number_Scans'],  scanz, 1, [j], [1]
        k = (j - limz(0))/cadence
        spex(k).start_time = time_origin(stime)
        spex(k).end_time   = time_origin(etime)
        spex(k).scans      = scanz
        spex(k).spectra    = float(spectra)/scanz
        spex(k).valid      = 1
        spex(k).record     = j
    endfor

end

;==========================================================================================
;   This routine reads the results of spectral fitting:
pro sdi3k_read_spekfits, ncid, spekfits, metadata, range, cadence=cadence
    ncdf_control, ncid, /sync

;---Return an error if there's no fit data in the file:
    id = ncdf_varid(ncid, 'Peak_Position')
    ie = ncdf_varid(ncid, 'Position')
    if id lt 0 and ie lt 0 then spekfits = 'Error: No fit data found in file: ' + metadata.file_name
    if id lt 0 and ie lt 0 then return

;---Get data sizes and the range of records to be read:
    maxrec = metadata.maxrec - 1
    nchan  = metadata.scan_channels
    nz     = metadata.nzones
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]

;---Create a template record for fit data, then replicate it to create an array to hold the requested records:
       resrec = {valid: 0, $
                record: 0, $
            start_time: 0D, $
              end_time: 0D, $
                 scans: 0., $
              velocity: fltarr(nz), $
           temperature: fltarr(nz), $
             intensity: fltarr(nz), $
            background: fltarr(nz), $
           msis_height: fltarr(nz) - 9e9, $
 characteristic_energy: fltarr(nz) -9e9, $
        sigma_velocity: fltarr(nz), $
     sigma_temperature: fltarr(nz), $
     sigma_intensities: fltarr(nz), $
      sigma_background: fltarr(nz), $
          signal2noise: fltarr(nz), $
           chi_squared: fltarr(nz), $
     units_temperature: 'K', $
        units_velocity: 'm/s', $
     units_msis_height: 'km', $
     units_characteristic_energy: 'keV'}

    spekfits = replicate(resrec, 1 + (limz(1) - limz(0))/cadence)

;---Read the requested records:
    for j=limz(0),limz(1),cadence do begin
        mc_nc_varget,ncid, ['Peak_Position','Position'],          positions,   -999., [0,  j],[nz, 1]
        mc_nc_varget,ncid, ['Sigma_Position'],                    sigpos,      -999., [0,  j],[nz, 1]
        mc_nc_varget,ncid, ['Peak_Width','Temperature'],          widths,      -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Sigma_Width','Sigma_Temperature'],   sigwid,      -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Peak_Area','Area'],                  areas,       -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Sigma_Area'],                        sigarea,     -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Background'],                        backgrounds, -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Sigma_Bgnd, Sigma_Background'],      sigbgnd,     -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Signal_to_Noise', 'Signal_Noise'],   sig2noise,   -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Chi_Squared'],                       chi_squared, -999., [0, j], [nz, 1]
        mc_nc_varget,ncid, ['Start_Time'],                        stime,       -9e9,  [j],    [1]
        mc_nc_varget,ncid, ['End_Time'],                          etime,       -9e9,  [j],    [1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  j], count=[nz, 1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'),        stime,       offset=[j],     count=[1]
;        ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),          etime,       offset=[j],     count=[1]
        mc_nc_varget,ncid, ['Number_Summed','Number_Scans'],      scanz, 1,    [j],            [1]
        k = (j - limz(0))/cadence
        spekfits(k).velocity          = positions
        spekfits(k).sigma_velocity    = sigpos
        spekfits(k).temperature       = widths
        spekfits(k).sigma_temperature = sigwid
        spekfits(k).intensity         = areas
        spekfits(k).sigma_intensities = sigarea
        spekfits(k).background        = backgrounds
        spekfits(k).sigma_background  = sigbgnd
        spekfits(k).signal2noise      = sig2noise
        spekfits(k).chi_squared       = chi_squared
        spekfits(k).start_time        = time_origin(stime)
        spekfits(k).end_time          = time_origin(etime)
        spekfits(k).signal2noise      = sig2noise
        spekfits(k).scans             = scanz
        spekfits(k).record            = j
        spekfits(k).valid             = 1
    endfor

;---The following code removes "wrapped" orders in the peak fitting:
goto, wrapskip
    posarr = spekfits.velocity
    goods = where(abs(posarr) lt 1e4, nn)
    if nn eq 0 then goto, QUIT_FITREAD
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
QUIT_FITREAD:
    spekfits.velocity = posarr
wrapskip:
;---More quality control:

    spekfits.velocity = (spekfits.velocity + 2.25*metadata.scan_channels) mod metadata.scan_channels
end

;=============================================================================
pro sdi3k_read_winds, ncid, winds, metadata, range, cadence=cadence
    ncdf_control, ncid, /sync

;---Return an error if there's no fit data in the file:
    id = ncdf_varid(ncid, 'Zonal_Wind')
    if id lt 0 then winds = 'Error: No wind data found in file: ' + metadata.file_name
    if id lt 0 then return

;---Get data sizes and the range of records to be read:
    maxrec = metadata.maxrec - 1
    nchan  = metadata.scan_channels
    nz     = metadata.nzones
    nrings = metadata.rings
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]

;---Create a template record for wind data, then replicate it to create an array to hold the requested records:
            windfit =  {valid: 0, $
                       record: 0., $
                   start_time: 0D, $
                     end_time: 0D, $
                        scans: 0, $
                   zonal_wind: fltarr(nz), $
              meridional_wind: fltarr(nz), $
                vertical_wind: fltarr(nz), $
              fitted_los_wind: fltarr(nz), $
    fitted_perpendicular_wind: fltarr(nz), $
                      zeniths: fltarr(nz), $
                     azimuths: fltarr(nz), $
              zonal_distances: fltarr(nz), $
         meridional_distances: fltarr(nz), $
               zone_latitudes: fltarr(nz), $
              zone_longitudes: fltarr(nz), $
          reduced_chi_squared: 0., $
                       u_zero: fltarr(nrings), $
                       v_zero: fltarr(nrings), $
                         dudx: fltarr(nrings), $
                         dudy: fltarr(nrings), $
                         dvdx: fltarr(nrings), $
                         dvdy: fltarr(nrings), $
               time_smoothing: 0., $
              space_smoothing: 0., $
               assumed_height: 0., $
              dvdx_assumption: 'Unknown', $
                    algorithm: 'Unknown'}
    hgt = 0.
    mc_glob_attget, ncid, 'Wind_Fitting_Method',   alg,  'Unknown'

;    ncdf_attget, ncid, /global, 'Wind_Fitting_Method',                  alg
    windfit.algorithm = string(byte(alg))
    mc_glob_attget, ncid, 'Wind_Fitting_Assumption',   ass,  'Unknown'
;   ncdf_attget, ncid, /global, 'Wind_Fitting_Assumption',              ass
    windfit.dvdx_assumption = string(byte(ass))
    mc_glob_attget, ncid, 'Assumed_Emission_Height_for_Wind_Fit', hgt,  -999
;    ncdf_attget, ncid, /global, 'Assumed_Emission_Height_for_Wind_Fit', hgt
    windfit.assumed_height = hgt
    winds = replicate(windfit, 1 + (limz(1) - limz(0))/cadence)

;---Read the requested records:
    for j=limz(0),limz(1),cadence do begin
        k = (j - limz(0))/cadence
        mc_nc_varget,  ncid, ['Number_Summed','Number_Scans'],   scanz, 1, [j], [1]
        winds(k).scans = scanz
        sdi3k_windget, ncid, 'Start_Time',                winds, j, k,  'start_time'
        sdi3k_windget, ncid, 'End_Time',                  winds, j, k,  'end_time'
        sdi3k_windget, ncid, 'Zonal_Wind',                winds, j, k,  'zonal_wind'
        sdi3k_windget, ncid, 'Meridional_Wind',           winds, j, k,  'meridional_wind'
        sdi3k_windget, ncid, 'Vertical_Wind',             winds, j, k,  'vertical_wind'
        sdi3k_windget, ncid, 'Fitted_LOS_Wind',           winds, j, k,  'fitted_los_wind'
        sdi3k_windget, ncid, 'Fitted_Perpendicular_Wind', winds, j, k,  'fitted_perpendicular_wind'
        sdi3k_windget, ncid, 'U_0',                       winds, j, k,  'u_zero'
        sdi3k_windget, ncid, 'V_0',                       winds, j, k,  'v_zero'
        sdi3k_windget, ncid, ['du_dx', 'du/dx'],          winds, j, k,  'dudx'
        sdi3k_windget, ncid, ['du_dy', 'du/dy'],          winds, j, k,  'dudy'
        sdi3k_windget, ncid, ['dv_dx', 'dv/dx'],          winds, j, k,  'dvdx'
        sdi3k_windget, ncid, ['dv_dy', 'dv/dy'],          winds, j, k,  'dvdy'
        sdi3k_windget, ncid, 'Zone_Azimuths',             winds, j, k,  'azimuths'
        sdi3k_windget, ncid, 'Zone_Zenith_Angles',        winds, j, k,  'zeniths'
        sdi3k_windget, ncid, 'Zone_Latitudes',            winds, j, k,  'zone_latitudes'
        sdi3k_windget, ncid, 'Zone_Longitudes',           winds, j, k,  'zone_longitudes'
        sdi3k_windget, ncid, 'Zone_Meridional_Distances', winds, j, k,  'meridional_distances'
        sdi3k_windget, ncid, 'Zone_Zonal_Distances',      winds, j, k,  'zonal_distances'
        sdi3k_windget, ncid, 'Wind_Chi_Squared',          winds, j, k,  'reduced_chi_squared'
        sdi3k_windget, ncid, 'Time_Smoothing',            winds, j, k,  'time_smoothing'
        sdi3k_windget, ncid, 'Spatial_Smoothing',         winds, j, k,  'space_smoothing'
        winds(k).valid  = 1
        winds(k).record = j
        winds(k).start_time = time_origin(winds(k).start_time)
        winds(k).end_time   = time_origin(winds(k).end_time)
    endfor
end

;=============================================================================
;   This routine is a generic reader for windfit results:
pro sdi3k_windget, ncid, nc_varname, datstruc, index, idx2, fieldname
    nn       = 0
    field_id = where(tag_names(datstruc(idx2)) eq strupcase(fieldname), nn)
    if nn gt 0 then field_id = field_id(0) else return
    buffarr = datstruc(idx2).(field_id)
    bsize = size(buffarr)

;---Find the variable id:
    j=0
    while (ncdf_varid(ncid, nc_varname(j)) lt 0) and (j lt n_elements(nc_varname)-1) do j = j+1
    if ncdf_varid(ncid, nc_varname(j)) lt 0 then return


;---Determine whether this netCDF variable has time as one of its dimensions:
    ncinfo  = ncdf_inquire(ncid)
    varinfo = ncdf_varinq(ncid, ncdf_varid(ncid, nc_varname(j)))
    timvar  = where(varinfo.dim eq ncinfo.recdim, nn)
    timevar = nn gt 0

    if timevar      then ncdf_varget, ncid, ncdf_varid(ncid, nc_varname(j)), buffarr, offset = [0,index], count = [n_elements(buffarr), 1]
    if not(timevar) then ncdf_varget, ncid, ncdf_varid(ncid, nc_varname(j)), buffarr

    datstruc(idx2).(field_id) = buffarr
end

;==========================================================================================
;   This routine reads the accumulated images from an SDI netCDF file:
pro sdi3k_read_image, ncid, images, metadata, range, cadence=cadence
    ncdf_control, ncid, /sync

;---Return an error if there's no fit data in the file:
    id = ncdf_varid(ncid, 'Accumulated_Image')
    if id lt 0 then images = 'Error: No image data found in file: ' + metadata.file_name
    if id lt 0 then return

;---Get data sizes and the range of records to be read:
    maxrec = metadata.maxrec - 1
    xdim   = metadata.columns
    ydim   = metadata.rows
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]

;---Create a template record for wind data, then replicate it to create an array to hold the requested records:
       img =  {s_sdi3k_ncdf_image, $
                        valid: 0, $
                       record: 0., $
                   start_time: 0D, $
                     end_time: 0D, $
                        scans: 0, $
                        scene: lonarr(xdim, ydim), $
                        scale: lonarr(2)}
    images = replicate(img, 1 + (limz(1) - limz(0))/cadence)

;---Read the requested records:
    for j=limz(0),limz(1),cadence do begin
        k = (j - limz(0))/cadence
        ncdf_varget, ncid, ncdf_varid(ncid, 'Accumulated_Image'), img,         offset=[0, 0, j],     count=[xdim, ydim, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'),        stime,       offset=[j],     count=[1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),          etime,       offset=[j],     count=[1]
        mc_nc_varget,ncid, ['Number_Summed','Number_Scans'],      scanz, 1,    [j],            [1]
        if strpos(strupcase(strcompress(metadata.site, /remove_all)), 'MAWSON') ge 0 then img = rotate(img, 2)
        imord = sort(img)
        images(k).scene             = img
        images(k).start_time        = time_origin(stime)
        images(k).end_time          = time_origin(etime)
        images(k).scans             = scanz
        images(k).record            = j
        images(k).valid             = 1
        images(k).scale             = [img(imord(0.02*n_elements(imord))), img(imord(0.975*n_elements(imord)))]
        wait, 0.003
     endfor
end

;==========================================================================================
;   This routine would, if implemented, read phasemaps from an SDI netCDF file:
pro sdi3k_read_phasemap, ncid, phasemap, metadata
    print, 'sdi3k_read_phasemap has not yet been implemented...'
end

;==========================================================================================
;   This routine returns the zone map that corresponds to an SDI netCDF file:
pro sdi3k_read_zonemap,  ncid, zonemap,  metadata
@sdi3k_ncdf_inc.pro
;---Lookup the entry for this netCDF file in our private "ncid_index" table:
    idx   = where(ncid_index.ncid eq ncid, nfnd)
    idx   = idx(0)
    lastx = ncid_index(idx).xdim - 1
    lasty = ncid_index(idx).ydim - 1


;---If the ncid_index table contains a valid zone map for this file, grab it from there:
    if ncid_index(idx).zmap_valid then begin
       zonemap = ncid_index(idx).zone_map(0:lastx,0:lasty)
       return
    endif

;---If this netCDF file contains a zone map, grab it from there:
    NCDF_CONTROL, 0, /NOVERBOSE
    id    = ncdf_varid(ncid, 'Zone_Map')
    if id ge 0 then begin
       ncdf_varget, ncid, id, zonemap
       ncid_index(idx).zone_map(0:lastx,0:lasty) = zonemap
       ncid_index(idx).zmap_valid = 1
       return
    endif
    NCDF_CONTROL, 0, /VERBOSE

;---Dang! We gotta build the zone map from scratch:
       nz     = metadata.nzones
       nrings = metadata.rings
       nx     = ncid_index(idx).xdim
       ny     = ncid_index(idx).ydim
       edge   = (nx < ny)/2
       zonemap= intarr(nx, ny)
       nzones=0
;------Make a scale factor to deal with cases where the sky image (and hence zone map) significantly underfills the detector:
       radscale = 1.
       if max(metadata.zone_radii) lt 90. then radscale =99./max(metadata.zone_radii)

;------Make an image array whose elements represent the distance from the nominal fringe center:
       xx     = transpose(lindgen(ny,nx)/ny) - metadata.x_center_pix
       yy     = lindgen(nx,ny)/nx            - metadata.y_center_pix
       dist   = 100*sqrt(xx*xx + yy*yy)/float(edge)
       angle  = 180 + atan(-yy, -xx)*!radeg - metadata.rotation_from_oval
       toolo  = where(angle lt 0., nn)
       if nn gt 0 then angle(toolo) = angle(toolo) + 360.
       toohi  = where(angle gt 360., nn)
       if nn gt 0 then angle(toohi) = angle(toohi) - 360.
       for ring=0,metadata.rings-1 do begin
           these = where(dist gt metadata.zone_radii(ring)*radscale)
           zonemap(these) = total(metadata.zone_sectors(0:ring))
           zonemap(these) = zonemap(these) + angle(these)/(360./metadata.zone_sectors(ring+1))
       endfor
       zonemap(where(dist gt metadata.zone_radii(metadata.rings-1)*radscale)) = -1
       if strpos(strupcase(strcompress(metadata.site, /remove_all)), 'MAWSON') ge 0 then zonemap = rotate(zonemap, 2)

       ncid_index(idx).zone_map(0:lastx,0:lasty) = zonemap
       ncid_index(idx).zmap_valid = 1
end

;==========================================================================================
;   This routine returns the centers of the zones as fractions of the camera image position::
pro sdi3k_get_zone_centers, ncid, zone_centers, metadata
@sdi3k_ncdf_inc.pro
    sdi3k_read_zonemap, ncid, zonemap, metadata
;---Lookup the entry for this netCDF file in our private "ncid_index" table:
    idx   = where(ncid_index.ncid eq ncid, nfnd)
    idx   = idx(0)

    nx    = ncid_index(idx).xdim
    ny    = ncid_index(idx).ydim
    nz    = metadata.nzones
    edge  = (nx < ny)/2
    xx    = transpose(lindgen(ny,nx)/ny) - metadata.x_center_pix
    yy    = lindgen(nx,ny)/nx            - metadata.y_center_pix
    zone_centers = fltarr(nz, 3)
    for zone=0,nz-1 do begin
        these = where(zonemap eq zone, nn)
        if nn gt 0 then begin
;           zone_centers(zone, 0) = total(xx(these) + metadata.x_center_pix)/(nn*2*edge)
;           zone_centers(zone, 1) = total(yy(these) + metadata.y_center_pix)/(nn*2*edge)
           zone_centers(zone, 0) = total(xx(these) + metadata.x_center_pix)/(nn*nx)
           zone_centers(zone, 1) = total(yy(these) + metadata.y_center_pix)/(nn*ny)
           zone_centers(zone, 2) = nn
        endif
    endfor
end

;==========================================================================================
;   This routine returns a list of pixels that occur at the edges of the zones:
pro sdi3k_get_zone_edges, ncid, zone_edges, metadata
@sdi3k_ncdf_inc.pro
    sdi3k_read_zonemap, ncid, zonemap, metadata

    zone_edges = where(zonemap ne shift(zonemap, 1,0) or zonemap ne shift(zonemap, 0, 1))
end

;==========================================================================================
;   This routine returns the all-sky average of a parameter, weighted by sin(zenith_angle):
function wpar_ringav, wot, zrad
   wot = reform(wot)
   nr     = n_elements(zrad)
   ringav = total(wot(1:nr-1)*sin(zrad(1:nr-1)))/total(sin(zrad(1:nr-1)))
   return, ringav
end

;==========================================================================================
;   This function returns the all-sky standard deviation of a parameter, weighted
;   by sin(zenith_angle):
    function zenwgt_sdev, par, skyav, zens
    return, sqrt(total(((par - skyav)*sin(!dtor*zens))^2)/total((sin(!dtor*zens))^2))
end

;==========================================================================================
;   This routine returns a structure containing all-sky averages of the wind fit results:
pro sdi3k_build_1dwindpars, ncid, windpars, metadata, range, cadence=cadence
; windfit, rarr, resarr, ringsel=ringsel
@sdi2kinc.pro

;---Return an error if there's no fit data in the file:
    id = ncdf_varid(ncid, 'Zonal_Wind')
    if id lt 0 then windpars = 'Error: No wind data found in file: ' + metadata.file_name
    if id lt 0 then return

;---Get the range of records to be read:
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]
    sdi3k_read_winds, ncid, winds, metadata, [0, metadata.maxrec-1], cadence=cadence
    sky_fov  = metadata.sky_fov_deg
    nz       = metadata.nzones
    ncnrings = metadata.rings
    ringsel  = indgen(ncnrings)
    zrad     = fltarr(ncnrings)

    for rng=2,ncnrings-1 do begin
        zang = (metadata.zone_radii(rng) + metadata.zone_radii(rng-1))/2
        zang = (zang*sky_fov/100)*!pi/180
        zrad(rng) = zang
    endfor

     resrcd = {record: 0,  $
           start_time: 0d, $
             end_time: 0d, $
       mag_zonal_wind: 0., $
  mag_meridional_wind: 0., $
       geo_zonal_wind: 0., $
  geo_meridional_wind: 0., $
        vertical_wind: 0., $
            sigmagzon: 0., $
            sigmagmer: 0., $
            siggeozon: 0., $
            siggeomer: 0., $
           sigverwind: 0., $
                du_dx: 0., $
                du_dy: 0., $
                dv_dx: 0., $
                dv_dy: 0., $
            vorticity: 0., $
           divergence: 0., $
  resolved_divergence: fltarr(ncnrings), $
     wind_chi_squared: 0., $
     units_zonal_wind: 'm/s', $
units_meridional_wind: 'm/s', $
  units_vertical_wind: 'm/s', $
          units_du_dx: '1000/s', $
          units_du_dy: '1000/s', $
          units_dv_dx: '1000/s', $
          units_dv_dy: '1000/s', $
      units_vorticity: '1000/s', $
     units_divergence: '1000/s', $
     units_resolved_divergence: '1000/s'}

   brg = metadata.oval_angle

;   for j=0,n_elements(winds)-1 do begin
   for j=limz(0),limz(1),cadence do begin
       resrcd.record               = winds(j).record
       resrcd.start_time           = time_origin(winds(j).start_time)
       resrcd.end_time             = time_origin(winds(j).end_time)
       resrcd.mag_zonal_wind       = wpar_ringav(winds(j).u_zero(ringsel), zrad(ringsel))
       resrcd.mag_meridional_wind  = wpar_ringav(winds(j).v_zero(ringsel), zrad(ringsel))
       resrcd.geo_zonal_wind       = resrcd.mag_zonal_wind*cos(!dtor*brg)      + resrcd.mag_meridional_wind*sin(!dtor*brg)
       resrcd.geo_meridional_wind  = resrcd.mag_meridional_wind*cos(!dtor*brg) - resrcd.mag_zonal_wind*sin(!dtor*brg)
       resrcd.vertical_wind        = winds(j).vertical_wind(0)
       resrcd.sigmagzon            = zenwgt_sdev(winds(j).zonal_wind,      resrcd.mag_zonal_wind,      winds(j).zeniths)
       resrcd.sigmagmer            = zenwgt_sdev(winds(j).meridional_wind, resrcd.mag_meridional_wind, winds(j).zeniths)
       resrcd.siggeozon            = zenwgt_sdev(winds(j).zonal_wind*cos(!dtor*brg)      + winds(j).meridional_wind*sin(!dtor*brg), resrcd.geo_zonal_wind, winds(j).zeniths)
       resrcd.siggeomer            = zenwgt_sdev(winds(j).meridional_wind*cos(!dtor*brg) - winds(j).zonal_wind*sin(!dtor*brg), resrcd.geo_meridional_wind, winds(j).zeniths)
       resrcd.du_dx                = 1000.*wpar_ringav(winds(j).dudx(ringsel), zrad(ringsel))
       resrcd.du_dy                = 1000.*wpar_ringav(winds(j).dudy(ringsel), zrad(ringsel))
       resrcd.dv_dx                = 1000.*wpar_ringav(winds(j).dvdx(ringsel), zrad(ringsel))
       resrcd.dv_dy                = 1000.*wpar_ringav(winds(j).dvdy(ringsel), zrad(ringsel))
       resrcd.wind_chi_squared     = winds(j).reduced_chi_squared
       resrcd.vorticity            = resrcd.dv_dx - resrcd.du_dy
       resrcd.divergence           = resrcd.du_dx + resrcd.dv_dy
       for k=0,ncnrings-1 do begin
           resrcd.resolved_divergence(k) = 1000*(winds(j).dudx(k)+ winds(j).dvdy(k))
       endfor
;       if n_elements(windpars) eq 0 then windpars = resrcd else windpars = [windpars, resrcd]
       if j eq limz(0) then windpars = resrcd else windpars = [windpars, resrcd]
   endfor
end

;==========================================================================================
;   This routine closes an SDI netCDF file AND deletes its entry from the ncid index table:
pro sdi3k_ncdf_close, ncid
@sdi3k_ncdf_inc.pro
    ncdf_close, ncid
    idx  = where(ncid_index.ncid eq ncid, nfnd)
    if nfnd eq 0 then return
    idx  = idx(0)
    veceldel, ncid_index, idx
end


;========================================================================
;
;   This is the entry point for reading SDI netCDF data:
;
;========================================================================

pro sdi3k_read_netcdf_data, filename, $
                            metadata=metadata, $
                            spex=spex, $
                            spekfits=spekfits, $
                            winds=winds, $
                            windpars=windpars, $
                            images=images, $
                            phasemap=phasemap, $
                            zonemap=zonemap, $
                            zone_centers=zone_centers, $
                            zone_edges=zone_edges, $
                            range=range, $
                            cadence=cadence, $
                            preprocess_spekfits=preprocess_spekfits, $
                            close_nc_file=close_nc_file, $
                            keep_nc_open=keep_nc_open

   if not(keyword_set(cadence))   then cadence=1
   metadata = -1
;--Lookup the ncid from the filename. Use existing ncid if already open, else open it:
   ncid = sdi3k_nc_get_ncid(filename, write_allowed=0)
   if ncid lt 0 then return
;if arg_present(spex) then stop
;--Always read the meta data, even if we're not returning it:
   sdi3k_read_metadata, filename, ncid, metadata
   if size(metadata, /type) ne 8 then begin
      sdi3k_ncdf_close, ncid
      return
   endif

   if not(keyword_set(range)) then range = [0,metadata.maxrec-1]

;--Now read each of the data types requested by the keywords supplied:

   read_zone_map = arg_present(zonemap) or keyword_set(preprocess_spekfits)

   if arg_present(spex)            then sdi3k_read_spex,        ncid, spex,         metadata, range, cadence=cadence
   if arg_present(spekfits)        then sdi3k_read_spekfits,    ncid, spekfits,     metadata, range, cadence=cadence
   if arg_present(winds)           then sdi3k_read_winds,       ncid, winds,        metadata, range, cadence=cadence
   if arg_present(images)          then sdi3k_read_image,       ncid, images,       metadata, range, cadence=cadence
   if arg_present(windpars)        then sdi3k_build_1dwindpars, ncid, windpars,     metadata, range, cadence=cadence
   if arg_present(phasemap)        then sdi3k_read_phasemap,    ncid, phasemap,     metadata
   if read_zone_map                then sdi3k_read_zonemap,     ncid, zonemap,      metadata
   if arg_present(zone_centers)    then sdi3k_get_zone_centers, ncid, zone_centers, metadata
   if arg_present(zone_edges)      then sdi3k_get_zone_edges,   ncid, zone_edges,   metadata
   if keyword_set(close_nc_file) or ~(keyword_set(keep_nc_open)) then sdi3k_ncdf_close, ncid

   if arg_present(spekfits) and keyword_set(preprocess_spekfits) and size(spekfits, /tname) eq 'STRUCT' then begin
      maxpix = 0.
      for j=0,metadata.nzones-1 do begin
          thesepix = where(zonemap eq j, npix)
          spekfits.intensity(j) = spekfits.intensity(j)/npix
          if npix gt maxpix then maxpix = npix
      endfor
      spekfits.intensity = spekfits.intensity*maxpix
      sdi3k_drift_correct, spekfits, metadata, /force, /data_based
      spekfits.velocity = metadata.channels_to_velocity*spekfits.velocity
      spekfits.sigma_velocity = metadata.channels_to_velocity*spekfits.sigma_velocity
      vz = spekfits.velocity(0)
      sdi3k_remove_radial_residual, metadata, spekfits, parname='VELOCITY'
      sdi3k_remove_radial_residual, metadata, spekfits, parname='TEMPERATURE', /zero_mean
      sdi3k_remove_radial_residual, metadata, spekfits, parname='INTENSITY',   /multiplicative
      pv = spekfits.intensity
      pv = pv(sort(pv))
      nv = n_elements(pv)
      spekfits.intensity = spekfits.intensity - pv(0.02*nv)
   endif
end
